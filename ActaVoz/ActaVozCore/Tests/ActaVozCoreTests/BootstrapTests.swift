import XCTest
@testable import ActaVozCore

final class BootstrapTests: XCTestCase {
    private var temporaryRoots: [URL] = []

    override func tearDownWithError() throws {
        for root in temporaryRoots {
            try? FileManager.default.removeItem(at: root)
        }
        temporaryRoots = []
    }

    private func makeLocations() throws -> StorageLocations {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-bootstrap-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        temporaryRoots.append(root)
        return StorageLocations.testing(root: root)
    }

    func testPrepareCreatesStructureAndReturnsDefaultConfiguration() throws {
        let locations = try makeLocations()

        let configuration = try Bootstrap(locations: locations).prepare()

        XCTAssertEqual(configuration, .current)
        XCTAssertTrue(FileManager.default.fileExists(atPath: locations.notesDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: locations.userDirectoriesDirectory.path))
    }

    func testConfigurationSurvivesARelaunch() throws {
        let locations = try makeLocations()
        var configuration = try Bootstrap(locations: locations).prepare()
        configuration.hasCompletedFirstRun = true
        try SettingsStore(fileURL: locations.settingsFile).save(configuration)

        // Un arranque nuevo simula reabrir la aplicación.
        let reloaded = try Bootstrap(locations: locations).prepare()

        XCTAssertTrue(reloaded.hasCompletedFirstRun)
    }

    func testPrepareFailsWhenRootIsAFile() throws {
        let locations = try makeLocations()
        let fileAsRoot = locations.root.appendingPathComponent("ActaVoz")
        try Data("centinela".utf8).write(to: fileAsRoot)

        var blocked = locations
        blocked.root = fileAsRoot

        XCTAssertThrowsError(try Bootstrap(locations: blocked).prepare())
        XCTAssertEqual(try String(contentsOf: fileAsRoot, encoding: .utf8), "centinela")
    }
}
