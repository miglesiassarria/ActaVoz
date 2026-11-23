import XCTest
@testable import ActaVozCore

final class SessionRepositoryTests: XCTestCase {
    private var roots: [URL] = []
    private var repository: SessionRepository!
    private let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-repo-\(UUID().uuidString)", isDirectory: true)
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

    func testCreateSessionUsesDateAndShortIDUnderNotas() throws {
        let id = SessionID(rawValue: "ABC123")
        let summary = try repository.createSession(in: .inbox, startDate: startDate, id: id)

        XCTAssertEqual(summary.location, .inbox)
        XCTAssertTrue(summary.folderURL.path.hasPrefix(repository.inboxDirectory.path))
        XCTAssertTrue(summary.folderURL.lastPathComponent.hasSuffix("_ABC123"))
        XCTAssertTrue(summary.metadata.title.contains("2023-11-14"))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: summary.folderURL.appendingPathComponent("sesion.json").path
        ))
    }

    func testTwoSessionsAtTheSameInstantGetDifferentFolders() throws {
        let first = try repository.createSession(in: .inbox, startDate: startDate)
        let second = try repository.createSession(in: .inbox, startDate: startDate)

        XCTAssertNotEqual(first.metadata.id, second.metadata.id)
        XCTAssertNotEqual(first.folderURL, second.folderURL)
        XCTAssertEqual(try repository.sessions(in: .inbox).count, 2)
    }

    func testTitleCanChangeWithoutRenamingTheFolder() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let folderName = summary.folderURL.lastPathComponent

        try repository.updateTitle("Reunión de producto", at: summary.folderURL)
        let loaded = try repository.loadSession(at: summary.folderURL)

        XCTAssertEqual(loaded.summary.title, "Reunión de producto")
        XCTAssertEqual(loaded.summary.folderURL.lastPathComponent, folderName)
    }

    func testParticipantCorrectionsSurviveReopening() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        let participants = [
            Participant(id: "p1", name: "Ana"),
            Participant(id: "p2", name: "Luis")
        ]

        try repository.updateParticipants(participants, at: summary.folderURL)
        let reloaded = try repository.loadSession(at: summary.folderURL)

        XCTAssertEqual(reloaded.summary.metadata.participants, participants)
    }

    func testDirectoryCreateRenameAndNestingRejection() throws {
        XCTAssertEqual(try repository.createDirectory(named: "Proyectos"), "Proyectos")
        XCTAssertThrowsError(try repository.createDirectory(named: "Proyectos")) { error in
            XCTAssertEqual(error as? LibraryError, .directoryAlreadyExists("Proyectos"))
        }
        XCTAssertThrowsError(try repository.createDirectory(named: "Proyectos/Interno")) { error in
            XCTAssertEqual(error as? LibraryError, .invalidDirectoryName("Proyectos/Interno"))
        }

        XCTAssertEqual(try repository.renameDirectory(named: "Proyectos", to: "Clientes"), "Clientes")
        XCTAssertEqual(try repository.directories(), ["Clientes"])
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: repository.directoriesDirectory.appendingPathComponent("Clientes").path
        ))
    }

    func testMoveSessionKeepsIdentityAndContents() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        try repository.writeNotes("notas que deben sobrevivir", at: summary.folderURL)
        try repository.createDirectory(named: "Clientes")

        let moved = try repository.moveSession(at: summary.folderURL, to: .directory("Clientes"))

        XCTAssertEqual(moved.location, .directory("Clientes"))
        XCTAssertEqual(moved.metadata.id, summary.metadata.id)
        XCTAssertTrue(moved.folderURL.path.contains("/Directorios/Clientes/"))
        let loaded = try repository.loadSession(at: moved.folderURL)
        XCTAssertEqual(loaded.notes, "notas que deben sobrevivir")
        XCTAssertTrue(try repository.sessions(in: .inbox).isEmpty)
        XCTAssertEqual(try repository.sessions(in: .directory("Clientes")).count, 1)
    }

    func testMoveOntoExistingFolderIsRejected() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        try repository.createDirectory(named: "Clientes")
        _ = try repository.moveSession(at: summary.folderURL, to: .directory("Clientes"))

        XCTAssertThrowsError(
            try repository.moveSession(at: repository.baseURL(for: .directory("Clientes"))
                .appendingPathComponent(summary.folderURL.lastPathComponent), to: .directory("Clientes"))
        ) { error in
            guard case LibraryError.collision = error else {
                return XCTFail("Se esperaba collision, llegó \(error)")
            }
        }
    }

    func testDeleteSessionRemovesEverything() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        try repository.writeNotes("contenido", at: summary.folderURL)

        try repository.deleteSession(at: summary.folderURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: summary.folderURL.path))
        XCTAssertTrue(try repository.sessions(in: .inbox).isEmpty)
    }

    func testDeletingDirectoryRemovesContainedSessions() throws {
        try repository.createDirectory(named: "Clientes")
        let summary = try repository.createSession(in: .directory("Clientes"), startDate: startDate)

        try repository.deleteDirectory(named: "Clientes")

        XCTAssertFalse(FileManager.default.fileExists(atPath: summary.folderURL.path))
        XCTAssertTrue(try repository.directories().isEmpty)
    }

    func testExistingFolderWithSameIdentityRetriesAnotherID() throws {
        let id = SessionID(rawValue: "ABC123")
        let occupied = SessionRepository.folderURL(
            base: repository.inboxDirectory,
            startDate: startDate,
            id: id
        )
        try FileManager.default.createDirectory(at: occupied, withIntermediateDirectories: true)

        let summary = try repository.createSession(in: .inbox, startDate: startDate, id: id)

        XCTAssertNotEqual(summary.metadata.id, "ABC123")
        XCTAssertNotEqual(summary.folderURL, occupied)
        XCTAssertEqual(try repository.sessions(in: .inbox).count, 1)
    }

    func testUnwritableInboxReportsErrorWithoutCreatingSession() throws {
        try FileManager.default.createDirectory(at: repository.inboxDirectory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o500],
            ofItemAtPath: repository.inboxDirectory.path
        )
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o700],
                ofItemAtPath: repository.inboxDirectory.path
            )
        }

        XCTAssertThrowsError(try repository.createSession(in: .inbox, startDate: startDate)) { error in
            guard case LibraryError.io = error else {
                return XCTFail("Se esperaba io, llegó \(error)")
            }
        }
    }

    func testPathsOutsideRootAreRejected() throws {
        let outside = FileManager.default.temporaryDirectory
        XCTAssertThrowsError(try repository.loadSession(at: outside)) { error in
            guard case LibraryError.notUnderRoot = error else {
                return XCTFail("Se esperaba notUnderRoot, llegó \(error)")
            }
        }
    }

    func testCorruptedMetadataIsReported() throws {
        let summary = try repository.createSession(in: .inbox, startDate: startDate)
        try Data("no es json".utf8).write(to: summary.folderURL.appendingPathComponent("sesion.json"))

        XCTAssertThrowsError(try repository.loadSession(at: summary.folderURL)) { error in
            guard case LibraryError.invalidMetadata = error else {
                return XCTFail("Se esperaba invalidMetadata, llegó \(error)")
            }
        }
    }
}
