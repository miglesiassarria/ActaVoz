import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import CoreAudio
import AudioToolbox
import Darwin

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
    // El actor puede reentrar mientras Core Audio espera a TCC.
    private var starting = false
    private var stopping = false
    private var generation: UInt64 = 0
    private var activePlan: CapturePlan?
    private var folderURL: URL?
    private var healthTask: Task<Void, Never>?
    private var restarting = false
    private var pausedByUser = false
    private var recovering: Set<CaptureSource> = []
    private var segmentStartedAt = Date()
    private var lastRecoveryAttempt = Date.distantPast

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
            try await CoreAudioSystemTap.requestAccess()
            // Crear el objeto tap no demuestra autorización ni llegada de audio.
            probe = .notChecked
        } catch {
            probe = .unavailable
        }
        return availability().system
    }

    func start(_ plan: CapturePlan, folder: URL) async throws {
        guard !starting, !stopping, sources.isEmpty else { throw CaptureError.alreadyRecording }
        starting = true
        generation &+= 1
        let thisGeneration = generation
        defer { starting = false }
        let audioFolder = folder.appendingPathComponent("AudioFuentes", isDirectory: true)
        try FileManager.default.createDirectory(at: audioFolder, withIntermediateDirectories: true)
        let fragment = UUID()
        // Recovery starts after the last persisted sample, never at zero.
        let existing = try FileManager.default.contentsOfDirectory(at: audioFolder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "caf" }
        let prior = try existing.map { url -> AudioTimelinePlanner.Input in
            let file = try AVAudioFile(forReading: url)
            return .init(url: url, duration: Double(file.length) / file.processingFormat.sampleRate,
                         metadata: try AudioTimelineFragment.load(for: url))
        }
        let offset = try AudioTimelinePlanner.plan(prior).map { $0.sessionStart + $0.duration }.max() ?? 0
        writer.begin(segmentID: fragment, sessionStart: offset, hostStart: Self.hostSeconds())
        startedAt = Date()
        sources = []
        var failures: [String] = []
        if plan.sources.contains(.microphone) {
            do {
                try startMicrophone(at: audioFolder.appendingPathComponent("microfono-\(fragment).caf"), deviceUID: plan.microphoneDeviceID)
                sources.insert(.microphone)
            } catch { failures.append("Micrófono: \(error.localizedDescription)") }
        }
        if plan.sources.contains(.system) {
            do {
                try await startSystemAudio(at: audioFolder.appendingPathComponent("sistema-\(fragment).caf"))
                guard generation == thisGeneration else { throw CancellationError() }
                sources.insert(.system)
            } catch {
                if generation != thisGeneration { throw CancellationError() }
                failures.append("Audio del sistema: \(error.localizedDescription)")
            }
        }
        guard !sources.isEmpty else { throw CaptureError.driverFailed(failures.joined(separator: "\n")) }
        // El controlador recibe el estado de las fuentes cuando ya terminó start().
        if !failures.isEmpty {
            let failedSources = plan.sources.subtracting(sources)
            Task { @MainActor [weak self] in
                for source in failedSources { self?.onEvent?(.failed(source, failures.joined(separator: "\n"))) }
            }
        }
        activePlan = plan
        folderURL = folder
        segmentStartedAt = Date()
        lastRecoveryAttempt = Date()
        startHealthMonitoring()
    }

    func pause() {
        pausedByUser = true
        writer.setPaused(true)
    }

    func resume() {
        pausedByUser = false
        writer.setPaused(false)
    }

    func stop() async throws -> [CaptureSource: URL] {
        guard !stopping else { throw CaptureError.driverFailed("La captura ya se está deteniendo.") }
        stopping = true
        defer { stopping = false }
        // Invalida el start suspendido antes de esperar al cleanup serializado.
        generation &+= 1
        healthTask?.cancel()
        healthTask = nil
        activePlan = nil
        folderURL = nil
        pausedByUser = false
        recovering = []
        if microphoneTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            microphoneTapInstalled = false
        }
        engine.stop()
        await systemTap.stop()
        sources = []
        return try writer.finish()
    }

    private static func hostSeconds() -> Double { AVAudioTime.seconds(forHostTime: mach_absolute_time()) }

    private func startMicrophone(at url: URL, deviceUID: String?) throws {
        let input = engine.inputNode
        if let deviceUID {
            var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            var size: UInt32 = 0
            var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
            guard status == noErr else { throw CaptureError.driverFailed("No se pueden enumerar micrófonos: \(status)") }
            var devices = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
            status = devices.withUnsafeMutableBytes { AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, $0.baseAddress!) }
            guard status == noErr else { throw CaptureError.driverFailed("No se pueden leer micrófonos: \(status)") }
            let selected = devices.first { device in
                var uidAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceUID,
                    mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
                var uid: CFString = "" as CFString
                var uidSize = UInt32(MemoryLayout<CFString>.size)
                return AudioObjectGetPropertyData(device, &uidAddress, 0, nil, &uidSize, &uid) == noErr && uid as String == deviceUID
            }
            guard var device = selected, let unit = input.audioUnit else {
                throw CaptureError.driverFailed("El micrófono seleccionado ya no está disponible.")
            }
            status = AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
                                          &device, UInt32(MemoryLayout<AudioDeviceID>.size))
            guard status == noErr else { throw CaptureError.driverFailed("No se puede seleccionar el micrófono: \(status)") }
        }
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw CaptureError.driverFailed("El micrófono no ofrece un formato válido.")
        }
        let writer = self.writer
        let epoch = writer.currentEpoch()
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, time in
            do {
                guard time.isHostTimeValid else { throw CaptureError.driverFailed("El micrófono no proporciona hostTime.") }
                if try writer.write(buffer, source: .microphone, url: url, hostTime: time.hostTime, epoch: epoch) {
                    DispatchQueue.main.async { self?.didReceive(.microphone) }
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
        let epoch = writer.currentEpoch()
        try await systemTap.start { [weak self] pcm, hostTime in
            do {
                if try writer.write(pcm, source: .system, url: url, hostTime: hostTime, epoch: epoch) {
                    DispatchQueue.main.async { self?.didReceive(.system) }
                }
            } catch {
                DispatchQueue.main.async { self?.onEvent?(.failed(.system, error.localizedDescription)) }
            }
        }
        probe = .accessible
    }

    private func startHealthMonitoring() {
        healthTask?.cancel()
        healthTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, let self else { return }
                await self.checkHealth()
            }
        }
    }

    private func didReceive(_ source: CaptureSource) {
        guard !stopping else { return }
        if !sources.contains(source) { sources.insert(source) }
        if recovering.remove(source) != nil {
            onEvent?(.sourceRecovered(source))
        }
    }

    private func checkHealth() async {
        guard !pausedByUser, !starting, !stopping, !restarting, !sources.isEmpty || !recovering.isEmpty else { return }
        let now = Date()
        let stalled = sources.filter { source in
            if let last = writer.lastWriteAt(source) { return now.timeIntervalSince(last) > 4 }
            return now.timeIntervalSince(segmentStartedAt) > 4
        }
        if !stalled.isEmpty {
            for source in stalled {
                sources.remove(source)
                recovering.insert(source)
                onEvent?(.sourceLost(source))
            }
            await recoverSources()
        } else if sources.isEmpty, !recovering.isEmpty,
                  now.timeIntervalSince(lastRecoveryAttempt) > 5 {
            await recoverSources()
        }
    }

    /// Reabre un tramo nuevo tras una pérdida. No borra archivos previos.
    private func recoverSources() async {
        guard !restarting, !stopping, let plan = activePlan, let folder = folderURL else { return }
        restarting = true
        let attemptGeneration = generation
        defer {
            restarting = false
            lastRecoveryAttempt = Date()
        }
        if microphoneTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            microphoneTapInstalled = false
        }
        engine.stop()
        await systemTap.stop()
        guard !stopping, generation == attemptGeneration else { return }
        _ = try? writer.finish()
        let offset = persistedSessionEnd()
        let fragment = UUID()
        writer.begin(segmentID: fragment, sessionStart: offset, hostStart: Self.hostSeconds())
        segmentStartedAt = Date()
        let audioFolder = folder.appendingPathComponent("AudioFuentes", isDirectory: true)
        sources = []
        recovering.formUnion(plan.sources)
        if plan.sources.contains(.microphone) {
            do {
                try startMicrophone(at: audioFolder.appendingPathComponent("microfono-\(fragment).caf"),
                                    deviceUID: plan.microphoneDeviceID)
            } catch {}
        }
        if plan.sources.contains(.system) {
            do {
                try await startSystemAudio(at: audioFolder.appendingPathComponent("sistema-\(fragment).caf"))
            } catch {}
        }
    }

    private func persistedSessionEnd() -> Double {
        guard let folderURL else { return 0 }
        let directory = folderURL.appendingPathComponent("AudioFuentes", isDirectory: true)
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "caf" }
            .compactMap { try? AudioTimelineFragment.load(for: $0)?.end }
            .max() ?? 0
    }
}

