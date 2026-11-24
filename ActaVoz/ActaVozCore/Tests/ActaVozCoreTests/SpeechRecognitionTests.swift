import Speech
import XCTest
@testable import ActaVozCore

final class SpeechRecognitionTests: XCTestCase {
    func testTranscribesSpanishAudioWithInstalledModel() async throws {
        guard SpeechTranscriber.isAvailable else { throw XCTSkip("SpeechAnalyzer no disponible") }
        let installed = await SpeechTranscriber.installedLocales.map(\.identifier)
        guard installed.contains("es_ES") else { throw XCTSkip("Falta el modelo español instalado") }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("actavoz-asr-\(UUID().uuidString).aiff")
        defer { try? FileManager.default.removeItem(at: url) }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-v", "Monica", "-o", url.path, "Hola, esta es una reunión de prueba."]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw XCTSkip("say no pudo generar el audio") }

        let result = try await LocalSpeechRecognizer().transcribe(url: url, language: .spanish)
        XCTAssertEqual(result.language, .spanish)
        XCTAssertFalse(result.utterances.isEmpty)
        XCTAssertTrue(result.utterances.map(\.text).joined(separator: " ").lowercased().contains("reunión"))
    }

    func testTranscribesEnglishAudioWithInstalledModel() async throws {
        guard SpeechTranscriber.isAvailable else { throw XCTSkip("SpeechAnalyzer no disponible") }
        let installed = await SpeechTranscriber.installedLocales.map(\.identifier)
        guard installed.contains("en_US") else { throw XCTSkip("Falta el modelo inglés instalado") }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("actavoz-asr-\(UUID().uuidString).aiff")
        defer { try? FileManager.default.removeItem(at: url) }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-v", "Samantha", "-o", url.path, "Hello, this is a test meeting."]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw XCTSkip("say no pudo generar el audio") }

        let result = try await LocalSpeechRecognizer().transcribe(url: url, language: .english)
        XCTAssertEqual(result.language, .english)
        XCTAssertFalse(result.utterances.isEmpty)
        XCTAssertTrue(result.utterances.map(\.text).joined(separator: " ").lowercased().contains("meeting"))
    }
}
