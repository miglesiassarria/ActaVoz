import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import ScreenCaptureKit

/// Captura real: micrófono con AVAudioEngine y audio del sistema con
/// ScreenCaptureKit. Cada fuente se guarda en su propio CAF durante el
/// procesamiento; solo al conservar se combinan en un m4a.
@MainActor
final class SystemCaptureDriver: NSObject, CaptureDriver {
    var onEvent: ((CaptureEvent) -> Void)?

    private let engine = AVAudioEngine()
    private var microphoneFile: AVAudioFile?
    private var systemFile: AVAudioFile?
    private var stream: SCStream?
    private var output: SystemAudioOutput?
    private var startedAt = Date()
    private var sources: Set<CaptureSource> = []
    private var microphoneURL: URL?
    private var systemURL: URL?
    private var microphoneTapInstalled = false

    func availability() -> CaptureAvailability {
        let microphone: PermissionState
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: microphone = .granted
        case .denied, .restricted: microphone = .denied
        case .notDetermined: microphone = .undetermined
        @unknown default: microphone = .unavailable
        }

        let system: PermissionState = CGPreflightScreenCaptureAccess() ? .granted : .denied
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        ).devices.map { AudioDevice(id: $0.uniqueID, name: $0.localizedName) }

        return CaptureAvailability(microphone: microphone, system: system, devices: devices)
    }

    func start(_ plan: CapturePlan, folder: URL) throws {
        let audioFolder = folder.appendingPathComponent("AudioFuentes", isDirectory: true)
        try FileManager.default.createDirectory(at: audioFolder, withIntermediateDirectories: true)
        startedAt = Date()
        sources = plan.sources

        if plan.sources.contains(.microphone) {
            let url = audioFolder.appendingPathComponent("microfono.caf")
            try startMicrophone(at: url)
            microphoneURL = url
        }

        if plan.sources.contains(.system) {
            let url = audioFolder.appendingPathComponent("sistema.caf")
            systemURL = url
            Task { await startSystemAudio(at: url) }
        }
    }

    func pause() {
        if sources.contains(.microphone) {
            engine.pause()
        }
        if let stream {
            Task { try? await stream.stopCapture() }
        }
    }

    func resume() {
        if sources.contains(.microphone) {
            try? engine.start()
        }
        if let stream {
            Task { try? await stream.startCapture() }
        }
    }

    func stop() throws -> [CaptureSource: URL] {
        if microphoneTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            microphoneTapInstalled = false
        }
        engine.stop()
        microphoneFile = nil

        if let stream {
            let semaphore = DispatchSemaphore(value: 0)
            stream.stopCapture { _ in semaphore.signal() }
            _ = semaphore.wait(timeout: .now() + 2)
        }
        stream = nil
        output = nil
        systemFile = nil

        var result: [CaptureSource: URL] = [:]
        if let microphoneURL { result[.microphone] = microphoneURL }
        if let systemURL { result[.system] = systemURL }
        return result
    }

    // MARK: - Micrófono

    private func startMicrophone(at url: URL) throws {
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw CaptureError.driverFailed("El micrófono no ofrece un formato válido.")
        }
        let file = try AVAudioFile(
            forWriting: url,
            settings: format.settings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        microphoneFile = file
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            try? file.write(from: buffer)
            guard let self else { return }
            let now = Date()
            let elapsed = now.timeIntervalSince(self.startedAt)
            DispatchQueue.main.async {
                self.onEvent?(.chunk(.microphone, start: elapsed, end: elapsed))
            }
        }
        microphoneTapInstalled = true
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            microphoneTapInstalled = false
            throw CaptureError.driverFailed(error.localizedDescription)
        }
    }

    // MARK: - Audio del sistema

    private func startSystemAudio(at url: URL) async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            guard let display = content.displays.first else {
                throw CaptureError.driverFailed("No hay ninguna pantalla para capturar audio del sistema.")
            }
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.capturesAudio = true
            configuration.excludesCurrentProcessAudio = true
            configuration.sampleRate = 48_000
            configuration.channelCount = 2

            let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48_000,
                channels: 2,
                interleaved: false
            )
            guard let format else {
                throw CaptureError.driverFailed("Formato de audio del sistema no válido.")
            }
            let file = try AVAudioFile(
                forWriting: url,
                settings: format.settings,
                commonFormat: format.commonFormat,
                interleaved: format.isInterleaved
            )
            systemFile = file

            let sink = SystemAudioOutput { [weak self] buffer in
                try? file.write(from: buffer)
                guard let self else { return }
                let elapsed = Date().timeIntervalSince(self.startedAt)
                DispatchQueue.main.async {
                    self.onEvent?(.chunk(.system, start: elapsed, end: elapsed))
                }
            }
            output = sink

            let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
            try stream.addStreamOutput(sink, type: .audio, sampleHandlerQueue: .global(qos: .userInitiated))
            try await stream.startCapture()
            self.stream = stream
        } catch {
            let message = error.localizedDescription
            onEvent?(.failed(.system, message))
            systemFile = nil
        }
    }
}

