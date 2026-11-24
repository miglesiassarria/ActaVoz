import XCTest
@testable import ActaVozCore

private final class MockTransport: HTTPTransport, @unchecked Sendable {
    private(set) var requests: [URLRequest] = []
    var responder: @Sendable (URLRequest) -> (Data, Int)

    init(responder: @escaping @Sendable (URLRequest) -> (Data, Int)) {
        self.responder = responder
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let (data, status) = responder(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

private final class LengthLimitedProvider: LanguageProvider, @unchecked Sendable {
    let connection = ProviderConnection(name: "mock", kind: .generic, baseURL: "https://mock", defaultModel: "m")
    private(set) var chunks: [String] = []
    let limit: Int

    init(limit: Int) { self.limit = limit }

    func complete(messages: [ProviderMessage], model: String) async throws -> String {
        let text = messages.last?.content ?? ""
        if text.count > limit {
            throw ProviderError.contextTooLong
        }
        chunks.append(text)
        return "out-\(text.count)"
    }

    func check() async throws {}
}

final class ProviderTests: XCTestCase {
    func testOpenAIRequestUsesKeyAndModel() async throws {
        let transport = MockTransport { request in
            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["model"] as? String, "gpt-test")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
            let data = try! JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": "hola"]]]])
            return (data, 200)
        }
        let connection = ProviderConnection(name: "OpenAI", kind: .openAI, defaultModel: "gpt-test")
        let client = ProviderHTTPClient(connection: connection, secret: "sk-test", transport: transport)
        let output = try await client.complete(messages: [.user("Hola")], model: "gpt-test")
        XCTAssertEqual(output, "hola")
        XCTAssertEqual(transport.requests.count, 1)
    }

    func testUnauthorizedAndLengthAreMappedWithoutSecret() async throws {
        let transport = MockTransport { _ in (Data(), 401) }
        let client = ProviderHTTPClient(
            connection: ProviderConnection(name: "OpenAI", kind: .openAI, defaultModel: "m"),
            secret: "super-secret",
            transport: transport
        )
        do {
            _ = try await client.complete(messages: [.user("x")], model: "m")
            XCTFail("Debe fallar")
        } catch let error as ProviderError {
            XCTAssertEqual(error, .unauthorized)
            XCTAssertFalse(error.localizedDescription.contains("super-secret"))
        }
    }

    func testConfigurationPersistsMultipleConnectionsAndSelections() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ProviderConfigurationStore(fileURL: root.appendingPathComponent("proveedores.json"))
        let one = ProviderConnection(name: "Uno", kind: .openAI, defaultModel: "a")
        let two = ProviderConnection(name: "Dos", kind: .ollama, defaultModel: "b")
        let config = ProviderConfiguration(
            connections: [one, two],
            activeConnectionID: two.id,
            summaryModel: ModelSelection(connectionID: one.id, model: "a")
        )
        try store.save(config)
        let loaded = try store.load()
        XCTAssertEqual(loaded.connections.count, 2)
        XCTAssertEqual(loaded.activeConnectionID, two.id)
        XCTAssertEqual(loaded.selection(for: .chat)?.model, "b")
        XCTAssertEqual(loaded.selection(for: .summary)?.model, "a")
        XCTAssertEqual(loaded.selection(for: .names)?.model, "b")
    }

    func testContextSplitsOnlyAfterRejectionAndCoversEverything() async throws {
        let provider = LengthLimitedProvider(limit: 120)
        let service = ProviderContextService(provider: provider)
        let transcript = String(repeating: "Reunión de prueba. ", count: 80)
        let result = try await service.generate(transcript: transcript, instruction: "Resume", model: "m")
        XCTAssertGreaterThan(result.parts, 1)
        XCTAssertEqual(provider.chunks.joined(), transcript)
        XCTAssertTrue(result.output.contains("out-"))
    }


    func testSelectionFallsBackToPrimary() {
        let connection = ProviderConnection(name: "Uno", kind: .generic, baseURL: "https://x", defaultModel: "principal")
        let config = ProviderConfiguration(connections: [connection], activeConnectionID: connection.id)
        XCTAssertEqual(config.selection(for: .chat)?.model, "principal")
        XCTAssertEqual(config.selection(for: .summary)?.model, "principal")
        XCTAssertEqual(config.selection(for: .names)?.model, "principal")
        XCTAssertTrue(config.hasProvider)
    }

    func testNoProviderIsValid() {
        let config = ProviderConfiguration()
        XCTAssertFalse(config.hasProvider)
        XCTAssertNil(config.selection(for: .chat))
    }

    func testServerErrorDoesNotLeakSecret() async {
        let transport = MockTransport { _ in (Data(), 500) }
        let client = ProviderHTTPClient(
            connection: ProviderConnection(name: "Claude", kind: .claude, defaultModel: "m"),
            secret: "secret-value",
            transport: transport
        )
        do {
            _ = try await client.complete(messages: [.user("x")], model: "m")
            XCTFail("Debe fallar")
        } catch {
            XCTAssertFalse(error.localizedDescription.contains("secret-value"))
        }
    }


    func testClaudePayloadUsesMessagesEndpoint() async throws {
        let transport = MockTransport { request in
            XCTAssertEqual(request.url?.path, "/v1/messages")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "claude-key")
            let data = try! JSONSerialization.data(withJSONObject: ["content": [["text": "ok"]]])
            return (data, 200)
        }
        let client = ProviderHTTPClient(
            connection: ProviderConnection(name: "Claude", kind: .claude, defaultModel: "claude-model"),
            secret: "claude-key",
            transport: transport
        )
        let output = try await client.complete(messages: [.user("Hola")], model: "claude-model")
        XCTAssertEqual(output, "ok")
    }

    func testOllamaUsesChatEndpointWithoutKey() async throws {
        let transport = MockTransport { request in
            XCTAssertEqual(request.url?.path, "/api/chat")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let data = try! JSONSerialization.data(withJSONObject: ["message": ["content": "ok"]])
            return (data, 200)
        }
        let client = ProviderHTTPClient(
            connection: ProviderConnection(name: "Ollama", kind: .ollama, defaultModel: "llama"),
            secret: nil,
            transport: transport
        )
        let output = try await client.complete(messages: [.user("Hola")], model: "llama")
        XCTAssertEqual(output, "ok")
    }

    func testNoOAuthIsAdvertised() {
        XCTAssertTrue(ProviderKind.allCases.allSatisfy { !$0.supportsOAuth })
    }

    func testKeychainStoresAndDeletesTestSecret() throws {
        let store = KeychainSecretStore(service: "app.actavoz.providers.tests.\(UUID().uuidString)")
        defer { try? store.delete(account: "test") }
        try store.set("secreto", for: "test")
        XCTAssertEqual(try store.secret(for: "test"), "secreto")
        try store.delete(account: "test")
        XCTAssertNil(try store.secret(for: "test"))
    }
}
