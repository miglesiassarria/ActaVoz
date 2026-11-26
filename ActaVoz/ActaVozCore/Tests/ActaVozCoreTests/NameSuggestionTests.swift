import XCTest
@testable import ActaVozCore

private final class NameTransport: HTTPTransport, @unchecked Sendable {
    var bodies: [[String: Any]] = []
    var answer = "a: Ana\nb: Luis\nc: Invención"
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        bodies.append(try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any] ?? [:])
        let data = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": answer]]]])
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

final class NameSuggestionTests: XCTestCase {
    func testParseOnlyKnownParticipants() {
        let participants = [Participant(id: "a", name: "Interlocutor 1"), Participant(id: "b", name: "Interlocutor 2")]
        let parsed = ProviderNameSuggester.parse("a: Ana\nb: Luis\nc: Otro", participants: participants)
        XCTAssertEqual(parsed, ["a": "Ana", "b": "Luis"])
    }

    func testUsesPrimaryModelAndTranscriptText() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let config = ProviderConfiguration(
            connections: [ProviderConnection(id: "c", name: "Mock", kind: .openAI, baseURL: "https://mock", defaultModel: "principal")],
            activeConnectionID: "c",
            summaryModel: ModelSelection(connectionID: "c", model: "resumen")
        )
        let store = ProviderConfigurationStore(fileURL: root.appendingPathComponent("proveedores.json"))
        try store.save(config)
        let secrets = InMemorySecretStore()
        try secrets.set("k", for: "c")
        let transport = NameTransport()
        let suggester = ProviderNameSuggester(configurationStore: store, secrets: secrets, transport: transport)
        let result = try await suggester.suggest(transcript: "Me llamo Ana", participants: [Participant(id: "a", name: "Interlocutor 1")])
        XCTAssertEqual(result["a"], "Ana")
        XCTAssertEqual(transport.bodies.first?["model"] as? String, "principal")
    }
}
