import XCTest
@testable import ActaVozCore

final class ScreenPermissionRegressionTests: XCTestCase {
    func testSuccessfulScreenCaptureKitProbeOverridesStalePreflightDenial() {
        XCTAssertEqual(SystemAudioPermission.resolve(preflightGranted: false, probe: .accessible), .granted)
    }
    func testUnprobedPreflightFailureIsNotAConfirmedDenial() {
        XCTAssertEqual(SystemAudioPermission.resolve(preflightGranted: false, probe: .notChecked), .undetermined)
    }
    func testProbeFailureDoesNotInventAuthorization() {
        XCTAssertEqual(SystemAudioPermission.resolve(preflightGranted: true, probe: .denied), .denied)
    }
}
