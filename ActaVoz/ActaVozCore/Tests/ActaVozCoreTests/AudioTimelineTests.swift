import XCTest
@testable import ActaVozCore

final class AudioTimelineTests: XCTestCase {
    func testSharedHostClockRetainsSourceOffsetAndRemovesPause() {
        var clock = AudioTimelineClock(hostStart: 100, sessionStart: 12)
        clock.pause(at: 103)
        clock.resume(at: 108)
        XCTAssertEqual(clock.slices(hostStart: 101, duration: 1).first?.sessionStart, 13)
        XCTAssertEqual(clock.slices(hostStart: 102, duration: 7), [
            .init(bufferOffset: 0, sessionStart: 14, duration: 1),
            .init(bufferOffset: 6, sessionStart: 15, duration: 1)
        ])
        XCTAssertTrue(clock.slices(hostStart: 104, duration: 2).isEmpty)
        // A late callback still uses its capture timestamp, not delivery time.
        XCTAssertEqual(clock.slices(hostStart: 101.5, duration: 0.5).first?.sessionStart, 13.5)
    }

    func testSeparateSourcesMixButSuccessiveRecoverySegmentsDoNotRestartAtZero() throws {
        let segment = UUID(), next = UUID()
        func input(_ name: String, _ source: CaptureSource, _ id: UUID, _ start: Double, _ duration: Double) -> AudioTimelinePlanner.Input {
            .init(url: URL(fileURLWithPath: "/tmp/\(name).caf"), duration: duration,
                  metadata: .init(source: source, segmentID: id, spans: [.init(fileStart: 0, sessionStart: start, duration: duration)]))
        }
        let result = try AudioTimelinePlanner.plan([
            input("mic-first", .microphone, segment, 0, 3),
            input("system-first", .system, segment, 0.25, 2.75),
            input("mic-next", .microphone, next, 3, 2),
            input("system-next", .system, next, 3.5, 1.5)
        ])
        XCTAssertEqual(result.map(\.sessionStart), [0, 0.25, 3, 3.5])
        XCTAssertEqual(result.map(\.duration), [3, 2.75, 2, 1.5])
        XCTAssertNotEqual(result[0].url, result[1].url)
    }

    func testLegacyFallbackMixesWithinSegmentAndConcatenatesSegments() throws {
        let first = AudioTimelinePlanner.Input(url: URL(fileURLWithPath: "/tmp/microfono-a.caf"), duration: 3, metadata: nil)
        let other = AudioTimelinePlanner.Input(url: URL(fileURLWithPath: "/tmp/sistema-a.caf"), duration: 4, metadata: nil)
        let later = AudioTimelinePlanner.Input(url: URL(fileURLWithPath: "/tmp/sistema-b.caf"), duration: 2, metadata: nil)
        XCTAssertEqual(try AudioTimelinePlanner.plan([first, other]).map(\.sessionStart), [0, 0])
        XCTAssertThrowsError(try AudioTimelinePlanner.plan([first, other, later]))
    }

    func testInputOrderDoesNotDefineChronology() throws {
        let a = UUID(uuidString: "FFFFFFFF-0000-0000-0000-000000000000")!
        let b = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let second = AudioTimelinePlanner.Input(url: URL(fileURLWithPath: "/tmp/sistema-(a.uuidString).caf"), duration: 2,
            metadata: .init(source: .system, segmentID: a, spans: [.init(fileStart: 0, sessionStart: 5, duration: 2)]))
        let first = AudioTimelinePlanner.Input(url: URL(fileURLWithPath: "/tmp/sistema-(b.uuidString).caf"), duration: 3,
            metadata: .init(source: .system, segmentID: b, spans: [.init(fileStart: 0, sessionStart: 0, duration: 3)]))
        XCTAssertEqual(try AudioTimelinePlanner.plan([second, first]).map(\.sessionStart), [0, 5])
        XCTAssertThrowsError(try AudioTimelinePlanner.plan([second, .init(url: URL(fileURLWithPath: "/tmp/sistema-(b.uuidString).caf"), duration: 6, metadata: .init(source: .system, segmentID: b, spans: [.init(fileStart: 0, sessionStart: 2, duration: 6)]))]))
    }

    func testInterruptedCheckpointKeepsCafTail() throws {
        let url = URL(fileURLWithPath: "/tmp/sistema-00000000-0000-0000-0000-000000000002.caf")
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let metadata = AudioTimelineFragment(source: .system, segmentID: id, spans: [.init(fileStart: 0, sessionStart: 2, duration: 0.9)])
        let plan = try AudioTimelinePlanner.plan([.init(url: url, duration: 1, metadata: metadata)])
        XCTAssertEqual(plan.first?.duration ?? 0, 1, accuracy: 0.0001)
    }

    func testRejectsGapsAndMismatchedMetadata() throws {
        let url = URL(fileURLWithPath: "/tmp/sistema-00000000-0000-0000-0000-000000000001.caf")
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let gap = AudioTimelineFragment(source: .system, segmentID: id, spans: [.init(fileStart: 0.2, sessionStart: 0, duration: 0.8)])
        XCTAssertThrowsError(try AudioTimelinePlanner.plan([.init(url: url, duration: 1, metadata: gap)]))
        let wrong = AudioTimelineFragment(source: .microphone, segmentID: id, spans: [.init(fileStart: 0, sessionStart: 0, duration: 1)])
        XCTAssertThrowsError(try AudioTimelinePlanner.plan([.init(url: url, duration: 1, metadata: wrong)]))
    }

    func testSidecarRoundTripAndInvalidMetadataDoNotDeleteAudio() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let audio = folder.appendingPathComponent("microfono.caf")
        let original = Data("original CAF placeholder".utf8)
        try original.write(to: audio)
        XCTAssertNil(try AudioTimelineFragment.load(for: audio))
        let metadata = AudioTimelineFragment(source: .microphone, segmentID: UUID(), spans: [
            .init(fileStart: 0, sessionStart: 4, duration: 2)
        ])
        try metadata.save(for: audio)
        XCTAssertEqual(try AudioTimelineFragment.load(for: audio), metadata)
        try Data("broken".utf8).write(to: AudioTimelineFragment.sidecarURL(for: audio))
        XCTAssertThrowsError(try AudioTimelineFragment.load(for: audio))
        XCTAssertEqual(try Data(contentsOf: audio), original)
    }

    func testRejectsOutOfBoundsAndMixedUnknownChronology() throws {
        let audio = URL(fileURLWithPath: "/tmp/test.caf")
        let metadata = AudioTimelineFragment(source: .system, segmentID: UUID(), spans: [.init(fileStart: 0, sessionStart: 0, duration: 3)])
        XCTAssertThrowsError(try AudioTimelinePlanner.plan([.init(url: audio, duration: 2, metadata: metadata)]))
        XCTAssertThrowsError(try AudioTimelinePlanner.plan([
            .init(url: audio, duration: 3, metadata: metadata),
            .init(url: URL(fileURLWithPath: "/tmp/legacy.caf"), duration: 1, metadata: nil)
        ]))
    }
}
