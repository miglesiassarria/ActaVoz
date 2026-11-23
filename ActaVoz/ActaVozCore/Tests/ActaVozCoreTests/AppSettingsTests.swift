import XCTest
@testable import ActaVozCore

final class AppSettingsTests: XCTestCase {
    private var temporaryRoots: [URL] = []

    override func tearDownWithError() throws {
        for root in temporaryRoots {
            try? FileManager.default.removeItem(at: root)
        }
        temporaryRoots = []
    }

    private func makeLocations() throws -> StorageLocations {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-settings-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        temporaryRoots.append(root)
        return StorageLocations.testing(root: root)
    }

    func testLoadReturnsDefaultsWhenFileDoesNotExist() throws {
        let locations = try makeLocations()
        let store = SettingsStore(fileURL: locations.settingsFile)

        XCTAssertEqual(try store.load(), .current)
        XCTAssertEqual(try store.load().schemaVersion, 1)
        XCTAssertFalse(try store.load().hasCompletedFirstRun)
    }

    func testSaveAndLoadRoundTrip() throws {
        let locations = try makeLocations()
        let store = SettingsStore(fileURL: locations.settingsFile)
        let configuration = AppConfiguration(schemaVersion: 1, hasCompletedFirstRun: true)

        try store.save(configuration)

        XCTAssertTrue(FileManager.default.fileExists(atPath: locations.settingsFile.path))
        XCTAssertEqual(try store.load(), configuration)
    }

    func testCorruptedFileIsReportedInsteadOfSilentlyResetting() throws {
        let locations = try makeLocations()
        try FileManager.default.createDirectory(at: locations.configurationDirectory, withIntermediateDirectories: true)
        try Data("no es json".utf8).write(to: locations.settingsFile)

        XCTAssertThrowsError(try SettingsStore(fileURL: locations.settingsFile).load()) { error in
            guard case SettingsError.invalidContents = error else {
                return XCTFail("Se esperaba invalidContents, llegó \(error)")
            }
        }
    }

    func testSaveCreatesConfigurationDirectory() throws {
        let locations = try makeLocations()
        XCTAssertFalse(FileManager.default.fileExists(atPath: locations.configurationDirectory.path))

        try SettingsStore(fileURL: locations.settingsFile).save(.current)

        XCTAssertTrue(FileManager.default.fileExists(atPath: locations.configurationDirectory.path))
    }
}