/// Recibe los búferes de audio del sistema y los convierte al formato de archivo.
private final class SystemAudioOutput: NSObject, SCStreamOutput {
    private let handler: (AVAudioPCMBuffer) -> Void

    init(handler: @escaping (AVAudioPCMBuffer) -> Void) {
        self.handler = handler
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, let buffer = sampleBuffer.actavozAudioBuffer() else { return }
        handler(buffer)
    }
}

extension CMSampleBuffer {
    /// Convierte el búfer de ScreenCaptureKit en un búfer PCM reutilizable.
    func actavozAudioBuffer() -> AVAudioPCMBuffer? {
        guard let description = CMSampleBufferGetFormatDescription(self),
              let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(description),
              let format = AVAudioFormat(streamDescription: streamDescription)
        else { return nil }

        let frames = AVAudioFrameCount(CMSampleBufferGetNumSamples(self))
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            return nil
        }
        buffer.frameLength = frames

        var blockBuffer: CMBlockBuffer?
        var audioBufferList = AudioBufferList()
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            self,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        guard status == noErr else { return nil }

        let source = UnsafeMutableAudioBufferListPointer(&audioBufferList)
        let destination = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        for index in 0..<min(source.count, destination.count) {
            guard let sourceData = source[index].mData,
                  let destinationData = destination[index].mData else { continue }
            let bytes = min(source[index].mDataByteSize, destination[index].mDataByteSize)
            memcpy(destinationData, sourceData, Int(bytes))
            destination[index].mDataByteSize = bytes
        }
        return buffer
    }
}

/// Combina las fuentes separadas en un único m4a para reproducción.
struct CompositionAudioFinalizer: AudioFinalizing {
    func combine(_ sources: [URL], to destination: URL) throws {
        let composition = AVMutableComposition()
        for url in sources {
            let asset = AVURLAsset(url: url)
            guard let track = asset.tracks(withMediaType: .audio).first else { continue }
            let duration = asset.duration
            guard duration.seconds > 0 else { continue }
            guard let compositionTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else { continue }
            try compositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: track,
                at: .zero
            )
        }

        guard composition.tracks(withMediaType: .audio).count > 0 else {
            throw CaptureError.driverFailed("Ninguna fuente contiene audio.")
        }
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw CaptureError.driverFailed("No se pudo preparar la exportación del audio.")
        }
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        export.outputURL = destination
        export.outputFileType = .m4a

        let semaphore = DispatchSemaphore(value: 0)
        export.exportAsynchronously { semaphore.signal() }
        semaphore.wait()

        if export.status != .completed {
            throw export.error ?? CaptureError.driverFailed("La exportación del audio no terminó correctamente.")
        }
    }
}