/// Serializa escrituras y cierre; el archivo adopta el formato real del primer
/// búfer recibido. El callback no emite éxito si falla la escritura.
private final class CaptureAudioWriter: @unchecked Sendable {
    private let lock = NSLock()
    private var files: [CaptureSource: AVAudioFile] = [:]
    private var urls: [CaptureSource: URL] = [:]
    private var metadata: [CaptureSource: AudioTimelineFragment] = [:]
    private var segmentID = UUID()
    private var clock = AudioTimelineClock(hostStart: 0, sessionStart: 0)
    private var closed = true
    private var failures: [CaptureSource: Error] = [:]
    private var lastWrite: [CaptureSource: Date] = [:]
    private var epoch = 0
    func begin(segmentID: UUID, sessionStart: Double, hostStart: Double) {
        lock.lock(); defer { lock.unlock() }
        files.removeAll(); urls.removeAll(); metadata.removeAll(); lastWrite.removeAll()
        epoch &+= 1
        self.segmentID = segmentID
        clock = AudioTimelineClock(hostStart: hostStart, sessionStart: sessionStart)
        closed = false; failures.removeAll()
    }
    func setPaused(_ paused: Bool) {
        lock.lock(); defer { lock.unlock() }
        let host = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        if paused { clock.pause(at: host) } else { clock.resume(at: host) }
    }
    func currentEpoch() -> Int { lock.lock(); defer { lock.unlock() }; return epoch }
    func lastWriteAt(_ source: CaptureSource) -> Date? { lock.lock(); defer { lock.unlock() }; return lastWrite[source] }
    func write(_ buffer: AVAudioPCMBuffer, source: CaptureSource, url: URL, hostTime: UInt64, epoch expected: Int) throws -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !closed, epoch == expected else { return false }
        if let failure = failures[source] { throw failure }
        let rate = buffer.format.sampleRate
        let slices = clock.slices(hostStart: AVAudioTime.seconds(forHostTime: hostTime),
                                  duration: Double(buffer.frameLength) / rate)
        guard !slices.isEmpty else { return false }
        do {
            if files[source] == nil {
                // Publish even an empty sidecar before creating audio: a crash must
                // never make a new timed CAF look like an old zero-origin file.
                let initial = AudioTimelineFragment(source: source, segmentID: segmentID)
                try initial.save(for: url)
                metadata[source] = initial
                files[source] = try AVAudioFile(forWriting: url, settings: buffer.format.settings,
                    commonFormat: buffer.format.commonFormat, interleaved: buffer.format.isInterleaved)
                urls[source] = url
            }
            let file = files[source]!
            for slice in slices {
                let first = Int((slice.bufferOffset * rate).rounded())
                let count = min(Int(buffer.frameLength) - first, Int((slice.duration * rate).rounded()))
                guard count > 0, let trimmed = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: AVAudioFrameCount(count)) else { continue }
                trimmed.frameLength = AVAudioFrameCount(count)
                let input = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
                let output = UnsafeMutableAudioBufferListPointer(trimmed.mutableAudioBufferList)
                let stride = Int(buffer.format.streamDescription.pointee.mBytesPerFrame)
                for index in 0..<input.count {
                    guard let src = input[index].mData, let dst = output[index].mData else {
                        throw CaptureError.driverFailed("Búfer de audio no válido.")
                    }
                    memcpy(dst, src.advanced(by: first * stride), count * stride)
                }
                let fileStart = Double(file.length) / rate
                try file.write(from: trimmed)
                lastWrite[source] = Date()
                if let last = metadata[source]!.spans.last,
                   abs(last.fileStart + last.duration - fileStart) < 1 / rate,
                   abs(last.sessionStart + last.duration - slice.sessionStart) < 2 / rate {
                    metadata[source]!.spans[metadata[source]!.spans.count - 1].duration += Double(count) / rate
                } else {
                    // Frame rounding cannot create overlapping placements.
                    let previousEnd = metadata[source]!.end
                    guard slice.sessionStart >= previousEnd - 2 / rate else {
                        throw CaptureError.driverFailed("Audio recibido fuera de orden. Se conservan los fragmentos originales.")
                    }
                    metadata[source]!.spans.append(.init(fileStart: fileStart, sessionStart: max(previousEnd, slice.sessionStart),
                                                          duration: Double(count) / rate))
                }
                // Atomic checkpoint after every successfully written buffer.
                try metadata[source]!.save(for: url)
            }
            return true
        } catch {
            failures[source] = error // Un fallo de una fuente no bloquea la otra.
            throw error
        }
    }
    func finish() throws -> [CaptureSource: URL] {
        lock.lock(); defer { lock.unlock() }
        closed = true
        files.removeAll() // Close CAF headers, preserving every original on failure.
        if let failure = failures.values.first { throw failure }
        let result = urls
        urls.removeAll()
        return result
    }
}

