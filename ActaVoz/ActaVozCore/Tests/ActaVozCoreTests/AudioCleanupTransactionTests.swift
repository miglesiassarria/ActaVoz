import XCTest
@testable import ActaVozCore

final class AudioCleanupTransactionTests: XCTestCase {
    func testPartialCleanupRetriesWithoutTouchingExportedResult() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("a.caf"), b = root.appendingPathComponent("b.caf")
        let result = root.appendingPathComponent("audio.m4a")
        for url in [a,b,result] { try Data("original".utf8).write(to: url) }
        let journal = AudioCleanupTransaction(folder: root)
        try journal.begin([a,b])
        XCTAssertThrowsError(try journal.complete { url in
            if url.lastPathComponent == "b.caf" { throw CaptureError.driverFailed("Disco ocupado") }
            try FileManager.default.removeItem(at: url)
        })
        XCTAssertFalse(FileManager.default.fileExists(atPath: a.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: journal.journalURL.path))
        try journal.complete()
        XCTAssertTrue(FileManager.default.fileExists(atPath: journal.journalURL.path))
        try journal.finish()
        XCTAssertFalse(FileManager.default.fileExists(atPath: b.path))
        XCTAssertEqual(try Data(contentsOf: result), Data("original".utf8))
        XCTAssertFalse(FileManager.default.fileExists(atPath: journal.journalURL.path))
    }
}
