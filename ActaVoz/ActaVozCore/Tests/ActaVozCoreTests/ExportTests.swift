import XCTest
@testable import ActaVozCore

final class ExportTests: XCTestCase {
    private func sample() -> Session {
        let metadata = SessionMetadata(
            id: "S1",
            title: "Reunión de prueba",
            startDate: Date(timeIntervalSince1970: 0),
            language: .spanish,
            participants: [Participant(id: "a", name: "Ana"), Participant(id: "b", name: "Luis")]
        )
        let transcript = Transcript(segments: [
            TranscriptSegment(id: "1", start: 0, end: 2, speakerId: "a", text: "Hola"),
            TranscriptSegment(id: "2", start: 65, end: 67, speakerId: "b", text: "Adiós")
        ])
        let summary = SessionSummary(metadata: metadata, location: .inbox, folderURL: URL(fileURLWithPath: "/tmp"), hasAudio: false, hasSummary: true)
        return Session(summary: summary, transcript: transcript, notes: "Nota", summaryText: "Resumen", synthesis: "Síntesis", chat: ChatHistory())
    }

    func testTranscriptIncludesSpeakerAndTime() {
        let text = ExportService().transcript(sample())
        XCTAssertTrue(text.contains("[00:00] Ana: Hola"))
        XCTAssertTrue(text.contains("[01:05] Luis: Adiós"))
    }

    func testNotesIncludeSynthesisOnlyWhenRequested() {
        let service = ExportService()
        XCTAssertFalse(service.notes(sample(), includeSynthesis: false).contains("Síntesis"))
        XCTAssertTrue(service.notes(sample(), includeSynthesis: true).contains("Síntesis"))
    }

    func testMarkdownAndPlainRender() {
        let service = ExportService()
        let md = service.render(.summary, session: sample(), format: .markdown)
        XCTAssertTrue(md.hasPrefix("# Reunión de prueba"))
        XCTAssertEqual(service.render(.summary, session: sample(), format: .plainText), "Resumen")
    }

    func testSuggestedFilename() {
        XCTAssertEqual(
            ExportService().suggestedFilename(.transcript, title: "A/B", format: .markdown),
            "A-B-transcripcion.md"
        )
    }
}
