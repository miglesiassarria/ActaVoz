import CryptoKit
import Foundation

public protocol SynthesisResponding: Sendable {
    func generate(notes: String, summary: String) async throws -> String
}

public struct ProviderSynthesisResponder: SynthesisResponding {
    public var configurationStore: ProviderConfigurationStore
    public var secrets: any SecretStore
    public var transport: any HTTPTransport

    public init(configurationStore: ProviderConfigurationStore, secrets: any SecretStore, transport: any HTTPTransport = URLSessionTransport()) {
        self.configurationStore = configurationStore
        self.secrets = secrets
        self.transport = transport
    }

    public func generate(notes: String, summary: String) async throws -> String {
        let configuration = try configurationStore.load()
        guard let selection = configuration.selection(for: .summary),
              let connection = configuration.connection(for: selection) else {
            throw ProviderConfigurationError.missingModel
        }
        let client = try ProviderFactory.make(connection: connection, store: secrets, transport: transport)
        let messages: [ProviderMessage] = [
            .system("Genera una síntesis breve en Markdown que integre el resumen de la reunión y las notas personales. No inventes datos. No sustituyas el resumen."),
            .user("Resumen de la reunión:\n\(summary)\n\nNotas personales:\n\(notes)")
        ]
        return try await client.complete(messages: messages, model: selection.model)
    }
}

public struct SynthesisService {
    public var responder: any SynthesisResponding

    public init(responder: any SynthesisResponding) { self.responder = responder }

    public func generate(notes: String, summary: String) async throws -> String {
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummaryServiceError.summaryRequired
        }
        return try await responder.generate(notes: notes, summary: summary)
    }

    public func save(_ text: String, notes: String, summary: String, at folder: URL) throws {
        try Data(text.utf8).write(to: folder.appendingPathComponent("sintesis.md"), options: .atomic)
        try Data(Self.hash(notes: notes, summary: summary).utf8)
            .write(to: folder.appendingPathComponent("sintesis.fuentes"), options: .atomic)
    }

    public func delete(at folder: URL) throws {
        for name in ["sintesis.md", "sintesis.fuentes"] {
            let url = folder.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        }
    }

    public func needsUpdate(notes: String, summary: String, at folder: URL) -> Bool {
        let url = folder.appendingPathComponent("sintesis.fuentes")
        guard let stored = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return stored != Self.hash(notes: notes, summary: summary)
    }

    public static func hash(notes: String, summary: String) -> String {
        let digest = SHA256.hash(data: Data((notes + "\u{1F}" + summary).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
