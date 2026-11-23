import XCTest
@testable import ActaVozCore

@MainActor
final class LibraryModelTests: XCTestCase {
    private var roots: [URL] = []
    private var repository: SessionRepository!
    private var model: LibraryModel!
    private let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-model-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        roots.append(root)
        repository = SessionRepository(root: root)
        model = LibraryModel(repository: repository)
    }

    override func tearDownWithError() throws {
        for root in roots { try? FileManager.default.removeItem(at: root) }
        roots = []
    }

    func testReloadListsInboxSessionsNewestFirst() throws {
        let older = try repository.createSession(in: .inbox, startDate: startDate)
        let newer = try repository.createSession(in: .inbox, startDate: startDate.addingTimeInterval(3600))

        model.reload()

        XCTAssertEqual(model.sessions.map(\.metadata.id), [newer.metadata.id, older.metadata.id])
        XCTAssertTrue(model.directories.isEmpty)
    }

    func testQueryFiltersByNotesAndTitle() throws {
        let primera = try repository.createSession(in: .inbox, startDate: startDate)
        let segunda = try repository.createSession(in: .inbox, startDate: startDate.addingTimeInterval(60))
        try repository.writeNotes("mudanza de oficina", at: primera.folderURL)
        try repository.updateTitle("Presupuesto anual", at: segunda.folderURL)
        model.reload()

        model.updateQuery("mudanza")
        XCTAssertEqual(model.sessions.map(\.metadata.id), [primera.metadata.id])

        model.updateQuery("presupuesto")
        XCTAssertEqual(model.sessions.map(\.metadata.id), [segunda.metadata.id])

        model.updateQuery("")
        XCTAssertEqual(model.sessions.count, 2)
    }

    func testSelectingDirectoryShowsOnlyItsSessions() throws {
        try repository.createDirectory(named: "Clientes")
        _ = try repository.createSession(in: .inbox, startDate: startDate)
        let clients = try repository.createSession(in: .directory("Clientes"), startDate: startDate)
        model.reload()

        model.select(.directory("Clientes"))

        XCTAssertEqual(model.directories, ["Clientes"])
        XCTAssertEqual(model.sessions.map(\.metadata.id), [clients.metadata.id])
    }

    func testCreateDirectorySelectsIt() throws {
        model.newDirectoryName = "Proyectos"
        model.createDirectory()

        XCTAssertEqual(model.directories, ["Proyectos"])
        XCTAssertEqual(model.selection, .directory("Proyectos"))
    }

    func testDeletionNeedsConfirmationAndCancelKeepsData() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        model.reload()
        model.selectedSession = summary

        model.requestDeleteSession()
        XCTAssertNotNil(model.deletion)
        model.cancelDeletion()
        XCTAssertNil(model.deletion)
        XCTAssertTrue(FileManager.default.fileExists(atPath: summary.folderURL.path))

        model.requestDeleteSession()
        model.confirmDeletion()
        XCTAssertFalse(FileManager.default.fileExists(atPath: summary.folderURL.path))
        model.reload()
        XCTAssertTrue(model.sessions.isEmpty)
    }

    func testMovingSelectedSessionChangesLocation() throws {
        try repository.createDirectory(named: "Clientes")
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        model.reload()
        model.selectedSession = summary

        model.moveSelectedSession(to: .directory("Clientes"))

        XCTAssertEqual(model.selection, .directory("Clientes"))
        XCTAssertEqual(model.selectedSession?.location, .directory("Clientes"))
        XCTAssertTrue(try repository.sessions(in: .inbox).isEmpty)
    }
}

@MainActor
final class SessionModelTests: XCTestCase {
    private var roots: [URL] = []
    private var repository: SessionRepository!
    private let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-sessionmodel-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        roots.append(root)
        repository = SessionRepository(root: root)
    }

    override func tearDownWithError() throws {
        for root in roots { try? FileManager.default.removeItem(at: root) }
        roots = []
    }

    func testLoadExposesContents() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        try repository.writeNotes("# Nota", at: summary.folderURL)
        let model = SessionModel(repository: repository, folderURL: summary.folderURL)

        model.load()

        XCTAssertEqual(model.session?.notes, "# Nota")
        XCTAssertNil(model.errorMessage)
    }

    func testSavingTitlePersistsWithoutRenamingFolder() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let model = SessionModel(repository: repository, folderURL: summary.folderURL)
        model.load()

        model.saveTitle("Reunión de dirección")

        XCTAssertEqual(model.session?.summary.title, "Reunión de dirección")
        XCTAssertEqual(try repository.loadSession(at: summary.folderURL).summary.title, "Reunión de dirección")
        XCTAssertEqual(model.session?.summary.folderURL.lastPathComponent, summary.folderURL.lastPathComponent)
    }

    func testRenamingParticipantPersists() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        try repository.updateParticipants([Participant(id: "p1", name: "Interlocutor 1")], at: summary.folderURL)
        let model = SessionModel(repository: repository, folderURL: summary.folderURL)
        model.load()

        model.renameParticipant(id: "p1", to: "Ana")

        XCTAssertEqual(model.session?.summary.metadata.participants.first?.name, "Ana")
        XCTAssertEqual(
            try repository.loadSession(at: summary.folderURL).summary.metadata.participants.first?.name,
            "Ana"
        )
    }

    func testSavingNotesWritesMarkdown() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let model = SessionModel(repository: repository, folderURL: summary.folderURL)
        model.load()

        model.saveNotes("# Mis notas\n\nIdea")

        let raw = try String(
            contentsOf: summary.folderURL.appendingPathComponent("notas.md"),
            encoding: .utf8
        )
        XCTAssertEqual(raw, "# Mis notas\n\nIdea")
        XCTAssertEqual(model.session?.notes, raw)
    }
}
