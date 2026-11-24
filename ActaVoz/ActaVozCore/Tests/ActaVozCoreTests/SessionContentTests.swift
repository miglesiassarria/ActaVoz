import XCTest
@testable import ActaVozCore

final class SessionContentTests: XCTestCase {
    private var roots: [URL] = []
    private var repository: SessionRepository!
    private let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-content-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        roots.append(root)
        repository = SessionRepository(root: root)
    }

    override func tearDownWithError() throws {
        for root in roots {
            try? FileManager.default.removeItem(at: root)
        }
        roots = []
    }

    private func readFile(_ name: String, in folder: URL) throws -> String {
        try String(contentsOf: folder.appendingPathComponent(name), encoding: .utf8)
    }

    func testTranscriptKeepsTimestampsAndSpeakers() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let transcript = Transcript(
            language: .spanish,
            segments: [
                TranscriptSegment(id: "s1", start: 0, end: 2.5, speakerId: "p1", text: "Buenos días."),
                TranscriptSegment(id: "s2", start: 2.5, end: 6.0, speakerId: "p2", text: "Revisemos el presupuesto.")
            ]
        )

        try repository.writeTranscript(transcript, at: summary.folderURL)
        let loaded = try repository.loadSession(at: summary.folderURL)
        let raw = try readFile("transcripcion.json", in: summary.folderURL)

        XCTAssertEqual(loaded.transcript, transcript)
        XCTAssertTrue(raw.contains("\"start\" : 2.5"))
        XCTAssertTrue(raw.contains("\"speakerId\" : \"p2\""))
        XCTAssertTrue(raw.contains("\"schemaVersion\" : 2"))
    }

    func testNotesSummarySynthesisAndChatRoundTrip() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let chat = ChatHistory(messages: [
            ChatMessage(id: "m1", role: .user, text: "¿Qué se decidió?", createdAt: startDate),
            ChatMessage(id: "m2", role: .assistant, text: "Se aprobó el presupuesto.", createdAt: startDate)
        ])

        try repository.writeNotes("# Mis notas\n\nIdea propia.", at: summary.folderURL)
        try repository.writeSummary("# Resumen\n\nSe aprobó el presupuesto.", at: summary.folderURL)
        try repository.writeSynthesis("# Síntesis\n\nNotas y reunión.", at: summary.folderURL)
        try repository.writeChat(chat, at: summary.folderURL)

        let loaded = try repository.loadSession(at: summary.folderURL)
        XCTAssertEqual(loaded.notes, "# Mis notas\n\nIdea propia.")
        XCTAssertEqual(loaded.summaryText, "# Resumen\n\nSe aprobó el presupuesto.")
        XCTAssertEqual(loaded.synthesis, "# Síntesis\n\nNotas y reunión.")
        XCTAssertEqual(loaded.chat, chat)
        XCTAssertTrue(loaded.summary.hasSummary)

        for name in ["notas.md", "resumen.md", "sintesis.md", "chat.json"] {
            XCTAssertTrue(FileManager.default.fileExists(
                atPath: summary.folderURL.appendingPathComponent(name).path
            ), "falta \(name)")
        }
    }

    func testAudioIsCopiedAndFlagged() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let source = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        try Data([0x00, 0x01, 0x02]).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        try repository.storeAudio(from: source, at: summary.folderURL)
        let loaded = try repository.loadSession(at: summary.folderURL)

        XCTAssertTrue(loaded.summary.hasAudio)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: repository.audioURL(at: summary.folderURL).path
        ))
    }

    func testSearchFindsExclusiveTermsInEachField() throws {
        let primera = try repository.createSession(in: .inbox, startDate: startDate)
        let segunda = try repository.createSession(in: .inbox, startDate: startDate.addingTimeInterval(60))
        let tercera = try repository.createSession(in: .inbox, startDate: startDate.addingTimeInterval(120))

        try repository.updateTitle("Planificación anual", at: primera.folderURL)
        try repository.writeTranscript(
            Transcript(segments: [
                TranscriptSegment(id: "s1", start: 0, end: 1, speakerId: "p1", text: "Hablemos del presupuesto.")
            ]),
            at: segunda.folderURL
        )
        try repository.writeNotes("Recordar la mudanza de oficina.", at: tercera.folderURL)

        func ids(_ query: String) throws -> [String] {
            try repository.sessions(matching: query).map(\.metadata.id)
        }

        XCTAssertEqual(try ids("planificacion"), [primera.metadata.id])
        XCTAssertEqual(try ids("PRESUPUESTO"), [segunda.metadata.id])
        XCTAssertEqual(try ids("mudanza"), [tercera.metadata.id])
        XCTAssertTrue(try ids("inexistente").isEmpty)
        XCTAssertEqual(try ids("").count, 3)
    }

    func testSearchCoversSummaryAndIsAccentInsensitive() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        try repository.writeSummary("Acuerdo sobre la reunión de dirección.", at: summary.folderURL)

        XCTAssertEqual(try repository.sessions(matching: "reunion").count, 1)
        XCTAssertEqual(try repository.sessions(matching: "DIRECCION").count, 1)
    }

    func testUnknownFilesSurviveAMove() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let extra = summary.folderURL.appendingPathComponent("perfil-voz.bin")
        try Data([1, 2, 3]).write(to: extra)
        try repository.createDirectory(named: "Archivo")

        let moved = try repository.moveSession(at: summary.folderURL, to: .directory("Archivo"))

        XCTAssertTrue(FileManager.default.fileExists(
            atPath: moved.folderURL.appendingPathComponent("perfil-voz.bin").path
        ))
    }

    func testListingSurvivesUnknownFoldersWithoutMetadata() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let stray = repository.inboxDirectory.appendingPathComponent("carpeta-sin-sesion", isDirectory: true)
        try FileManager.default.createDirectory(at: stray, withIntermediateDirectories: true)

        let sessions = try repository.sessions(in: .inbox)

        XCTAssertEqual(sessions.map(\.metadata.id), [summary.metadata.id])
    }
}
