import Foundation

public protocol NameSuggesting: Sendable {
    func suggest(transcript: String, participants: [Participant]) async throws -> [String: String]
}

public struct ProviderNameSuggester: NameSuggesting {
    public var configurationStore: ProviderConfigurationStore
    public var secrets: any SecretStore
    public var transport: any HTTPTransport

    public init(configurationStore: ProviderConfigurationStore, secrets: any SecretStore, transport: any HTTPTransport = URLSessionTransport()) {
        self.configurationStore = configurationStore
        self.secrets = secrets
        self.transport = transport
    }

    public func suggest(transcript: String, participants: [Participant]) async throws -> [String: String] {
        let configuration = try configurationStore.load()
        guard let selection = configuration.selection(for: .names),
              let connection = configuration.connection(for: selection) else {
            throw ProviderConfigurationError.missingModel
        }
        let client = try ProviderFactory.make(connection: connection, store: secrets, transport: transport)
        let roster = participants.map { "\($0.id): \($0.name)" }.joined(separator: "\n")
        let messages: [ProviderMessage] = [
            .system("Propón nombres solo cuando la transcripción los mencione con claridad. Responde una línea por interlocutor con el formato id: Nombre, sin explicaciones ni nombres inventados."),
            .user("Interlocutores:\n\(roster)\n\nTranscripción:\n\(transcript)")
        ]
        let answer = try await client.complete(messages: messages, model: selection.model)
        return Self.parse(answer, participants: participants)
    }

    public static func parse(_ answer: String, participants: [Participant]) -> [String: String] {
        let ids = Set(participants.map(\.id))
        var result: [String: String] = [:]
        for line in answer.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, ids.contains(parts[0]), !parts[1].isEmpty else { continue }
            let name = parts[1].replacingOccurrences(of: "\n", with: " ")
            result[parts[0]] = String(name.prefix(80))
        }
        return result
    }
}
