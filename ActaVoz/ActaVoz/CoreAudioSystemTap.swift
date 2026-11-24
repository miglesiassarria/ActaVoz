import AVFoundation
import CoreAudio
import Foundation

/// Captura solo audio, sin enumerar pantallas.
final class CoreAudioSystemTap {
    private var tap: AudioObjectID = 0
    private var aggregate: AudioObjectID = 0
    private var io: AudioDeviceIOProcID?
    // Todas las operaciones de ciclo de vida, incluido AudioDeviceStart (TCC),
    // se ejecutan fuera del actor principal y en orden. El callback usa otra cola.
    private let lifecycleQueue = DispatchQueue(label: "app.actavoz.audio-tap.lifecycle")
    private let queue = DispatchQueue(label: "app.actavoz.audio-tap.callback")

    static func requestAccess() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do { try requestAccessSync(); continuation.resume() }
                catch { continuation.resume(throwing: error) }
            }
        }
    }
    private static func requestAccessSync() throws {
        let description = makeDescription()
        var tap: AudioObjectID = 0
        try check(AudioHardwareCreateProcessTap(description, &tap), "Solicitar audio del sistema")
        if tap != 0 { AudioHardwareDestroyProcessTap(tap) }
    }
    private static func makeDescription() -> CATapDescription {
        let description = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
        description.name = "ActaVoz — audio del sistema"
        description.isPrivate = true
        description.muteBehavior = .unmuted
        description.bundleIDs = [Bundle.main.bundleIdentifier ?? "app.actavoz.ActaVoz"]
        return description
    }
    /// Arranca y detiene un tap real: `AudioDeviceStart` es lo que hace que
    /// macOS evalúe y solicite el permiso de audio del sistema.
    func probeAccess() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lifecycleQueue.async {
                do {
                    try self.startSync(handler: { _, _ in })
                    self.stopSync()
                    continuation.resume()
                } catch {
                    self.stopSync()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func start(handler: @escaping (AVAudioPCMBuffer, UInt64) -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lifecycleQueue.async {
                do { try self.startSync(handler: handler); continuation.resume() }
                catch { continuation.resume(throwing: error) }
            }
        }
    }
    private func startSync(handler: @escaping (AVAudioPCMBuffer, UInt64) -> Void) throws {
        guard tap == 0, aggregate == 0 else { throw CaptureError.alreadyRecording }
        do {
            let description = Self.makeDescription()
            try Self.check(AudioHardwareCreateProcessTap(description, &tap), "Crear tap")
            var address = AudioObjectPropertyAddress(mSelector: kAudioTapPropertyFormat, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            var asbd = AudioStreamBasicDescription()
            var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            try Self.check(AudioObjectGetPropertyData(tap, &address, 0, nil, &size, &asbd), "Leer formato del tap")
            guard let format = AVAudioFormat(streamDescription: &asbd) else { throw CaptureError.driverFailed("Formato Core Audio no válido.") }
            let settings: [String: Any] = [
                kAudioAggregateDeviceNameKey: "ActaVoz Audio Tap",
                kAudioAggregateDeviceUIDKey: "app.actavoz.tap." + UUID().uuidString,
                kAudioAggregateDeviceIsPrivateKey: true,
                kAudioAggregateDeviceTapAutoStartKey: true,
                kAudioAggregateDeviceTapListKey: [[kAudioSubTapUIDKey: description.uuid.uuidString, kAudioSubTapDriftCompensationKey: true]]
            ]
            try Self.check(AudioHardwareCreateAggregateDevice(settings as CFDictionary, &aggregate), "Crear dispositivo privado")
            try Self.check(AudioDeviceCreateIOProcIDWithBlock(&io, aggregate, queue) { _, input, inputTime, _, _ in
                let list = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
                // Todos los planos deben contener exactamente los mismos frames;
                // aceptar un plano corto dejaría muestras sin inicializar en el PCM.
                let bytesPerFrame = format.streamDescription.pointee.mBytesPerFrame
                guard let first = list.first, bytesPerFrame > 0, first.mDataByteSize > 0,
                      first.mDataByteSize % bytesPerFrame == 0 else { return }
                let byteCount = first.mDataByteSize
                let frames = AVAudioFrameCount(byteCount / bytesPerFrame)
                guard let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
                pcm.frameLength = frames
                let destination = UnsafeMutableAudioBufferListPointer(pcm.mutableAudioBufferList)
                guard list.count == destination.count else { return }
                for i in 0..<list.count {
                    guard list[i].mDataByteSize == byteCount,
                          list[i].mNumberChannels == destination[i].mNumberChannels,
                          let source = list[i].mData, let target = destination[i].mData,
                          byteCount <= destination[i].mDataByteSize else { return }
                    memcpy(target, source, Int(byteCount))
                }
                guard inputTime.pointee.mFlags.contains(.hostTimeValid) else { return }
                handler(pcm, inputTime.pointee.mHostTime)
            }, "Crear lector de audio")
            try Self.check(AudioDeviceStart(aggregate, io), "Iniciar audio del sistema")
        } catch { stopSync(); throw error }
    }
    func stop() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lifecycleQueue.async {
                self.stopSync()
                continuation.resume()
            }
        }
    }
    private func stopSync() {
        if aggregate != 0, let io { AudioDeviceStop(aggregate, io); AudioDeviceDestroyIOProcID(aggregate, io) }
        io = nil
        if aggregate != 0 { AudioHardwareDestroyAggregateDevice(aggregate); aggregate = 0 }
        if tap != 0 { AudioHardwareDestroyProcessTap(tap); tap = 0 }
    }
    // Las operaciones pendientes retienen self: al llegar aquí ya no compiten
    // con este cleanup, incluso si no se llamó explícitamente a stop().
    deinit { stopSync() }
    private static func check(_ status: OSStatus, _ operation: String) throws {
        guard status == noErr else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "\(operation): Core Audio OSStatus \(status). Revisa Solo grabación del audio del sistema en Ajustes."])
        }
    }
}
