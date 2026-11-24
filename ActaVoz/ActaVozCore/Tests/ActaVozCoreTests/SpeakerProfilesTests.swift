import XCTest
@testable import ActaVozCore

final class SpeakerProfilesTests: XCTestCase {
    private var root: URL!
    private var store: SpeakerProfileStore!
    private var temp: TemporaryVoiceStore!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        store = SpeakerProfileStore(fileURL: root.appendingPathComponent("perfiles.json"))
        temp = TemporaryVoiceStore(sessionFolder: root)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func embedding(_ index: Int, value: Float = 1) -> [Float] {
        var vector = [Float](repeating: 0, count: 256)
        vector[index] = value
        return vector
    }

    func testSaveRenameDeleteAndMatch() throws {
        let ana = try store.saveProfile(name: "Ana", embedding: embedding(0))
        XCTAssertEqual(try store.load().count, 1)
        XCTAssertEqual(try store.match(embedding: embedding(0))?.profile.id, ana.id)
        XCTAssertNil(try store.match(embedding: embedding(1)))
        try store.rename(id: ana.id, to: "Ana María")
        XCTAssertEqual(try store.load().first?.name, "Ana María")
        try store.delete(id: ana.id)
        XCTAssertTrue(try store.load().isEmpty)
    }

    func testRejectsInvalidEmbedding() {
        XCTAssertThrowsError(try store.saveProfile(name: "Ana", embedding: [1, 2, 3]))
    }

    func testTemporaryVoiceCanCreateLateProfileWithoutAudio() throws {
        try temp.save(speakerId: "p1", embedding: embedding(2))
        XCTAssertTrue(temp.fileExists(speakerId: "p1"))
        let updated = try SpeakerProfileService.confirm(
            speakerId: "p1",
            name: "Ana",
            session: session(),
            profilesEnabled: true,
            store: store,
            temporaryStore: temp
        )
        XCTAssertEqual(updated.summary.metadata.participants.first?.name, "Ana")
        XCTAssertNotNil(updated.summary.metadata.participants.first?.profileID)
        XCTAssertEqual(try store.load().count, 1)
        XCTAssertFalse(temp.fileExists(speakerId: "p1"))
    }

    func testDisabledProfilesPurgeTemporaryVoice() throws {
        try temp.save(speakerId: "p1", embedding: embedding(0))
        _ = try SpeakerProfileService.finalize(
            session: session(),
            profilesEnabled: false,
            store: store,
            temporaryStore: temp
        )
        XCTAssertFalse(temp.fileExists(speakerId: "p1"))
        XCTAssertTrue(try store.load().isEmpty)
    }

    func testFinalizeOnlySavesConfirmedParticipants() throws {
        try temp.save(speakerId: "p1", embedding: embedding(0))
        try temp.save(speakerId: "p2", embedding: embedding(1))
        var current = session()
        current.summary.metadata.participants[0].name = "Ana"
        current.summary.metadata.participants[0].isConfirmed = true
        let updated = try SpeakerProfileService.finalize(
            session: current,
            profilesEnabled: true,
            store: store,
            temporaryStore: temp
        )
        XCTAssertEqual(try store.load().map(\.name), ["Ana"])
        XCTAssertFalse(temp.fileExists(speakerId: "p1"))
        XCTAssertTrue(temp.fileExists(speakerId: "p2"))
        XCTAssertNotNil(updated.summary.metadata.participants[0].profileID)
    }

    func testProposalUsesThresholdAndDoesNotConfirm() throws {
        _ = try store.saveProfile(name: "Ana", embedding: embedding(0))
        try temp.save(speakerId: "p2", embedding: embedding(0))
        let match = SpeakerProfileService.proposal(for: "p2", temporaryStore: temp, store: store)
        XCTAssertEqual(match?.profile.name, "Ana")
        XCTAssertFalse(session().summary.metadata.participants[1].isConfirmed)
    }

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
        return Session(
            summary: SessionSummary(metadata: metadata, location: .inbox, folderURL: root, hasAudio: false, hasSummary: false),
            transcript: Transcript(segments: []),
            notes: "",
            summaryText: "",
            synthesis: "",
            chat: ChatHistory()
        )
    }
}
