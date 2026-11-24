import Speech
import XCTest
@testable import ActaVozCore

final class AutomaticLanguageTests: XCTestCase {
    private func audio(_ voice: String, _ phrase: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("actavoz-auto-\(UUID().uuidString).aiff")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-v", voice, "-o", url.path, phrase]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw XCTSkip("say no pudo generar el audio") }
        return url
    }

    func testAutomaticDetectsSpanish() async throws {
        guard SpeechTranscriber.isAvailable else { throw XCTSkip("SpeechAnalyzer no disponible") }
        let installed = await SpeechTranscriber.installedLocales.map(\.identifier)
        guard installed.contains("es_ES"), installed.contains("en_US") else { throw XCTSkip("Faltan modelos") }
        let url = try audio("Monica", "Hola, esta es una reunión de prueba.")
        defer { try? FileManager.default.removeItem(at: url) }
        let result = try await LocalSpeechRecognizer().transcribe(url: url, language: .automatic)
        XCTAssertEqual(result.language, .spanish)
        XCTAssertTrue(result.utterances.map(\.text).joined(separator: " ").lowercased().contains("reunión"))
    }

    func testAutomaticDetectsEnglish() async throws {
        guard SpeechTranscriber.isAvailable else { throw XCTSkip("SpeechAnalyzer no disponible") }
        let installed = await SpeechTranscriber.installedLocales.map(\.identifier)
        guard installed.contains("es_ES"), installed.contains("en_US") else { throw XCTSkip("Faltan modelos") }
        let url = try audio("Samantha", "Hello, this is a test meeting.")
        defer { try? FileManager.default.removeItem(at: url) }
        let result = try await LocalSpeechRecognizer().transcribe(url: url, language: .automatic)
        XCTAssertEqual(result.language, .english)
        XCTAssertTrue(result.utterances.map(\.text).joined(separator: " ").lowercased().contains("meeting"))
    }
}
