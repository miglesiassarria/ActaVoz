import Foundation

public enum AudioRetentionPolicy: String, Codable, Sendable, CaseIterable {
    case alwaysKeep
    case alwaysDelete
    case askEachTime

    public var displayName: String {
        switch self {
        case .alwaysKeep: return "Guardar siempre"
        case .alwaysDelete: return "Borrar siempre"
        case .askEachTime: return "Preguntar en cada sesión"
        }
    }
}

public enum CaptureSource: String, Codable, Sendable, CaseIterable, Identifiable {
    case microphone
    case system

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .microphone: return "Micrófono"
        case .system: return "Audio del sistema"
        }
    }
}

public enum PermissionState: String, Codable, Sendable {
    case granted
    case denied
    case undetermined
    case unavailable
}

public struct AudioDevice: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct CaptureAvailability: Equatable, Sendable {
    public var microphone: PermissionState
    public var system: PermissionState
    public var devices: [AudioDevice]

    public init(
        microphone: PermissionState = .undetermined,
        system: PermissionState = .undetermined,
        devices: [AudioDevice] = []
    ) {
        self.microphone = microphone
        self.system = system
        self.devices = devices
    }

    public func permission(for source: CaptureSource) -> PermissionState {
        switch source {
        case .microphone: return microphone
        case .system: return system
        }
    }
}

public struct RecordingOptions: Equatable, Sendable {
    public var language: SessionLanguage
    public var savesVoiceProfiles: Bool
    public var microphoneEnabled: Bool
    public var systemEnabled: Bool
    public var microphoneDeviceID: String?

    public init(
        language: SessionLanguage = .spanish,
        savesVoiceProfiles: Bool = true,
        microphoneEnabled: Bool = true,
        systemEnabled: Bool = true,
        microphoneDeviceID: String? = nil
    ) {
        self.language = language
        self.savesVoiceProfiles = savesVoiceProfiles
        self.microphoneEnabled = microphoneEnabled
        self.systemEnabled = systemEnabled
        self.microphoneDeviceID = microphoneDeviceID
    }

    public var enabledSources: Set<CaptureSource> {
        var sources: Set<CaptureSource> = []
        if microphoneEnabled { sources.insert(.microphone) }
        if systemEnabled { sources.insert(.system) }
        return sources
    }
}

public enum PauseReason: String, Codable, Sendable {
    case user
    case sourcesLost
}

public enum CaptureStatus: Equatable, Sendable {
    case idle
    case preparing
    case recording
    case paused(PauseReason)
    case processing
    case awaitingAudioDecision
    case finished
    case failed(String)

    public var isActive: Bool {
        switch self {
        case .recording, .paused: return true
        default: return false
        }
    }

    public var displayName: String {
        switch self {
        case .idle: return "Lista para grabar"
        case .preparing: return "Preparando"
        case .recording: return "Grabando"
        case .paused(let reason):
            return reason == .user ? "En pausa" : "En pausa: sin fuentes"
        case .processing: return "Procesando la reunión"
        case .awaitingAudioDecision: return "Audio pendiente de decisión"
        case .finished: return "Procesada"
        case .failed(let message): return message
        }
    }
}

public struct CapturePlan: Equatable, Sendable {
    public var sources: Set<CaptureSource>
    public var microphoneDeviceID: String?

    public init(sources: Set<CaptureSource>, microphoneDeviceID: String? = nil) {
        self.sources = sources
        self.microphoneDeviceID = microphoneDeviceID
    }
}

public enum CaptureEvent: Equatable, Sendable {
    case chunk(CaptureSource, start: TimeInterval, end: TimeInterval)
    case sourceLost(CaptureSource)
    case sourceRecovered(CaptureSource)
    case failed(CaptureSource, String)
}

public protocol CaptureDriver: AnyObject {
    var onEvent: ((CaptureEvent) -> Void)? { get set }
    func availability() -> CaptureAvailability
    func start(_ plan: CapturePlan, folder: URL) throws
    func pause()
    func resume()
    func stop() throws -> [CaptureSource: URL]
}

/// Estado escrito en `grabacion.json` para poder recuperar tras un cierre inesperado.
public struct PendingRecording: Codable, Equatable, Sendable {
    public var startedAt: Date
    public var elapsed: TimeInterval
    public var sources: [CaptureSource]
    public var paused: Bool
    public var language: SessionLanguage
    public var savesVoiceProfiles: Bool

    public init(
        startedAt: Date,
        elapsed: TimeInterval,
        sources: [CaptureSource],
        paused: Bool,
        language: SessionLanguage,
        savesVoiceProfiles: Bool
    ) {
        self.startedAt = startedAt
        self.elapsed = elapsed
        self.sources = sources
        self.paused = paused
        self.language = language
        self.savesVoiceProfiles = savesVoiceProfiles
    }
}

public enum CaptureError: Error, LocalizedError, Equatable {
    case noSourceAvailable
    case alreadyRecording
    case notRecording
    case driverFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noSourceAvailable:
            return "No hay ninguna fuente disponible. Concede permiso al micrófono o al audio del sistema."
        case .alreadyRecording:
            return "Ya hay una grabación en curso."
        case .notRecording:
            return "No hay ninguna grabación en curso."
        case .driverFailed(let message):
            return "No se pudo iniciar la captura: \(message)"
        }
    }
}
