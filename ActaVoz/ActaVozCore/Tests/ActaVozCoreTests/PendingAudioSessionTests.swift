import XCTest
@testable import ActaVozCore

@MainActor
private final class PendingFinalizer: AudioFinalizing {
    var fails = false
    func combine(_ sources: [URL], to destination: URL) async throws {
        if fails { throw CaptureError.driverFailed("Exportación fallida") }
        for source in sources { _ = try Data(contentsOf: source) }
        try Data("combinado".utf8).write(to: destination)
    }
}

@MainActor
final class PendingAudioSessionTests: XCTestCase {
    func testReopenRetryAndKeepPreservesNotes() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SessionRepository(root: root)
        let session = try repository.createSession(in: .inbox)
        let folder = session.folderURL
        try repository.writeNotes("Texto intacto", at: folder)
        let audio = folder.appendingPathComponent("AudioFuentes")
        try FileManager.default.createDirectory(at: audio, withIntermediateDirectories: true)
        let caf = audio.appendingPathComponent("sistema.caf")
        try Data("audio".utf8).write(to: caf)
        try Data(#"{"files":["AudioFuentes/sistema.caf"]}"#.utf8).write(to: folder.appendingPathComponent("audio-pendiente.json"))
        let finalizer = PendingFinalizer()
        let model = SessionModel(repository: repository, folderURL: folder, finalizer: finalizer)
        model.load()
        XCTAssertEqual(model.pendingAudio.count, 1)
        finalizer.fails = true
        await model.keepPendingAudio()
        XCTAssertFalse(model.pendingAudio.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: caf.path))
        finalizer.fails = false
        await model.keepPendingAudio()
        XCTAssertTrue(model.pendingAudio.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
        XCTAssertEqual(try repository.loadSession(at: folder).notes, "Texto intacto")
    }
}
