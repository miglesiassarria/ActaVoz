import XCTest
@testable import ActaVozCore

final class DirectoryPreparationTests: XCTestCase {
    private var temporaryRoots: [URL] = []

    override func tearDownWithError() throws {
        let fileManager = FileManager.default
        for root in temporaryRoots {
            try? fileManager.removeItem(at: root)
        }
        temporaryRoots = []
    }

    private func makeTemporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        temporaryRoots.append(root)
        return root
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func testPrepareCreatesSessionsConfigurationAndCaches() throws {
        let root = try makeTemporaryRoot()
        let locations = StorageLocations.testing(root: root)

        try DirectoryPreparer().prepare(locations)

        XCTAssertTrue(isDirectory(locations.root))
        XCTAssertTrue(isDirectory(locations.notesDirectory))
        XCTAssertTrue(isDirectory(locations.userDirectoriesDirectory))
        XCTAssertTrue(isDirectory(locations.configurationDirectory))
        XCTAssertTrue(isDirectory(locations.cachesDirectory))
    }

    func testPrepareIsIdempotentAndKeepsExistingContent() throws {
        let root = try makeTemporaryRoot()
        let locations = StorageLocations.testing(root: root)
        let preparer = DirectoryPreparer()

        try preparer.prepare(locations)

        let sentinel = locations.notesDirectory.appendingPathComponent("centinela.txt")
        try Data("no borrar".utf8).write(to: sentinel)

        try preparer.prepare(locations)
        try preparer.prepare(locations)

        XCTAssertEqual(try String(contentsOf: sentinel, encoding: .utf8), "no borrar")
        XCTAssertTrue(isDirectory(locations.notesDirectory))
    }

    func testRootThatIsAFileIsRejectedWithoutDeletingIt() throws {
        let base = try makeTemporaryRoot()
        let fileAsRoot = base.appendingPathComponent("ActaVoz")
        try Data("centinela".utf8).write(to: fileAsRoot)

        XCTAssertThrowsError(
            try DirectoryPreparer().prepare(StorageLocations.testing(root: fileAsRoot))
        ) { error in
            guard case StorageError.pathIsNotDirectory(let url) = error else {
                return XCTFail("Se esperaba pathIsNotDirectory, llegó \(error)")
            }
            XCTAssertEqual(url, fileAsRoot)
        }

        XCTAssertEqual(try String(contentsOf: fileAsRoot, encoding: .utf8), "centinela")
    }

    func testUnwritableParentIsReportedAsCannotCreateDirectory() throws {
        let base = try makeTemporaryRoot()
        let blocker = base.appendingPathComponent("bloqueo")
        try Data("archivo, no carpeta".utf8).write(to: blocker)

        let locations = StorageLocations.testing(root: blocker.appendingPathComponent("ActaVoz", isDirectory: true))

        XCTAssertThrowsError(try DirectoryPreparer().prepare(locations)) { error in
            guard case StorageError.cannotCreateDirectory = error else {
                return XCTFail("Se esperaba cannotCreateDirectory, llegó \(error)")
            }
        }
    }
}
