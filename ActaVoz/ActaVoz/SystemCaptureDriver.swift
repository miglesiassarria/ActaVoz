import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import CoreAudio

/// Captura de micrófono y audio-only con Core Audio taps, sin pedir pantalla.
@MainActor
final class SystemCaptureDriver: NSObject, CaptureDriver {
    var onEvent: ((CaptureEvent) -> Void)?
    private let engine = AVAudioEngine()
    private let systemTap = CoreAudioSystemTap()
    private let writer = CaptureAudioWriter()
    private var microphoneTapInstalled = false
    private var sources: Set<CaptureSource> = []
    private var startedAt = Date()
    private var probe: SystemAudioPermission.Probe = .notChecked

    func availability() -> CaptureAvailability {
        let microphone: PermissionState
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: microphone = .granted
        case .denied, .restricted: microphone = .denied
        case .notDetermined: microphone = .undetermined
        @unknown default: microphone = .unavailable
        }
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone, .external], mediaType: .audio, position: .unspecified)
            .devices.map { AudioDevice(id: $0.uniqueID, name: $0.localizedName) }
        return CaptureAvailability(microphone: microphone,
            system: SystemAudioPermission.resolve(preflightGranted: false, probe: probe), devices: devices)
    }

    func checkSystemAccess() async -> PermissionState {
        do {
            try CoreAudioSystemTap.requestAccess()
            // Crear el objeto tap no demuestra autorización ni llegada de audio.
            probe = .notChecked
        } catch {
            probe = .unavailable
        }
        return availability().system
    }

    func start(_ plan: CapturePlan, folder: URL) async throws {
        let audioFolder = folder.appendingPathComponent("AudioFuentes", isDirectory: true)
        try FileManager.default.createDirectory(at: audioFolder, withIntermediateDirectories: true)
        writer.begin()
        let fragment = UUID().uuidString
        startedAt = Date()
        sources = []
        var failures: [String] = []
        if plan.sources.contains(.microphone) {
            do {
                try startMicrophone(at: audioFolder.appendingPathComponent("microfono-\(fragment).caf"))
                sources.insert(.microphone)
            } catch { failures.append("Micrófono: \(error.localizedDescription)") }
        }
        if plan.sources.contains(.system) {
            do {
                try await startSystemAudio(at: audioFolder.appendingPathComponent("sistema-\(fragment).caf"))
                sources.insert(.system)
            } catch { failures.append("Audio del sistema: \(error.localizedDescription)") }
        }
        guard !sources.isEmpty else { throw CaptureError.driverFailed(failures.joined(separator: "\n")) }
        // El controlador recibe el estado de las fuentes cuando ya terminó start().
        if !failures.isEmpty {
            let failedSources = plan.sources.subtracting(sources)
            Task { @MainActor [weak self] in
                for source in failedSources { self?.onEvent?(.failed(source, failures.joined(separator: "\n"))) }
            }
        }
    }

    func pause() { writer.setPaused(true) }
    func resume() { writer.setPaused(false) }

    func stop() async throws -> [CaptureSource: URL] {
        if microphoneTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            microphoneTapInstalled = false
        }
        engine.stop()
        systemTap.stop()
        sources = []
        return writer.finish()
    }

    private func startMicrophone(at url: URL) throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw CaptureError.driverFailed("El micrófono no ofrece un formato válido.")
        }
        let writer = self.writer
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            do {
                if try writer.write(buffer, source: .microphone, url: url) {
                    DispatchQueue.main.async { self?.onEvent?(.chunk(.microphone, start: 0, end: 0)) }
                }
            } catch {
                DispatchQueue.main.async { self?.onEvent?(.failed(.microphone, error.localizedDescription)) }
            }
        }
        microphoneTapInstalled = true
        engine.prepare()
        do { try engine.start() }
        catch {
            input.removeTap(onBus: 0)
            microphoneTapInstalled = false
            throw error
        }
    }

    private func startSystemAudio(at url: URL) async throws {
        let writer = self.writer
        try systemTap.start { [weak self] pcm in
            do {
                if try writer.write(pcm, source: .system, url: url) {
                    DispatchQueue.main.async { self?.onEvent?(.chunk(.system, start: 0, end: 0)) }
                }
            } catch {
                DispatchQueue.main.async { self?.onEvent?(.failed(.system, error.localizedDescription)) }
            }
        }
        probe = .accessible
    }

}

/// Serializa escrituras y cierre; el archivo adopta el formato real del primer
/// búfer recibido. El callback no emite éxito si falla la escritura.
private final class CaptureAudioWriter: @unchecked Sendable {
    private let lock = NSLock()
    private var files: [CaptureSource: AVAudioFile] = [:]
    private var urls: [CaptureSource: URL] = [:]
    private var paused = false
    private var closed = false
    func begin() { lock.lock(); defer { lock.unlock() }; paused = false; closed = false }
    func setPaused(_ paused: Bool) { lock.lock(); defer { lock.unlock() }; self.paused = paused }
    func write(_ buffer: AVAudioPCMBuffer, source: CaptureSource, url: URL) throws -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !paused, !closed else { return false }
        if files[source] == nil {
            files[source] = try AVAudioFile(forWriting: url, settings: buffer.format.settings,
                commonFormat: buffer.format.commonFormat, interleaved: buffer.format.isInterleaved)
            urls[source] = url
        }
        try files[source]!.write(from: buffer)
        return true
    }
    func finish() -> [CaptureSource: URL] {
        lock.lock(); defer { lock.unlock() }
        closed = true
        files.removeAll() // Cierra cabeceras CAF antes de exportar.
        let result = urls
        urls.removeAll()
        return result
    }
}

struct CompositionAudioFinalizer: AudioFinalizing {
    func combine(_ sources: [URL], to destination: URL) async throws {
        let composition = AVMutableComposition()
        for url in sources {
            let asset = AVURLAsset(url: url)
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            let duration = try await asset.load(.duration)
            guard let track = tracks.first, duration.seconds > 0,
                  let composed = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            try composed.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: track, at: .zero)
        }
        guard !composition.tracks(withMediaType: .audio).isEmpty,
              let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw CaptureError.driverFailed("Ninguna fuente contiene audio válido. Se conservan los fragmentos para recuperarlos.")
        }
        let temporary = destination.deletingLastPathComponent().appendingPathComponent("audio-\(UUID().uuidString).m4a")
        do {
            try await export.export(to: temporary, as: .m4a)
            if FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: temporary)
            } else { try FileManager.default.moveItem(at: temporary, to: destination) }
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }
}
