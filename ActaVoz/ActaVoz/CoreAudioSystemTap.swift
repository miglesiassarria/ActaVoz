import AVFoundation
import CoreAudio
import Foundation

/// Captura solo audio, sin enumerar pantallas.
final class CoreAudioSystemTap {
    private var tap: AudioObjectID = 0
    private var aggregate: AudioObjectID = 0
    private var io: AudioDeviceIOProcID?
    private let queue = DispatchQueue(label: "app.actavoz.audio-tap")

    static func requestAccess() throws {
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
    func start(handler: @escaping (AVAudioPCMBuffer) -> Void) throws {
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
            try Self.check(AudioDeviceCreateIOProcIDWithBlock(&io, aggregate, queue) { _, input, _, _, _ in
                let list = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
                guard let first = list.first, first.mDataByteSize > 0, format.streamDescription.pointee.mBytesPerFrame > 0 else { return }
                let frames = AVAudioFrameCount(first.mDataByteSize / format.streamDescription.pointee.mBytesPerFrame)
                guard let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
                pcm.frameLength = frames
                let destination = UnsafeMutableAudioBufferListPointer(pcm.mutableAudioBufferList)
                guard list.count == destination.count else { return }
                for i in 0..<list.count {
                    guard let source = list[i].mData, let target = destination[i].mData, list[i].mDataByteSize <= destination[i].mDataByteSize else { return }
                    memcpy(target, source, Int(list[i].mDataByteSize))
                }
                handler(pcm)
            }, "Crear lector de audio")
            try Self.check(AudioDeviceStart(aggregate, io), "Iniciar audio del sistema")
        } catch { stop(); throw error }
    }
    func stop() {
        if aggregate != 0, let io { AudioDeviceStop(aggregate, io); AudioDeviceDestroyIOProcID(aggregate, io) }
        io = nil
        if aggregate != 0 { AudioHardwareDestroyAggregateDevice(aggregate); aggregate = 0 }
        if tap != 0 { AudioHardwareDestroyProcessTap(tap); tap = 0 }
    }
    deinit { stop() }
    private static func check(_ status: OSStatus, _ operation: String) throws {
        guard status == noErr else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "\(operation): Core Audio OSStatus \(status). Revisa Solo grabación del audio del sistema en Ajustes."])
        }
    }
}
