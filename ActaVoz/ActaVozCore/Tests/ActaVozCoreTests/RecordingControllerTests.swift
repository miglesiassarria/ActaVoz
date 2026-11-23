import XCTest
@testable import ActaVozCore

private final class FakeDriver: CaptureDriver {
    var onEvent: ((CaptureEvent) -> Void)?
    var availabilityValue = CaptureAvailability(
        microphone: .granted,
        system: .granted,
        devices: [AudioDevice(id: "mic-1", name: "Micrófono interno")]
    )
    var startError: Error?
    private(set) var startedPlan: CapturePlan?
    private(set) var paused = false
    private(set) var stopped = false
    var files: [CaptureSource: URL] = [:]

    func availability() -> CaptureAvailability { availabilityValue }

    func start(_ plan: CapturePlan, folder: URL) throws {
        if let startError { throw startError }
        startedPlan = plan
        for source in plan.sources {
            let url = folder.appendingPathComponent("fuente-\(source.rawValue).caf")
            try Data("audio".utf8).write(to: url)
            files[source] = url
        }
    }

    func pause() { paused = true }
    func resume() { paused = false }
    func stop() throws -> [CaptureSource: URL] {
        stopped = true
        return files
    }

    func emit(_ event: CaptureEvent) {
        onEvent?(event)
    }
}

private final class FakeFinalizer: AudioFinalizing {
    private(set) var calls: [[URL]] = []
    var error: Error?
    var destinationExists = false

    func combine(_ sources: [URL], to destination: URL) throws {
        if let error { throw error }
        calls.append(sources)
        try Data("audio".utf8).write(to: destination)
        destinationExists = true
    }
}

private final class TestClock {
    var now = Date(timeIntervalSince1970: 1_700_000_000)
    func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}

@MainActor
final class RecordingControllerTests: XCTestCase {
    private var folder: URL!
    private var driver: FakeDriver!
    private var finalizer: FakeFinalizer!
    private var clock: TestClock!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-rec-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        driver = FakeDriver()
        finalizer = FakeFinalizer()
        clock = TestClock()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    private func makeController(
        options: RecordingOptions = RecordingOptions(),
        policy: AudioRetentionPolicy = .alwaysKeep
    ) -> RecordingController {
        RecordingController(
            folder: folder,
            options: options,
            driver: driver,
            finalizer: finalizer,
            retentionPolicy: policy,
            now: { [clock] in clock!.now }
        )
    }

    func testStartRecordsBothSourcesAndWritesMarker() throws {
        let controller = makeController()

        try controller.start()

        XCTAssertEqual(controller.status, .recording)
        XCTAssertEqual(controller.activeSources, [.microphone, .system])
        XCTAssertEqual(driver.startedPlan?.sources, [.microphone, .system])
        let marker = PendingRecordingStore(folder: folder).load()
        XCTAssertEqual(marker?.sources.count, 2)
        XCTAssertEqual(marker?.paused, false)
    }

    func testDeniedMicrophoneWarnsAndRecordsOnlySystem() throws {
        driver.availabilityValue.microphone = .denied
        let controller = makeController()

        try controller.start()

        XCTAssertEqual(controller.activeSources, [.system])
        XCTAssertEqual(controller.missingSources, [.microphone])
        XCTAssertNotNil(controller.warning)
        XCTAssertEqual(controller.status, .recording)
    }

    func testNoAvailableSourceFailsWithoutStartingDriver() {
        driver.availabilityValue = CaptureAvailability(microphone: .denied, system: .denied)
        let controller = makeController()

        XCTAssertFalse(controller.canStart)
        XCTAssertThrowsError(try controller.start()) { error in
            XCTAssertEqual(error as? CaptureError, .noSourceAvailable)
        }
        XCTAssertNil(driver.startedPlan)
        if case .failed = controller.status {} else {
            XCTFail("Se esperaba estado failed, llegó \(controller.status)")
        }
    }

