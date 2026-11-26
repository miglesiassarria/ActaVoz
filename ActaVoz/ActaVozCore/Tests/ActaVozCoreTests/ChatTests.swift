import XCTest
@testable import ActaVozCore

private actor SpyResponder: ChatResponding {
    struct Call: Sendable {
        var transcript: String
        var history: [ChatMessage]
        var question: String
    }

    private(set) var calls: [Call] = []
    var delay: UInt64 = 0
    var failures = 0

    func answer(transcript: String, history: [ChatMessage], question: String) async throws -> String {
        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        if failures > 0 {
            failures -= 1
            throw ProviderError.unavailable("simulado")
        }
        calls.append(Call(transcript: transcript, history: history, question: question))
        return "respuesta-\(calls.count)"
    }

    func snapshot() -> [Call] { calls }
    func setDelay(_ value: UInt64) { delay = value }
    func setFailures(_ value: Int) { failures = value }
}

private final class ChatTransport: HTTPTransport, @unchecked Sendable {
    var bodies: [[String: Any]] = []
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any] ?? [:]
        bodies.append(body)
        let data = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": "ok"]]]])
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

@MainActor
final class ChatTests: XCTestCase {
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func waitUntil(_ condition: @escaping () -> Bool) async {
        for _ in 0..<100 {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    func testQuestionUsesFullTranscriptAndPersists() async throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let spy = SpyResponder()
        let model = SessionChatModel(folderURL: dir, responder: spy, transcriptProvider: { "Texto completo" })
        model.draft = "¿Qué se decidió?"
        model.ask()
        await waitUntil { !model.isResponding && model.messages.count == 2 }
        XCTAssertEqual(model.messages.map(\.role), [.user, .assistant])
        let calls = await spy.snapshot()
        XCTAssertEqual(calls.first?.transcript, "Texto completo")
        XCTAssertEqual(calls.first?.history, [])

        let reopened = SessionChatModel(folderURL: dir, responder: spy, transcriptProvider: { "Texto completo" })
        XCTAssertEqual(reopened.messages.count, 2)
        let data = try Data(contentsOf: dir.appendingPathComponent("chat.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let history = try decoder.decode(ChatHistory.self, from: data)
        XCTAssertEqual(history.messages.count, 2)
    }

    func testSecondQuestionIncludesPreviousTurnAndNewTranscript() async throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let spy = SpyResponder()
        var transcript = "Primera parte"
        let model = SessionChatModel(folderURL: dir, responder: spy, transcriptProvider: { transcript })
        model.draft = "Pregunta uno"
        model.ask()
        await waitUntil { !model.isResponding && model.messages.count == 2 }
        transcript = "Primera parte y segunda"
        model.draft = "Pregunta dos"
        model.ask()
        await waitUntil { !model.isResponding && model.messages.count == 4 }
        let calls = await spy.snapshot()
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[1].transcript, "Primera parte y segunda")
        XCTAssertEqual(calls[1].history.count, 2)
        XCTAssertEqual(calls[1].history.first?.text, "Pregunta uno")
    }

    func testQueuedQuestionsKeepOrder() async throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let spy = SpyResponder()
        await setDelay(spy, 300_000_000)
        let model = SessionChatModel(folderURL: dir, responder: spy, transcriptProvider: { "TX" })
        model.draft = "Primera"
        model.ask()
        model.draft = "Segunda"
        model.ask()
        XCTAssertEqual(model.pendingQuestions, ["Segunda"])
        await waitUntil { !model.isResponding && model.messages.count == 4 }
        let calls = await spy.snapshot()
        XCTAssertEqual(calls.map(\.question), ["Primera", "Segunda"])
        XCTAssertEqual(calls[1].history.count, 2)
    }

    func testFailureShowsErrorAndRetryCompletes() async throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let spy = SpyResponder()
        await setFailures(spy, 1)
        let model = SessionChatModel(folderURL: dir, responder: spy, transcriptProvider: { "TX" })
        model.draft = "Falla"
        model.ask()
        await waitUntil { !model.isResponding && model.errorMessage != nil }
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertEqual(model.messages.first?.role, .user)
        XCTAssertNotNil(model.errorMessage)
        model.retry()
        await waitUntil { !model.isResponding && model.messages.count == 2 }
        XCTAssertEqual(model.messages.last?.role, .assistant)
        XCTAssertNil(model.errorMessage)
    }

    func testProviderChatUsesConfiguredModelAndTextOnly() async throws {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let config = ProviderConfiguration(
            connections: [ProviderConnection(id: "c1", name: "Mock", kind: .openAI, baseURL: "https://mock", defaultModel: "principal")],
            activeConnectionID: "c1",
            chatModel: ModelSelection(connectionID: "c1", model: "chat-model")
        )
        let store = ProviderConfigurationStore(fileURL: root.appendingPathComponent("proveedores.json"))
        try store.save(config)
        let secrets = InMemorySecretStore()
        try secrets.set("clave", for: "c1")
        let transport = ChatTransport()
        let responder = ProviderChatResponder(configurationStore: store, secrets: secrets, transport: transport)
        let answer = try await responder.answer(
            transcript: "Transcripción completa",
            history: [ChatMessage(id: "1", role: .user, text: "Antes", createdAt: Date())],
            question: "Ahora"
        )
        XCTAssertEqual(answer, "ok")
        XCTAssertEqual(transport.bodies.first?["model"] as? String, "chat-model")
        let messages = transport.bodies.first?["messages"] as? [[String: Any]]
        XCTAssertTrue(messages?.contains { ($0["content"] as? String)?.contains("Transcripción completa") == true } == true)
        XCTAssertFalse(String(data: try JSONSerialization.data(withJSONObject: transport.bodies), encoding: .utf8)?.contains("audio") == true)
    }

    private func setDelay(_ spy: SpyResponder, _ value: UInt64) async {
        await spy.setDelay(value)
    }

    private func setFailures(_ spy: SpyResponder, _ value: Int) async {
        await spy.setFailures(value)
    }
}
