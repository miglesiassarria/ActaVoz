import Foundation

/// Identificador corto y estable de una sesión. No cambia al renombrar.
public struct SessionID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Seis caracteres en mayúsculas y dígitos, sin vocales para evitar palabras accidentales.
    public static func random() -> SessionID {
        let alphabet = Array("BCDFGHJKLMNPQRSTVWXYZ23456789")
        return SessionID(rawValue: String((0..<6).map { _ in alphabet.randomElement()! }))
    }

    public var description: String { rawValue }
}

public enum SessionLanguage: String, Codable, Sendable, CaseIterable {
    case spanish
    case english
    case automatic

    public var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "Inglés"
        case .automatic: return "Detección automática"
        }
    }
}

public struct Participant: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// Contenido de `sesion.json`. El esquema está versionado para poder migrarlo.
public struct SessionMetadata: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: String
    public var title: String
    public var startDate: Date
    public var language: SessionLanguage
    public var participants: [Participant]

    public init(
        schemaVersion: Int = SessionMetadata.currentSchemaVersion,
        id: String,
        title: String,
        startDate: Date,
        language: SessionLanguage = .spanish,
        participants: [Participant] = []
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.title = title
        self.startDate = startDate
        self.language = language
        self.participants = participants
    }
}

/// Una intervención transcrita, con tiempos en segundos desde el inicio de la sesión.
public struct TranscriptSegment: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var start: Double
    public var end: Double
    public var speakerId: String
    public var text: String

    public init(id: String, start: Double, end: Double, speakerId: String, text: String) {
        self.id = id
        self.start = start
        self.end = end
        self.speakerId = speakerId
        self.text = text
    }
}

/// Contenido de `transcripcion.json`.
public struct Transcript: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var language: SessionLanguage
    public var segments: [TranscriptSegment]

    public init(
        schemaVersion: Int = Transcript.currentSchemaVersion,
        language: SessionLanguage = .spanish,
        segments: [TranscriptSegment] = []
    ) {
        self.schemaVersion = schemaVersion
        self.language = language
        self.segments = segments
    }

    public var plainText: String {
        segments.map(\.text).joined(separator: "\n")
    }
}

public enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
}

public struct ChatMessage: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var role: ChatRole
    public var text: String
    public var createdAt: Date

    public init(id: String, role: ChatRole, text: String, createdAt: Date) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

/// Contenido de `chat.json`.
public struct ChatHistory: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var messages: [ChatMessage]

    public init(schemaVersion: Int = ChatHistory.currentSchemaVersion, messages: [ChatMessage] = []) {
        self.schemaVersion = schemaVersion
        self.messages = messages
    }
}

public enum SessionLocation: Equatable, Sendable, Hashable {
    case inbox
    case directory(String)

    public var directoryName: String? {
        if case .directory(let name) = self { return name }
        return nil
    }
}

public struct SessionSummary: Equatable, Sendable, Identifiable {
    public var metadata: SessionMetadata
    public var location: SessionLocation
    public var folderURL: URL
    public var hasAudio: Bool
    public var hasSummary: Bool

    public var id: String { metadata.id }
    public var title: String { metadata.title }
    public var startDate: Date { metadata.startDate }
}

public struct Session: Equatable, Sendable, Identifiable {
    public var summary: SessionSummary
    public var transcript: Transcript
    public var notes: String
    public var summaryText: String
    public var synthesis: String
    public var chat: ChatHistory

    public var id: String { summary.id }
}

public enum LibraryError: Error, LocalizedError, Equatable {
    case invalidDirectoryName(String)
    case directoryAlreadyExists(String)
    case directoryNotFound(String)
    case notUnderRoot(URL)
    case sessionNotFound(URL)
    case invalidMetadata(URL, reason: String)
    case collision(URL)
    case io(URL, reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidDirectoryName(let name):
            return "«\(name)» no es un nombre de directorio válido."
        case .directoryAlreadyExists(let name):
            return "Ya existe un directorio llamado «\(name)»."
        case .directoryNotFound(let name):
            return "No se encontró el directorio «\(name)»."
        case .notUnderRoot(let url):
            return "La ruta «\(url.path)» queda fuera de la carpeta de ActaVoz."
        case .sessionNotFound(let url):
            return "No se encontró una sesión en «\(url.path)»."
        case .invalidMetadata(let url, let reason):
            return "Los metadatos de «\(url.lastPathComponent)» no son válidos: \(reason)"
        case .collision(let url):
            return "Ya existe «\(url.lastPathComponent)» en el destino."
        case .io(let url, let reason):
            return "No se pudo operar sobre «\(url.lastPathComponent)»: \(reason)"
        }
    }
}
