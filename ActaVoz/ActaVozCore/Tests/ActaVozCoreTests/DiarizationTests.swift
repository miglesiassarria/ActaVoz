import XCTest
@testable import ActaVozCore

final class DiarizationTests: XCTestCase {
    func testAssignsByOverlap() {
        let utterances = [
            RecognizedUtterance(text: "A", start: 0, end: 1),
            RecognizedUtterance(text: "B", start: 2, end: 3)
        ]
        let turns = [
            SpeakerTurn(speakerId: "s1", start: 0, end: 1.2),
            SpeakerTurn(speakerId: "s2", start: 1.8, end: 3)
        ]
        let assigned = SpeakerAssignment.assign(utterances: utterances, turns: turns)
        XCTAssertEqual(assigned.map(\.speakerId), ["s1", "s2"])
    }

    func testAssignsNearestWhenNoOverlap() {
        let utterance = RecognizedUtterance(text: "A", start: 5, end: 6)
        let turns = [
            SpeakerTurn(speakerId: "s1", start: 0, end: 1),
            SpeakerTurn(speakerId: "s2", start: 9, end: 10)
        ]
        XCTAssertEqual(SpeakerAssignment.assign(utterances: [utterance], turns: turns).first?.speakerId, "s2")
    }

    func testCentroidIsNormalized() {
        var first = [Float](repeating: 0, count: 256); first[0] = 1
        var second = [Float](repeating: 0, count: 256); second[0] = 3
        let centroid = SpeakerAssignment.centroid(for: "s1", turns: [
            SpeakerTurn(speakerId: "s1", start: 0, end: 1, embedding: first),
            SpeakerTurn(speakerId: "s1", start: 1, end: 2, embedding: second)
        ])
        XCTAssertEqual(centroid.count, 256)
        XCTAssertEqual(centroid[0], 1, accuracy: 0.0001)
    }
}