    func testPauseFreezesElapsedAndResumeContinuesWithoutCountingPause() throws {
        let controller = makeController()
        try controller.start()

        clock.advance(10)
        controller.tick()
        XCTAssertEqual(controller.elapsed, 10, accuracy: 0.001)

        controller.togglePause()
        XCTAssertEqual(controller.status, .paused(.user))
        XCTAssertTrue(driver.paused)

        clock.advance(30)
        controller.tick()
        XCTAssertEqual(controller.elapsed, 10, accuracy: 0.001)

        controller.togglePause()
        XCTAssertEqual(controller.status, .recording)
        XCTAssertFalse(driver.paused)

        clock.advance(5)
        controller.tick()
        XCTAssertEqual(controller.elapsed, 15, accuracy: 0.001)
    }

    func testLosingAllSourcesPausesAndRecoveryResumes() throws {
        let controller = makeController()
        try controller.start()

        driver.emit(.sourceLost(.microphone))
        XCTAssertEqual(controller.activeSources, [.system])
        XCTAssertEqual(controller.status, .recording)

        driver.emit(.sourceLost(.system))
        XCTAssertEqual(controller.status, .paused(.sourcesLost))
        XCTAssertTrue(controller.activeSources.isEmpty)

        driver.emit(.sourceRecovered(.system))
        XCTAssertEqual(controller.status, .recording)
        XCTAssertEqual(controller.activeSources, [.system])
    }

    func testStopKeepsCombinedAudioAndClearsMarker() throws {
        let controller = makeController()
        try controller.start()
        clock.advance(8)

        let destination = try controller.stop()

        XCTAssertEqual(controller.status, .finished)
        XCTAssertNotNil(destination)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
        XCTAssertEqual(finalizer.calls.count, 1)
        XCTAssertNil(PendingRecordingStore(folder: folder).load())
        XCTAssertFalse(driver.files.values.contains { FileManager.default.fileExists(atPath: $0.path) })
        XCTAssertEqual(controller.elapsed, 8, accuracy: 0.001)
    }

    func testStopDeletesAudioWhenPolicySaysSo() throws {
        let controller = makeController(policy: .alwaysDelete)
        try controller.start()

        let destination = try controller.stop()

        XCTAssertNil(destination)
        XCTAssertEqual(controller.status, .finished)
        XCTAssertTrue(finalizer.calls.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
    }

    func testAskPolicyWaitsForDecisionAndKeepsOrDeletes() throws {
        let controller = makeController(policy: .askEachTime)
        try controller.start()

        let destination = try controller.stop()

        XCTAssertNil(destination)
        XCTAssertEqual(controller.status, .awaitingAudioDecision)
        XCTAssertTrue(controller.hasPendingAudioDecision)
        let pending = RecordingController.pendingAudioFiles(in: folder)
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })

        try controller.resolveAudioDecision(keep: true)
        XCTAssertEqual(controller.status, .finished)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio-pendiente.json").path))
    }

    func testAskPolicyCanDiscardPendingAudio() throws {
        let controller = makeController(policy: .askEachTime)
        try controller.start()
        _ = try controller.stop()

        try controller.resolveAudioDecision(keep: false)

        XCTAssertEqual(controller.status, .finished)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
    }

    func testPausedStateIsPersistedForRecovery() throws {
        let controller = makeController()
        try controller.start()
        clock.advance(12)
        controller.togglePause()

        let marker = PendingRecordingStore(folder: folder).load()

        XCTAssertEqual(marker?.paused, true)
        XCTAssertEqual(marker?.elapsed ?? 0, 12, accuracy: 0.001)
        XCTAssertEqual(Set(marker?.sources ?? []), [.microphone, .system])
    }

    func testDriverFailureLeavesFailedStatus() {
        driver.startError = NSError(domain: "prueba", code: 1)
        let controller = makeController()

        XCTAssertThrowsError(try controller.start())

        if case .failed = controller.status {} else {
            XCTFail("Se esperaba failed, llegó \(controller.status)")
        }
    }
}
