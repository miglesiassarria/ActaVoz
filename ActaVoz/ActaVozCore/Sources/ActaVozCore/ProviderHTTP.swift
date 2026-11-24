import Foundation

public struct ProviderMessage: Codable, Equatable, Sendable {
    public var role: String
    public var content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }

    public static func user(_ content: String) -> ProviderMessage { .init(role: "user", content: content) }
    public static func system(_ content: String) -> ProviderMessage { .init(role: "system", content: content) }
}

public enum ProviderError: Error, LocalizedError, Equatable {
    case missingSecret
    case unauthorized
    case contextTooLong
    case unavailable(String)
    case invalidResponse
    case rejected(String)

    public var errorDescription: String? {
        switch self {
        case .missingSecret: return "Falta la clave de este proveedor."
        case .unauthorized: return "El proveedor rechazó la credencial. Corrige la clave en Ajustes."
        case .contextTooLong: return "El proveedor rechazó la solicitud por longitud."
        case .unavailable(let reason): return "El proveedor no está disponible: \(reason)"
        case .invalidResponse: return "El proveedor devolvió una respuesta que no se pudo interpretar."
        case .rejected(let message): return "El proveedor rechazó la solicitud: \(message)"
        }
    }
}

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    public var session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ProviderError.invalidResponse }
        return (data, http)
    }
}

public protocol LanguageProvider: Sendable {
    var connection: ProviderConnection { get }
    func complete(messages: [ProviderMessage], model: String) async throws -> String
    func check() async throws
}

public struct ProviderHTTPClient: LanguageProvider {
    public let connection: ProviderConnection
    public let secret: String?
    public let transport: any HTTPTransport

    public init(connection: ProviderConnection, secret: String?, transport: any HTTPTransport) {
        self.connection = connection
        self.secret = secret
        self.transport = transport
    }

    private var baseURL: URL? { URL(string: connection.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) }

    public func complete(messages: [ProviderMessage], model: String) async throws -> String {
        guard let baseURL else { throw ProviderError.unavailable("URL no válida") }
        switch connection.kind {
        case .openAI, .openCodeGo, .generic:
            let request = try jsonRequest(
                url: baseURL.appendingPathComponent("chat/completions"),
                authorization: "Bearer " + (try requiredSecret()),
                body: openAIBody(messages: messages, model: model)
            )
            let (data, response) = try await transport.send(request)
            try validate(response)
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = object["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else { throw ProviderError.invalidResponse }
            return content
        case .claude:
            let request = try jsonRequest(
                url: baseURL.appendingPathComponent("v1/messages"),
                authorization: nil,
                extra: ["x-api-key": try requiredSecret(), "anthropic-version": "2023-06-01"],
                body: [
                    "model": model,
                    "max_tokens": 4096,
                    "messages": messages.map { ["role": $0.role == "system" ? "user" : $0.role, "content": $0.content] }
                ]
            )
            let (data, response) = try await transport.send(request)
            try validate(response)
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = object["content"] as? [[String: Any]],
                  let text = content.first?["text"] as? String else { throw ProviderError.invalidResponse }
            return text
        case .ollama:
            let request = try jsonRequest(
                url: baseURL.appendingPathComponent("api/chat"),
                authorization: nil,
                body: ["model": model, "stream": false, "messages": messages.map { ["role": $0.role, "content": $0.content] }]
            )
            let (data, response) = try await transport.send(request)
            try validate(response)
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = object["message"] as? [String: Any],
                  let content = message["content"] as? String else { throw ProviderError.invalidResponse }
            return content
        }
    }

    public func check() async throws {
        guard let baseURL else { throw ProviderError.unavailable("URL no válida") }
        switch connection.kind {
        case .openAI, .openCodeGo, .generic:
            let request = try getRequest(url: baseURL.appendingPathComponent("models"), authorization: "Bearer " + (try requiredSecret()))
            let (_, response) = try await transport.send(request)
            try validate(response)
        case .ollama:
            let (_, response) = try await transport.send(URLRequest(url: baseURL.appendingPathComponent("api/tags")))
            try validate(response)
        case .claude:
            _ = try await complete(messages: [.user("ping")], model: connection.defaultModel)
        }
    }

    private func requiredSecret() throws -> String {
        guard let secret, !secret.isEmpty else { throw ProviderError.missingSecret }
        return secret
    }

    private func validate(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300: return
        case 401, 403: throw ProviderError.unauthorized
        case 413: throw ProviderError.contextTooLong
        case 400:
            throw ProviderError.contextTooLong
        case 429: throw ProviderError.unavailable("límite de solicitudes")
        case 500..<600: throw ProviderError.unavailable("error del servidor (\(response.statusCode))")
        default: throw ProviderError.rejected("HTTP \(response.statusCode)")
        }
    }

    private func jsonRequest(url: URL, authorization: String?, extra: [String: String] = [:], body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authorization { request.setValue(authorization, forHTTPHeaderField: "Authorization") }
        for (key, value) in extra { request.setValue(value, forHTTPHeaderField: key) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func getRequest(url: URL, authorization: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        return request
    }

    private func openAIBody(messages: [ProviderMessage], model: String) -> [String: Any] {
        [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
    }
}

public enum ProviderSelection {
    /// Resuelve conexión y modelo para una función; nunca devuelve secretos.
    public static func resolve(
        configuration: ProviderConfiguration,
        use: ModelUse
    ) throws -> (connection: ProviderConnection, model: String) {
        guard let selection = configuration.selection(for: use),
              let connection = configuration.connection(for: selection) else {
            throw ProviderConfigurationError.missingModel
        }
        guard !selection.model.isEmpty else { throw ProviderConfigurationError.missingModel }
        return (connection, selection.model)
    }
}

public enum ProviderFactory {
    public static func make(
        connection: ProviderConnection,
        store: any SecretStore,
        transport: any HTTPTransport = URLSessionTransport()
    ) throws -> ProviderHTTPClient {
        let secret = try store.secret(for: connection.id)
        return ProviderHTTPClient(connection: connection, secret: secret, transport: transport)
    }
}
