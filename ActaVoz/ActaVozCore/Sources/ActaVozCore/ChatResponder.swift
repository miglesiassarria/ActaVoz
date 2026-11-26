import Foundation

public protocol ChatResponding: Sendable {
    /// Solo recibe texto: la transcripción y el historial; nunca audio.
    func answer(transcript: String, history: [ChatMessage], question: String) async throws -> String
}

public struct ProviderChatResponder: ChatResponding {
    public var configurationStore: ProviderConfigurationStore
    public var secrets: any SecretStore
    public var transport: any HTTPTransport

    public init(
        configurationStore: ProviderConfigurationStore,
        secrets: any SecretStore,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.configurationStore = configurationStore
        self.secrets = secrets
        self.transport = transport
    }

    public func answer(transcript: String, history: [ChatMessage], question: String) async throws -> String {
        let configuration = try configurationStore.load()
        guard let selection = configuration.selection(for: .chat),
              let connection = configuration.connection(for: selection) else {
            throw ProviderConfigurationError.missingModel
        }
        let client = try ProviderFactory.make(connection: connection, store: secrets, transport: transport)
        var messages: [ProviderMessage] = [
            .system("Responde en el idioma de la pregunta usando solo la transcripción y el historial. Si no consta, dilo."),
            .system("Transcripción completa hasta ahora:\n\(transcript)")
        ]
        messages += history.map { message in
            ProviderMessage(role: message.role == .user ? "user" : "assistant", content: message.text)
        }
        messages.append(.user(question))
        return try await client.complete(messages: messages, model: selection.model)
    }
}
