import XCTest
@testable import ActaVozCore

private struct FixedSynthesis: SynthesisResponding {
    var output: String
    func generate(notes: String, summary: String) async throws -> String { output }
}

private struct FailingSynthesis: SynthesisResponding {
    func generate(notes: String, summary: String) async throws -> String { throw ProviderError.unavailable("fallo") }
}

private final class SynthesisTransport: HTTPTransport, @unchecked Sendable {
    var bodies: [[String: Any]] = []
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        bodies.append(try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any] ?? [:])
        let data = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": "síntesis"]]]])
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

final class SynthesisTests: XCTestCase {
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testRequiresSummary() async throws {
        let service = SynthesisService(responder: FixedSynthesis(output: "x"))
        do {
            _ = try await service.generate(notes: "n", summary: "")
            XCTFail("Debe exigir resumen")
        } catch {
            XCTAssertEqual((error as? SummaryServiceError), .summaryRequired)
        }
    }

    func testSaveUpdateDeleteKeepsSources() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        try "Notas".write(to: dir.appendingPathComponent("notas.md"), atomically: true, encoding: .utf8)
        try "Resumen".write(to: dir.appendingPathComponent("resumen.md"), atomically: true, encoding: .utf8)
        let service = SynthesisService(responder: FixedSynthesis(output: "uno"))
        try service.save("uno", notes: "Notas", summary: "Resumen", at: dir)
        XCTAssertTrue(service.needsUpdate(notes: "Notas nuevas", summary: "Resumen", at: dir))
        XCTAssertFalse(service.needsUpdate(notes: "Notas", summary: "Resumen", at: dir))
        try service.save("dos", notes: "Notas nuevas", summary: "Resumen", at: dir)
        XCTAssertEqual(try String(contentsOf: dir.appendingPathComponent("sintesis.md"), encoding: .utf8), "dos")
        try service.delete(at: dir)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("sintesis.md").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent("notas.md").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent("resumen.md").path))
    }

    func testProviderUsesSummaryModelAndBothSources() async throws {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let config = ProviderConfiguration(
            connections: [ProviderConnection(id: "c", name: "Mock", kind: .openAI, baseURL: "https://mock", defaultModel: "principal")],
            activeConnectionID: "c",
            summaryModel: ModelSelection(connectionID: "c", model: "resumen-model")
        )
        let store = ProviderConfigurationStore(fileURL: root.appendingPathComponent("proveedores.json"))
        try store.save(config)
        let secrets = InMemorySecretStore()
        try secrets.set("k", for: "c")
        let transport = SynthesisTransport()
        let responder = ProviderSynthesisResponder(configurationStore: store, secrets: secrets, transport: transport)
        _ = try await responder.generate(notes: "NOTA", summary: "RESUMEN")
        XCTAssertEqual(transport.bodies.first?["model"] as? String, "resumen-model")
        let joined = (transport.bodies.first?["messages"] as? [[String: Any]])?.compactMap { $0["content"] as? String }.joined() ?? ""
        XCTAssertTrue(joined.contains("NOTA"))
        XCTAssertTrue(joined.contains("RESUMEN"))
    }

    func testFailureLeavesPreviousSynthesis() async throws {
        let service = SynthesisService(responder: FailingSynthesis())
        do {
            _ = try await service.generate(notes: "n", summary: "s")
            XCTFail("Debe fallar")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
