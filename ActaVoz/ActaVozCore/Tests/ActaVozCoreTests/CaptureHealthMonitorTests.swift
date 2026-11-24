import XCTest
@testable import ActaVozCore

final class CaptureHealthMonitorTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000)

    func testSilenceWithBuffersIsHealthy() {
        var monitor = CaptureHealthMonitor(timeout: 4, retryDelay: 5, now: start)
        monitor.beginSegment(at: start)
        let last = [CaptureSource.system: start.addingTimeInterval(3.5)]
        XCTAssertTrue(monitor.stalled(sources: [.system], lastWrite: last,
                                       now: start.addingTimeInterval(4.5)).isEmpty)
    }

    func testSourceWithoutBuffersTimesOut() {
        var monitor = CaptureHealthMonitor(timeout: 4, retryDelay: 5, now: start)
        monitor.beginSegment(at: start)
        XCTAssertTrue(monitor.stalled(sources: [.system], lastWrite: [:],
                                       now: start.addingTimeInterval(4.1)).contains(.system))
        XCTAssertFalse(monitor.stalled(sources: [.system], lastWrite: [:],
                                        now: start.addingTimeInterval(3.9)).contains(.system))
    }

    func testEachSourceIsIndependent() {
        var monitor = CaptureHealthMonitor(timeout: 4, retryDelay: 5, now: start)
        monitor.beginSegment(at: start)
        let last = [CaptureSource.microphone: start.addingTimeInterval(4)]
        XCTAssertEqual(monitor.stalled(sources: [.microphone, .system], lastWrite: last,
                                       now: start.addingTimeInterval(4.5)), [.system])
    }

    func testRetriesOnlyWhenNoSourceIsHealthy() {
        var monitor = CaptureHealthMonitor(timeout: 4, retryDelay: 5, now: start)
        monitor.beginSegment(at: start)
        let later = start.addingTimeInterval(6)
        XCTAssertFalse(monitor.shouldRetry(sources: [.system], recovering: [.microphone], now: later))
        XCTAssertTrue(monitor.shouldRetry(sources: [], recovering: [.microphone], now: later))
        XCTAssertFalse(monitor.shouldRetry(sources: [], recovering: [.microphone],
                                            now: start.addingTimeInterval(4.9)))
        monitor.recordAttempt(at: later)
        XCTAssertFalse(monitor.shouldRetry(sources: [], recovering: [.microphone],
                                            now: later.addingTimeInterval(4.9)))
        XCTAssertTrue(monitor.shouldRetry(sources: [], recovering: [.microphone],
                                           now: later.addingTimeInterval(5)))
    }
}