struct CompositionAudioFinalizer: AudioFinalizing {
    func combine(_ sources: [URL], to destination: URL) async throws {
        let composition = AVMutableComposition()
        var assets: [AVURLAsset] = [] // Retener cada asset durante toda la exportación asíncrona.
        var inputs: [AudioTimelinePlanner.Input] = []
        var audioTracks: [URL: AVAssetTrack] = [:]
        for url in sources {
            let asset = AVURLAsset(url: url)
            assets.append(asset)
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            let duration = try await asset.load(.duration)
            guard let track = tracks.first, duration.seconds.isFinite, duration.seconds > 0 else {
                throw CaptureError.driverFailed("Un fragmento no contiene audio válido. Se conservan todos los originales.")
            }
            audioTracks[url] = track
            inputs.append(.init(url: url, duration: duration.seconds, metadata: try AudioTimelineFragment.load(for: url)))
        }
        let placements = try AudioTimelinePlanner.plan(inputs)
        for url in sources {
            guard let track = audioTracks[url],
                  let composed = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw CaptureError.driverFailed("No se puede crear la pista de audio. Se conservan los fragmentos.")
            }
            for placement in placements.filter({ $0.url == url }).sorted(by: { $0.sessionStart < $1.sessionStart }) {
                let target = CMTime(seconds: placement.sessionStart, preferredTimescale: 1_000_000_000)
                if CMTimeCompare(target, composed.timeRange.duration) > 0 {
                    composed.insertEmptyTimeRange(CMTimeRange(start: composed.timeRange.duration, duration: CMTimeSubtract(target, composed.timeRange.duration)))
                }
                try composed.insertTimeRange(CMTimeRange(start: CMTime(seconds: placement.fileStart, preferredTimescale: 1_000_000_000),
                    duration: CMTime(seconds: placement.duration, preferredTimescale: 1_000_000_000)), of: track,
                    at: CMTime(seconds: placement.sessionStart, preferredTimescale: 1_000_000_000))
            }
        }
        guard !composition.tracks(withMediaType: .audio).isEmpty,
              let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw CaptureError.driverFailed("Ninguna fuente contiene audio válido. Se conservan los fragmentos para recuperarlos.")
        }
        let temporary = destination.deletingLastPathComponent().appendingPathComponent("audio-\(UUID().uuidString).m4a")
        do {
            try await export.export(to: temporary, as: .m4a)
            withExtendedLifetime(assets) {}
            if FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: temporary)
            } else { try FileManager.default.moveItem(at: temporary, to: destination) }
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }
}
