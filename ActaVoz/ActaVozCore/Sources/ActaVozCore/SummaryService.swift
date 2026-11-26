import Foundation

public protocol SummaryResponding: Sendable {
    func generate(template: SummaryTemplate, transcript: String) async throws -> String
}

public struct ProviderSummaryResponder: SummaryResponding {
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

    public func generate(template: SummaryTemplate, transcript: String) async throws -> String {
        let configuration = try configurationStore.load()
        guard let selection = configuration.selection(for: .summary),
              let connection = configuration.connection(for: selection) else {
            throw ProviderConfigurationError.missingModel
        }
        let client = try ProviderFactory.make(connection: connection, store: secrets, transport: transport)
        let sections = template.sections.map { "- \($0)" }.joined(separator: "\n")
        let messages: [ProviderMessage] = [
            .system("Genera un resumen en Markdown. Usa exactamente estos apartados como encabezados de nivel 3:\n\(sections)\n\(template.instructions)\nNo incluyas notas personales; solo la transcripción."),
            .user("Transcripción completa:\n\(transcript)")
        ]
        return try await client.complete(messages: messages, model: selection.model)
    }
}

public struct SummaryService {
    public var responder: any SummaryResponding

    public init(responder: any SummaryResponding) {
        self.responder = responder
    }

    public func generate(template: SummaryTemplate, transcript: String) async throws -> String {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummaryServiceError.emptyTranscript
        }
        return try await responder.generate(template: template, transcript: transcript)
    }

    /// Escribe solo después de que el proveedor termine; el archivo anterior no se toca si falla.
    public func save(_ text: String, at folder: URL) throws {
        try Data(text.utf8).write(to: folder.appendingPathComponent("resumen.md"), options: .atomic)
        try markEdited(false, at: folder)
    }

    public func delete(at folder: URL) throws {
        let url = folder.appendingPathComponent("resumen.md")
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try markEdited(false, at: folder)
    }

    public func markEdited(_ edited: Bool, at folder: URL) throws {
        let url = folder.appendingPathComponent("resumen.editado")
        try Data(edited ? "1".utf8 : "0".utf8).write(to: url, options: .atomic)
    }

    public func wasManuallyEdited(at folder: URL) -> Bool {
        let url = folder.appendingPathComponent("resumen.editado")
        return (try? String(contentsOf: url, encoding: .utf8)) == "1"
    }
}

public enum SummaryServiceError: Error, LocalizedError {
    case emptyTranscript
    case summaryRequired

    public var errorDescription: String? {
        switch self {
        case .emptyTranscript: return "No hay transcripción para resumir."
        case .summaryRequired: return "Genera primero el resumen principal."
        }
    }
}
