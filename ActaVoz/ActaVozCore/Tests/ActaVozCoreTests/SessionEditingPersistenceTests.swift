import XCTest
@testable import ActaVozCore

@MainActor
final class SessionEditingPersistenceTests: XCTestCase {
    private var root: URL!
    private var repository: SessionRepository!
    private var folder: URL!
    private var profileStore: SpeakerProfileStore!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        repository = SessionRepository(root: root)
        folder = try repository.createSession(in: .inbox, language: .spanish).folderURL
        profileStore = SpeakerProfileStore(fileURL: root.appendingPathComponent("perfiles.json"))
        try repository.updateParticipants([
            Participant(id: "p1", name: "Interlocutor 1"),
            Participant(id: "p2", name: "Interlocutor 2")
        ], at: folder)
        try repository.writeTranscript(Transcript(segments: [
            TranscriptSegment(id: "s1", start: 0, end: 2, speakerId: "p1", text: "Uno."),
            TranscriptSegment(id: "s2", start: 2, end: 4, speakerId: "p2", text: "Dos."),
            TranscriptSegment(id: "s3", start: 4, end: 6, speakerId: "p1", text: "Tres.")
        ]), at: folder)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func model() -> SessionModel {
        SessionModel(repository: repository, folderURL: folder, profileStore: profileStore)
    }

    func testRenamePersistsAcrossReload() throws {
        let model = model()
        model.load()
        model.renameParticipant(id: "p1", to: "Ana")
        let reloaded = try repository.loadSession(at: folder)
        let participant = reloaded.summary.metadata.participants.first { $0.id == "p1" }
        XCTAssertEqual(participant?.name, "Ana")
        XCTAssertEqual(participant?.isConfirmed, true)
        XCTAssertEqual(reloaded.transcript.segments.first { $0.id == "s1" }?.speakerId, "p1")
    }

    func testReassignPersistsOnlyOneSegment() throws {
        let model = model()
        model.load()
        model.reassignSegment(id: "s1", to: "p2")
        let reloaded = try repository.loadSession(at: folder)
        XCTAssertEqual(reloaded.transcript.segments.first { $0.id == "s1" }?.speakerId, "p2")
        XCTAssertEqual(reloaded.transcript.segments.first { $0.id == "s3" }?.speakerId, "p1")
    }

    func testMergePersistsAndRemovesSourceParticipant() throws {
        let model = model()
        model.load()
        model.mergeSpeakers(source: "p1", into: "p2")
        let reloaded = try repository.loadSession(at: folder)
        XCTAssertEqual(reloaded.summary.metadata.participants.map(\.id), ["p2"])
        XCTAssertTrue(reloaded.transcript.segments.allSatisfy { $0.speakerId == "p2" })
    }

    func testLateConfirmationCreatesProfileWithoutAudio() throws {
        let temporary = TemporaryVoiceStore(sessionFolder: folder)
        var vector = [Float](repeating: 0, count: 256); vector[0] = 1
        try temporary.save(speakerId: "p1", embedding: vector)
        let model = model()
        model.load()
        model.confirmParticipant(id: "p1", name: "Ana")
        let reloaded = try repository.loadSession(at: folder)
        XCTAssertEqual(reloaded.summary.metadata.participants.first { $0.id == "p1" }?.name, "Ana")
        XCTAssertNotNil(reloaded.summary.metadata.participants.first { $0.id == "p1" }?.profileID)
        XCTAssertEqual(try profileStore.load().map(\.name), ["Ana"])
        XCTAssertFalse(temporary.fileExists(speakerId: "p1"))
    }
}
