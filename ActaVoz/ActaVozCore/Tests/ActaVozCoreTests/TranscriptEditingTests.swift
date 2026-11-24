import XCTest
@testable import ActaVozCore

final class TranscriptEditingTests: XCTestCase {
    private func session() -> Session {
        let metadata = SessionMetadata(
            id: "S1",
            title: "Prueba",
            startDate: Date(timeIntervalSince1970: 0),
            participants: [
                Participant(id: "p1", name: "Interlocutor 1"),
                Participant(id: "p2", name: "Interlocutor 2")
            ]
        )
        let transcript = Transcript(segments: [
            TranscriptSegment(id: "s1", start: 0, end: 2, speakerId: "p1", text: "Me llamo Ana."),
            TranscriptSegment(id: "s2", start: 2, end: 4, speakerId: "p1", text: "Hola."),
            TranscriptSegment(id: "s3", start: 4, end: 6, speakerId: "p2", text: "Soy Luis.")
        ])
        return Session(
            summary: SessionSummary(
                metadata: metadata,
                location: .inbox,
                folderURL: URL(fileURLWithPath: "/tmp/S1"),
                hasAudio: false,
                hasSummary: false
            ),
            transcript: transcript,
            notes: "",
            summaryText: "",
            synthesis: "",
            chat: ChatHistory()
        )
    }

    func testRenameAppliesToAllSegmentsAndConfirms() throws {
        let updated = try TranscriptEditor.rename(speakerId: "p1", to: "Ana", in: session())
        XCTAssertEqual(updated.summary.metadata.participants.first(where: { $0.id == "p1" })?.name, "Ana")
        XCTAssertEqual(updated.summary.metadata.participants.first(where: { $0.id == "p1" })?.isConfirmed, true)
        XCTAssertTrue(updated.transcript.segments.filter { $0.speakerId == "p1" }.allSatisfy { $0.text.contains("Ana") || $0.text == "Hola." })
        XCTAssertEqual(updated.transcript.segments.filter { $0.speakerId == "p1" }.count, 2)
    }

    func testReassignChangesOnlyOneSegment() throws {
        let updated = try TranscriptEditor.reassign(segmentId: "s1", to: "p2", in: session())
        XCTAssertEqual(updated.transcript.segments.first(where: { $0.id == "s1" })?.speakerId, "p2")
        XCTAssertEqual(updated.transcript.segments.first(where: { $0.id == "s2" })?.speakerId, "p1")
    }

    func testMergeMovesSegmentsAndRemovesSource() throws {
        let updated = try TranscriptEditor.merge(source: "p1", into: "p2", in: session())
        XCTAssertEqual(updated.summary.metadata.participants.count, 1)
        XCTAssertTrue(updated.transcript.segments.allSatisfy { $0.speakerId == "p2" })
    }

    func testNameDeducerFindsExplicitNames() {
        let transcript = session().transcript
        let suggestions = NameDeducer.suggestions(in: transcript)
        XCTAssertTrue(suggestions.contains { $0.name == "Ana" && $0.speakerId == "p1" })
        XCTAssertTrue(suggestions.contains { $0.name == "Luis" && $0.speakerId == "p2" })
    }

    func testNameDeducerIgnoresAmbiguousText() {
        XCTAssertTrue(NameDeducer.suggestions(in: "Hola, ¿qué tal?", speakerId: "p1").isEmpty)
    }

    func testNormalizedSortsAndDeduplicates() {
        let transcript = Transcript(segments: [
            TranscriptSegment(id: "b", start: 2, end: 3, speakerId: "p1", text: "b"),
            TranscriptSegment(id: "a", start: 0, end: 1, speakerId: "p1", text: "a"),
            TranscriptSegment(id: "a", start: 0, end: 1, speakerId: "p1", text: "a")
        ])
        XCTAssertEqual(TranscriptEditor.normalized(transcript).segments.map(\.id), ["a", "b"])
    }
}
