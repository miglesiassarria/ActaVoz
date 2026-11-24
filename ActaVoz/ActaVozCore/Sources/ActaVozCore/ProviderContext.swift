import Foundation

public struct ContextResult: Equatable, Sendable {
    public var output: String
    public var parts: Int

    public init(output: String, parts: Int) {
        self.output = output
        self.parts = parts
    }
}

public enum ProviderContextError: Error, LocalizedError {
    case emptyTranscript
    case incompleteCoverage

    public var errorDescription: String? {
        switch self {
        case .emptyTranscript: return "No hay transcripción que enviar."
        case .incompleteCoverage: return "No se pudo procesar toda la transcripción."
        }
    }
}

/// Envía la transcripción completa. Solo divide si el proveedor rechaza por longitud.
public struct ProviderContextService {
    public var provider: any LanguageProvider

    public init(provider: any LanguageProvider) {
        self.provider = provider
    }

    public func generate(
        transcript: String,
        instruction: String,
        model: String
    ) async throws -> ContextResult {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProviderContextError.emptyTranscript
        }
        let messages = [ProviderMessage.system(instruction), .user(transcript)]
        do {
            let output = try await provider.complete(messages: messages, model: model)
            return ContextResult(output: output, parts: 1)
        } catch ProviderError.contextTooLong {
            let chunks = try await split(transcript, instruction: instruction, model: model)
            let outputs = chunks.outputs
            guard !outputs.isEmpty else { throw ProviderContextError.incompleteCoverage }
            return ContextResult(output: outputs.joined(separator: "\n\n"), parts: chunks.count)
        }
    }

    private struct SplitResult {
        var outputs: [String]
        var count: Int
    }

    private func split(_ text: String, instruction: String, model: String) async throws -> SplitResult {
        do {
            let output = try await provider.complete(
                messages: [.system(instruction), .user(text)],
                model: model
            )
            return SplitResult(outputs: [output], count: 1)
        } catch ProviderError.contextTooLong {
            guard text.count > 1 else { throw ProviderError.contextTooLong }
            let middle = text.index(text.startIndex, offsetBy: text.count / 2)
            let left = String(text[..<middle])
            let right = String(text[middle...])
            let a = try await split(left, instruction: instruction, model: model)
            let b = try await split(right, instruction: instruction, model: model)
            return SplitResult(outputs: a.outputs + b.outputs, count: a.count + b.count)
        }
    }
}
