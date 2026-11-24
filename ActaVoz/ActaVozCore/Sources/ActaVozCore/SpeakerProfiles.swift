import Foundation

public struct SpeakerProfile: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var embedding: [Float]
    public var createdAt: Date

    public init(id: String = UUID().uuidString, name: String, embedding: [Float], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.embedding = embedding
        self.createdAt = createdAt
    }
}

public struct SpeakerProfileMatch: Equatable, Sendable {
    public var profile: SpeakerProfile
    public var similarity: Double

    public init(profile: SpeakerProfile, similarity: Double) {
        self.profile = profile
        self.similarity = similarity
    }
}

public enum SpeakerProfileError: Error, LocalizedError, Equatable {
    case invalidEmbedding
    case cannotRead(URL, reason: String)
    case cannotWrite(URL, reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidEmbedding: return "El perfil de voz no contiene un vector válido."
        case .cannotRead(let url, let reason): return "No se pudieron leer los perfiles «\(url.path)»: \(reason)"
        case .cannotWrite(let url, let reason): return "No se pudieron guardar los perfiles «\(url.path)»: \(reason)"
        }
    }
}

/// Perfiles confirmados. Nunca guarda audio, solo el vector de voz.
public struct SpeakerProfileStore {
    public static let defaultMatchThreshold = 0.65

    public var fileURL: URL
    public var fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func load() throws -> [SpeakerProfile] {
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            guard !data.isEmpty else { return [] }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SpeakerProfile].self, from: data)
        } catch {
            throw SpeakerProfileError.cannotRead(fileURL, reason: error.localizedDescription)
        }
    }

    public func save(_ profiles: [SpeakerProfile]) throws {
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(profiles).write(to: fileURL, options: .atomic)
        } catch {
            throw SpeakerProfileError.cannotWrite(fileURL, reason: error.localizedDescription)
        }
    }

    @discardableResult
    public func saveProfile(id: String? = nil, name: String, embedding: [Float]) throws -> SpeakerProfile {
        guard embedding.count == 256, embedding.contains(where: { $0 != 0 }) else {
            throw SpeakerProfileError.invalidEmbedding
        }
        var profiles = try load()
        if let id, let index = profiles.firstIndex(where: { $0.id == id }) {
            profiles[index].name = name
            profiles[index].embedding = normalized(embedding)
            try save(profiles)
            return profiles[index]
        }
        let profile = SpeakerProfile(id: id ?? UUID().uuidString, name: name, embedding: normalized(embedding))
        profiles.append(profile)
        try save(profiles)
        return profile
    }

    public func rename(id: String, to name: String) throws {
        var profiles = try load()
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try save(profiles)
    }

    public func delete(id: String) throws {
        var profiles = try load()
        profiles.removeAll { $0.id == id }
        try save(profiles)
    }

    public func match(embedding: [Float], threshold: Double = SpeakerProfileStore.defaultMatchThreshold) throws -> SpeakerProfileMatch? {
        let query = normalized(embedding)
        guard !query.isEmpty else { return nil }
        let best = try load().compactMap { profile -> SpeakerProfileMatch? in
            let score = cosine(query, normalized(profile.embedding))
            return SpeakerProfileMatch(profile: profile, similarity: score)
        }
        .max { $0.similarity < $1.similarity }
        guard let best, best.similarity >= threshold else { return nil }
        return best
    }

    public func normalized(_ vector: [Float]) -> [Float] {
        let norm = sqrt(vector.reduce(0) { $0 + Double($1 * $1) })
        guard norm > 0 else { return [] }
        return vector.map { Float(Double($0) / norm) }
    }

    public func cosine(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        return Double(zip(a, b).reduce(0) { $0 + $1.0 * $1.1 })
    }
}

/// Vector temporal por interlocutor; permite crear el perfil tras confirmar aunque se borre el audio.
public struct TemporaryVoiceSample: Codable, Equatable, Sendable {
    public var speakerId: String
    public var embedding: [Float]
    public var updatedAt: Date
}

public struct TemporaryVoiceStore {
    public var sessionFolder: URL
    public var fileManager: FileManager

    public init(sessionFolder: URL, fileManager: FileManager = .default) {
        self.sessionFolder = sessionFolder
        self.fileManager = fileManager
    }

    public var directory: URL { sessionFolder.appendingPathComponent("VozTemporal", isDirectory: true) }

    public func save(speakerId: String, embedding: [Float]) throws {
        guard embedding.count == 256, embedding.contains(where: { $0 != 0 }) else { return }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let sample = TemporaryVoiceSample(speakerId: speakerId, embedding: embedding, updatedAt: Date())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(sample).write(to: url(for: speakerId), options: .atomic)
    }

    public func load(speakerId: String) -> TemporaryVoiceSample? {
        guard let data = try? Data(contentsOf: url(for: speakerId)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(TemporaryVoiceSample.self, from: data)
    }

    public func remove(speakerId: String) {
        try? fileManager.removeItem(at: url(for: speakerId))
    }

    public func removeAll() {
        try? fileManager.removeItem(at: directory)
    }

    public func fileExists(speakerId: String) -> Bool {
        fileManager.fileExists(atPath: url(for: speakerId).path)
    }

    private func url(for speakerId: String) -> URL {
        let safe = speakerId.replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent("\(safe).json")
    }
}

/// Decide qué perfiles se guardan y cuándo se purgan los vectores temporales.
public enum SpeakerProfileService {
    @discardableResult
    public static func finalize(
        session: Session,
        profilesEnabled: Bool,
        store: SpeakerProfileStore,
        temporaryStore: TemporaryVoiceStore
    ) throws -> Session {
        guard profilesEnabled else {
            temporaryStore.removeAll()
            return session
        }
        var updated = session
        for index in updated.summary.metadata.participants.indices {
            let participant = updated.summary.metadata.participants[index]
            guard participant.isConfirmed else { continue }
            guard let sample = temporaryStore.load(speakerId: participant.id) else { continue }
            let profile = try store.saveProfile(
                id: participant.profileID,
                name: participant.name,
                embedding: sample.embedding
            )
            updated.summary.metadata.participants[index].profileID = profile.id
            temporaryStore.remove(speakerId: participant.id)
        }
        return updated
    }

    @discardableResult
    public static func confirm(
        speakerId: String,
        name: String,
        session: Session,
        profilesEnabled: Bool,
        store: SpeakerProfileStore,
        temporaryStore: TemporaryVoiceStore
    ) throws -> Session {
        var updated = try TranscriptEditor.rename(speakerId: speakerId, to: name, in: session)
        guard profilesEnabled,
              let index = updated.summary.metadata.participants.firstIndex(where: { $0.id == speakerId }),
              let sample = temporaryStore.load(speakerId: speakerId) else { return updated }
        let profile = try store.saveProfile(
            id: updated.summary.metadata.participants[index].profileID,
            name: name,
            embedding: sample.embedding
        )
        updated.summary.metadata.participants[index].profileID = profile.id
        temporaryStore.remove(speakerId: speakerId)
        return updated
    }

    /// Propone un perfil solo si supera el umbral; nunca confirma por sí solo.
    public static func proposal(
        for speakerId: String,
        temporaryStore: TemporaryVoiceStore,
        store: SpeakerProfileStore,
        threshold: Double = SpeakerProfileStore.defaultMatchThreshold
    ) -> SpeakerProfileMatch? {
        guard let sample = temporaryStore.load(speakerId: speakerId) else { return nil }
        return try? store.match(embedding: sample.embedding, threshold: threshold)
    }
}
