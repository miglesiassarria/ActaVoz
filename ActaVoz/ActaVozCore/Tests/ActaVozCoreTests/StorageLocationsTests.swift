import XCTest
@testable import ActaVozCore

final class StorageLocationsTests: XCTestCase {
    func testProductionLayoutUsesHiddenFolderInHomeAndLibraryLocations() {
        let locations = StorageLocations.production()
        let home = FileManager.default.homeDirectoryForCurrentUser

        XCTAssertEqual(locations.root, home.appendingPathComponent(".ActaVoz", isDirectory: true))
        XCTAssertEqual(locations.notesDirectory.lastPathComponent, "Notas")
        XCTAssertEqual(locations.userDirectoriesDirectory.lastPathComponent, "Directorios")
        XCTAssertTrue(locations.notesDirectory.path.hasPrefix(locations.root.path))
        XCTAssertTrue(locations.userDirectoriesDirectory.path.hasPrefix(locations.root.path))

        XCTAssertTrue(locations.configurationDirectory.path.contains("Application Support/ActaVoz"))
        XCTAssertTrue(locations.cachesDirectory.path.contains("Library/Caches/ActaVoz"))
        XCTAssertEqual(locations.settingsFile.lastPathComponent, "config.json")
        XCTAssertTrue(locations.settingsFile.path.hasPrefix(locations.configurationDirectory.path))
    }

    func testTestingLayoutStaysInsideInjectedRoot() {
        let root = URL(fileURLWithPath: "/tmp/actavoz-layout", isDirectory: true)
        let locations = StorageLocations.testing(root: root)

        XCTAssertEqual(locations.root, root)
        XCTAssertTrue(locations.settingsFile.path.hasPrefix(root.path))
        XCTAssertTrue(locations.cachesDirectory.path.hasPrefix(root.path))
        XCTAssertTrue(locations.notesDirectory.path.hasPrefix(root.path))
    }
}
