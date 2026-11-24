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
    /// Permite simular que el arranque real confirma una fuente antes ambigua.
    var availabilityAfterStart: CaptureAvailability?
    private(set) var startedPlan: CapturePlan?
    private(set) var paused = false
    private(set) var stopped = false
    var files: [CaptureSource: URL] = [:]

    func availability() -> CaptureAvailability { availabilityValue }

    func start(_ plan: CapturePlan, folder: URL) async throws {
        if let startError { throw startError }
        startedPlan = plan
        if let availabilityAfterStart { availabilityValue = availabilityAfterStart }
        for source in plan.sources {
            let url = folder.appendingPathComponent("fuente-\(source.rawValue).caf")
            try Data("audio".utf8).write(to: url)
            files[source] = url
        }
    }

    func pause() { paused = true }
    func resume() { paused = false }
    func stop() async throws -> [CaptureSource: URL] {
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

    func combine(_ sources: [URL], to destination: URL) async throws {
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
        policy: AudioRetentionPolicy = .alwaysKeep,
        restoredElapsed: TimeInterval = 0
    ) -> RecordingController {
        RecordingController(
            folder: folder,
            options: options,
            driver: driver,
            finalizer: finalizer,
            retentionPolicy: policy,
            restoredElapsed: restoredElapsed,
            now: { [clock] in clock!.now }
        )
    }

    func testStartRecordsBothSourcesAndWritesMarker() async throws {
        let controller = makeController()

        try await controller.start()

        XCTAssertEqual(controller.status, .recording)
        XCTAssertEqual(controller.activeSources, [.microphone, .system])
        XCTAssertEqual(driver.startedPlan?.sources, [.microphone, .system])
        let marker = PendingRecordingStore(folder: folder).load()
        XCTAssertEqual(marker?.sources.count, 2)
        XCTAssertEqual(marker?.paused, false)
    }

    func testDeniedMicrophoneWarnsAndRecordsOnlySystem() async throws {
        driver.availabilityValue.microphone = .denied
        let controller = makeController()

        try await controller.start()

        XCTAssertEqual(controller.activeSources, [.system])
        XCTAssertEqual(controller.missingSources, [.microphone])
        XCTAssertNotNil(controller.warning)
        XCTAssertEqual(controller.status, .recording)
    }

    func testUnverifiedSystemSourceDoesNotWarnAfterSuccessfulStart() async throws {
        driver.availabilityValue = CaptureAvailability(microphone: .denied, system: .undetermined)
        driver.availabilityAfterStart = CaptureAvailability(microphone: .denied, system: .granted)
        var options = RecordingOptions()
        options.microphoneEnabled = false
        let controller = makeController(options: options)

        XCTAssertTrue(controller.canStart)
        try await controller.start()

        XCTAssertEqual(controller.activeSources, [.system])
        XCTAssertNil(controller.warning)
        XCTAssertTrue(controller.missingSources.isEmpty)
        XCTAssertEqual(controller.status, .recording)
    }

    func testNoAvailableSourceFailsWithoutStartingDriver() async throws {
        driver.availabilityValue = CaptureAvailability(microphone: .denied, system: .denied)
        let controller = makeController()

        XCTAssertFalse(controller.canStart)
        do { try await controller.start(); XCTFail("Debe rechazar inicio sin fuentes") }
        catch { XCTAssertEqual(error as? CaptureError, .noSourceAvailable) }
        XCTAssertNil(driver.startedPlan)
        if case .failed = controller.status {} else {
            XCTFail("Se esperaba estado failed, llegó \(controller.status)")
        }
    }

    func testPendingAudioRoundTripsNestedFragmentPaths() async throws {
        let controller = makeController(policy: .askEachTime)
        try await controller.start()
        let fragments = folder.appendingPathComponent("AudioFuentes")
        try FileManager.default.createDirectory(at: fragments, withIntermediateDirectories: true)
        let caf = fragments.appendingPathComponent("sistema-test.caf")
        try Data("audio".utf8).write(to: caf)
        _ = try await controller.stop()
        XCTAssertEqual(RecordingController.pendingAudioFiles(in: folder), [caf])
    }

    func testFinishedInterruptedRecordingCreatesPendingDecision() async throws {
        let controller = makeController(policy: .askEachTime)
        let audio = folder.appendingPathComponent("AudioFuentes")
        try FileManager.default.createDirectory(at: audio, withIntermediateDirectories: true)
        let caf = audio.appendingPathComponent("sistema.caf")
        try Data("audio".utf8).write(to: caf)
        try await controller.finishInterruptedRecording()
        XCTAssertEqual(controller.status, .awaitingAudioDecision)
        XCTAssertTrue(RecordingController.pendingAudioFiles(in: folder).contains { $0.lastPathComponent == caf.lastPathComponent })
        XCTAssertTrue(FileManager.default.fileExists(atPath: caf.path))
    }

    func testExportFailureKeepsRecoveryMarkerAndSources() async throws {
        let controller = makeController()
        try await controller.start()
        finalizer.error = CaptureError.driverFailed("Disco no disponible")
        do { _ = try await controller.stop(); XCTFail("Debe fallar") } catch {}
        XCTAssertNotNil(PendingRecordingStore(folder: folder).load())
        XCTAssertTrue(driver.files.values.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
    }

    func testPendingDecisionCanRetryExportWithoutLosingFiles() async throws {
        let controller = makeController(policy: .askEachTime)
        try await controller.start()
        _ = try await controller.stop()
        finalizer.error = CaptureError.driverFailed("Error temporal")
        do { try await controller.resolveAudioDecision(keep: true); XCTFail("Debe fallar") } catch {}
        XCTAssertEqual(controller.status, .awaitingAudioDecision)
        finalizer.error = nil
        try await controller.resolveAudioDecision(keep: true)
        XCTAssertEqual(controller.status, .finished)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
    }

    func testFinishInterruptedWithoutStartingCapture() async throws {
        let controller = makeController()
        let fragments = folder.appendingPathComponent("AudioFuentes")
        try FileManager.default.createDirectory(at: fragments, withIntermediateDirectories: true)
        let caf = fragments.appendingPathComponent("sistema-test.caf")
        try Data("audio".utf8).write(to: caf)
        try await controller.finishInterruptedRecording()
        XCTAssertNil(driver.startedPlan)
        XCTAssertEqual(controller.status, .finished)
        XCTAssertEqual(finalizer.calls.last?.map { $0.path.replacingOccurrences(of: "/private/var/", with: "/var/") }, [caf.path.replacingOccurrences(of: "/private/var/", with: "/var/")])
    }

    func testPendingMarkerRejectsSymlinkedDirectory() throws {
        let external = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: external, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: external) }
        let outside = external.appendingPathComponent("outside.caf")
        try Data("outside".utf8).write(to: outside)
        try FileManager.default.createSymbolicLink(at: folder.appendingPathComponent("AudioFuentes"), withDestinationURL: external)
        try Data(#"{"files":["AudioFuentes/outside.caf"]}"#.utf8).write(to: folder.appendingPathComponent("audio-pendiente.json"))
        XCTAssertTrue(RecordingController.pendingAudioFiles(in: folder).isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outside.path))
    }

    func testLegacyPendingMarkerResolvesAudioFuentes() throws {
        let audio = folder.appendingPathComponent("AudioFuentes")
        try FileManager.default.createDirectory(at: audio, withIntermediateDirectories: true)
        let caf = audio.appendingPathComponent("legacy.caf")
        try Data("audio".utf8).write(to: caf)
        try Data(#"{"files":["legacy.caf"]}"#.utf8).write(to: folder.appendingPathComponent("audio-pendiente.json"))
        XCTAssertEqual(RecordingController.pendingAudioFiles(in: folder).first?.lastPathComponent, "legacy.caf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: RecordingController.pendingAudioFiles(in: folder)[0].path))
    }

    func testPendingMarkerCannotEscapeSession() throws {
        let marker = folder.appendingPathComponent("audio-pendiente.json")
        try Data(#"{"files":["../outside.caf","/tmp/outside.caf","AudioFuentes/valid.caf"]}"#.utf8).write(to: marker)
        let files = RecordingController.pendingAudioFiles(in: folder)
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first?.lastPathComponent, "valid.caf")
    }

    func testRecoveredRecordingKeepsElapsedTime() async throws {
        let controller = makeController(restoredElapsed: 12)

        try await controller.start()
        clock.advance(3)
        controller.tick()

        XCTAssertEqual(controller.elapsed, 15, accuracy: 0.001)
    }

    func testPauseFreezesElapsedAndResumeContinuesWithoutCountingPause() async throws {
        let controller = makeController()
        try await controller.start()

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

    func testLosingAllSourcesPausesAndRecoveryResumes() async throws {
        let controller = makeController()
        try await controller.start()

        driver.emit(.sourceLost(.microphone))
        XCTAssertEqual(controller.activeSources, [.system])
        XCTAssertEqual(controller.status, .recording)

        driver.emit(.sourceLost(.system))
        XCTAssertEqual(controller.status, .paused(.sourcesLost))
        // La pausa por pérdida no debe bloquear el escritor: el driver necesita
        // confirmar el primer búfer y reanudar al recuperar la fuente.
        XCTAssertFalse(driver.paused)
        XCTAssertTrue(controller.activeSources.isEmpty)

        driver.emit(.sourceRecovered(.system))
        XCTAssertEqual(controller.status, .recording)
        XCTAssertEqual(controller.activeSources, [.system])
    }

    func testStopKeepsCombinedAudioAndClearsMarker() async throws {
        let controller = makeController()
        try await controller.start()
        clock.advance(8)

        let destination = try await controller.stop()

        XCTAssertEqual(controller.status, .finished)
        XCTAssertNotNil(destination)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
        XCTAssertEqual(finalizer.calls.count, 1)
        XCTAssertNil(PendingRecordingStore(folder: folder).load())
        XCTAssertFalse(driver.files.values.contains { FileManager.default.fileExists(atPath: $0.path) })
        XCTAssertEqual(controller.elapsed, 8, accuracy: 0.001)
    }

    func testStopDeletesAudioWhenPolicySaysSo() async throws {
        let controller = makeController(policy: .alwaysDelete)
        try await controller.start()

        let destination = try await controller.stop()

        XCTAssertNil(destination)
        XCTAssertEqual(controller.status, .finished)
        XCTAssertTrue(finalizer.calls.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
    }

    func testAskPolicyWaitsForDecisionAndKeepsOrDeletes() async throws {
        let controller = makeController(policy: .askEachTime)
        try await controller.start()

        let destination = try await controller.stop()

        XCTAssertNil(destination)
        XCTAssertEqual(controller.status, .awaitingAudioDecision)
        XCTAssertTrue(controller.hasPendingAudioDecision)
        let pending = RecordingController.pendingAudioFiles(in: folder)
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })

        try await controller.resolveAudioDecision(keep: true)
        XCTAssertEqual(controller.status, .finished)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio-pendiente.json").path))
    }

    func testAskPolicyCanDiscardPendingAudio() async throws {
        let controller = makeController(policy: .askEachTime)
        try await controller.start()
        _ = try await controller.stop()

        try await controller.resolveAudioDecision(keep: false)

        XCTAssertEqual(controller.status, .finished)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
    }

    func testPausedStateIsPersistedForRecovery() async throws {
        let controller = makeController()
        try await controller.start()
        clock.advance(12)
        controller.togglePause()

        let marker = PendingRecordingStore(folder: folder).load()

        XCTAssertEqual(marker?.paused, true)
        XCTAssertEqual(marker?.elapsed ?? 0, 12, accuracy: 0.001)
        XCTAssertEqual(Set(marker?.sources ?? []), [.microphone, .system])
    }

    func testDriverFailureLeavesFailedStatus() async throws {
        driver.startError = NSError(domain: "prueba", code: 1)
        let controller = makeController()

        do { try await controller.start(); XCTFail("Debe propagar el fallo") } catch {}

        if case .failed = controller.status {} else {
            XCTFail("Se esperaba failed, llegó \(controller.status)")
        }
    }
}
