import XCTest
@testable import ActaVozCore

private final class SummaryTransport: HTTPTransport, @unchecked Sendable {
    var bodies: [[String: Any]] = []
    var status = 200
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        bodies.append(try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any] ?? [:])
        let data = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": "# Resumen"]]]])
        return (data, HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}

private struct FailingSummary: SummaryResponding {
    func generate(template: SummaryTemplate, transcript: String) async throws -> String {
        throw ProviderError.unavailable("fallo simulado")
    }
}

final class SummaryTests: XCTestCase {
    func testFourBuiltInsAndSections() throws {
        let templates = SummaryTemplateCatalog.builtIns
        XCTAssertEqual(templates.count, 4)
        XCTAssertEqual(templates.map(\.name), ["Resumen general", "Reunión de trabajo", "Reunión individual", "Reflexión personal"])
        XCTAssertEqual(templates[1].sections.count, 4)
        XCTAssertTrue(templates.allSatisfy(\.isBuiltIn))
    }

    func testCustomTemplatesSearchDuplicateAndDelete() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SummaryTemplateStore(fileURL: root.appendingPathComponent("plantillas.json"))
        let created = try store.create(name: "Mi plantilla", instructions: "Sé breve", sections: ["A", "B"])
        XCTAssertEqual(try store.search("mi plant").map(\.id), [created.id])
        let copy = try store.duplicateBuiltIn(SummaryTemplateCatalog.builtIns[0])
        XCTAssertFalse(copy.isBuiltIn)
        XCTAssertEqual(try store.search("copia").count, 1)
        XCTAssertThrowsError(try store.update(SummaryTemplateCatalog.builtIns[0])) { error in
            XCTAssertEqual(error as? SummaryTemplateError, .builtInImmutable)
        }
        try store.delete(id: created.id)
        XCTAssertEqual(try store.search("Mi plantilla").count, 0)
    }

    func testProviderSummaryUsesSummaryModelAndExcludesNotes() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let config = ProviderConfiguration(
            connections: [ProviderConnection(id: "c", name: "Mock", kind: .openAI, baseURL: "https://mock", defaultModel: "principal")],
            activeConnectionID: "c",
            summaryModel: ModelSelection(connectionID: "c", model: "resumen-model")
        )
        let store = ProviderConfigurationStore(fileURL: root.appendingPathComponent("proveedores.json"))
        try store.save(config)
        let secrets = InMemorySecretStore()
        try secrets.set("clave", for: "c")
        let transport = SummaryTransport()
        let responder = ProviderSummaryResponder(configurationStore: store, secrets: secrets, transport: transport)
        _ = try await responder.generate(template: SummaryTemplateCatalog.builtIns[0], transcript: "Transcripción")
        XCTAssertEqual(transport.bodies.first?["model"] as? String, "resumen-model")
        let messages = transport.bodies.first?["messages"] as? [[String: Any]]
        let joined = messages?.compactMap { $0["content"] as? String }.joined() ?? ""
        XCTAssertTrue(joined.contains("Síntesis"))
        XCTAssertFalse(joined.contains("notas personales inventadas"))
    }

    func testFailureDoesNotReplaceExistingSummaryAndDeleteKeepsOtherFiles() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try "Resumen anterior".write(to: folder.appendingPathComponent("resumen.md"), atomically: true, encoding: .utf8)
        try "Transcripción".write(to: folder.appendingPathComponent("transcripcion.json"), atomically: true, encoding: .utf8)
        try "Notas".write(to: folder.appendingPathComponent("notas.md"), atomically: true, encoding: .utf8)
        let service = SummaryService(responder: FailingSummary())
        do {
            _ = try await service.generate(template: SummaryTemplateCatalog.builtIns[0], transcript: "Transcripción")
            _ = try service.save("nuevo", at: folder)
            XCTFail("Debe fallar")
        } catch {
            XCTAssertEqual(try String(contentsOf: folder.appendingPathComponent("resumen.md"), encoding: .utf8), "Resumen anterior")
        }
        try service.delete(at: folder)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("resumen.md").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("notas.md").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("transcripcion.json").path))
    }

    func testManualEditMarker() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let service = SummaryService(responder: FailingSummary())
        try service.markEdited(true, at: folder)
        XCTAssertTrue(service.wasManuallyEdited(at: folder))
        try service.save("generado", at: folder)
        XCTAssertFalse(service.wasManuallyEdited(at: folder))
    }
}
