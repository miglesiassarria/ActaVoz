import XCTest
@testable import ActaVozCore

private struct FakeRecognizer: SpeechRecognizing {
    var microphoneText: String = "Hola, soy Ana."
    var systemText: String = "Buenos días."
    var language: SessionLanguage = .spanish

    func transcribe(url: URL, language: SessionLanguage) async throws -> (language: SessionLanguage, utterances: [RecognizedUtterance]) {
        let text = url.lastPathComponent.contains("microfono") ? microphoneText : systemText
        return (self.language, [RecognizedUtterance(text: text, start: 0, end: 2)])
    }
}

private struct FakeDiarizer: SpeakerDiarizing {
    var turns: [SpeakerTurn]

    func turns(for url: URL) async throws -> [SpeakerTurn] { turns }
}

final class SessionProcessingTests: XCTestCase {
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
        try addSource("microfono-1.caf", .microphone)
        try addSource("sistema-1.caf", .system)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func addSource(_ name: String, _ source: CaptureSource) throws {
        let directory = folder.appendingPathComponent("AudioFuentes", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data([0, 1]).write(to: url)
        let fragment = AudioTimelineFragment(
            source: source,
            segmentID: UUID(),
            spans: [.init(fileStart: 0, sessionStart: 0, duration: 60)]
        )
        try fragment.save(for: url)
    }

    private func embedding(_ index: Int) -> [Float] {
        var vector = [Float](repeating: 0, count: 256)
        vector[index] = 1
        return vector
    }

    func testProcessesMicAndSystemWithDiarization() async throws {
        let service = SessionProcessingService(
            repository: repository,
            diarizer: FakeDiarizer(turns: [SpeakerTurn(speakerId: "s1", start: 0, end: 2, embedding: embedding(0))]),
            profileStore: profileStore,
            recognizer: FakeRecognizer()
        )
        let result = try await service.process(folder: folder, options: SessionProcessingOptions())
        XCTAssertEqual(result.session.transcript.segments.count, 2)
        XCTAssertEqual(result.session.transcript.segments.map(\.source), [.microphone, .system])
        XCTAssertTrue(result.session.summary.metadata.participants.contains { $0.id == "me" && $0.name == "Yo" && $0.isConfirmed })
        XCTAssertTrue(result.session.summary.metadata.participants.contains { $0.name == "Interlocutor 1" && !$0.isConfirmed })
        let temporary = TemporaryVoiceStore(sessionFolder: folder)
        XCTAssertTrue(temporary.fileExists(speakerId: "system-s1"))
        XCTAssertTrue(try profileStore.load().isEmpty)
    }

    func testDisablingMicrophoneIdentityLeavesNeutralParticipant() async throws {
        let service = SessionProcessingService(
            repository: repository,
            diarizer: FakeDiarizer(turns: [SpeakerTurn(speakerId: "s1", start: 0, end: 2, embedding: embedding(0))]),
            profileStore: profileStore,
            recognizer: FakeRecognizer()
        )
        let result = try await service.process(
            folder: folder,
            options: SessionProcessingOptions(labelsMicrophoneAsMe: false)
        )
        XCTAssertTrue(result.session.summary.metadata.participants.contains { $0.id == "mic-1" && !$0.isConfirmed })
        XCTAssertFalse(result.session.summary.metadata.participants.contains { $0.id == "me" })
    }

    func testKnownProfileIsProposedButNotConfirmed() async throws {
        _ = try profileStore.saveProfile(name: "Ana", embedding: embedding(0))
        let service = SessionProcessingService(
            repository: repository,
            diarizer: FakeDiarizer(turns: [SpeakerTurn(speakerId: "s1", start: 0, end: 2, embedding: embedding(0))]),
            profileStore: profileStore,
            recognizer: FakeRecognizer()
        )
        let result = try await service.process(folder: folder, options: SessionProcessingOptions())
        let participant = result.session.summary.metadata.participants.first { $0.id == "system-s1" }
        XCTAssertEqual(participant?.name, "Ana")
        XCTAssertEqual(participant?.isConfirmed, false)
        XCTAssertNotNil(participant?.profileID)
    }

    func testSpansMapToSessionTime() {
        let spans = [
            AudioTimelineFragment.Span(fileStart: 0, sessionStart: 10, duration: 5),
            AudioTimelineFragment.Span(fileStart: 5, sessionStart: 18, duration: 5)
        ]
        let mapped = SessionProcessingService.map(start: 4, end: 7, spans: spans)
        XCTAssertEqual(mapped.count, 2)
        XCTAssertEqual(mapped[0].start, 14)
        XCTAssertEqual(mapped[0].end, 15)
        XCTAssertEqual(mapped[1].start, 18)
        XCTAssertEqual(mapped[1].end, 20)
    }
}
