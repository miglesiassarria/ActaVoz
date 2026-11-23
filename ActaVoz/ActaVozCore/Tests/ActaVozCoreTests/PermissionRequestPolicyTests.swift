import XCTest
@testable import ActaVozCore

final class PermissionRequestPolicyTests: XCTestCase {
    func testOpeningPanelAndReturningFromSettingsDoNotPrompt() {
        for state: PermissionState in [.granted, .denied, .undetermined, .unavailable] {
            XCTAssertFalse(PermissionRequestPolicy.shouldRequest(userInitiated: false, inFlight: false, state: state))
        }
    }
    func testGrantedAccessIsNotRequestedAgain() {
        XCTAssertFalse(PermissionRequestPolicy.shouldRequest(userInitiated: true, inFlight: false, state: .granted))
    }
    func testRepeatedClicksDoNotLaunchConcurrentRequests() {
        XCTAssertFalse(PermissionRequestPolicy.shouldRequest(userInitiated: true, inFlight: true, state: .undetermined))
    }
    func testExplicitStartCanCheckUnknownSystemAccessWithoutMicrophone() {
        XCTAssertTrue(PermissionRequestPolicy.canAttemptStart(options: RecordingOptions(microphoneEnabled: false), availability: CaptureAvailability(microphone: .denied, system: .undetermined)))
    }
    func testConfirmedDenialDoesNotEnableStart() {
        XCTAssertFalse(PermissionRequestPolicy.canAttemptStart(options: RecordingOptions(microphoneEnabled: false), availability: CaptureAvailability(microphone: .denied, system: .denied)))
    }
    func testExplicitCheckCanResolveUnknownAccess() {
        XCTAssertTrue(PermissionRequestPolicy.shouldRequest(userInitiated: true, inFlight: false, state: .undetermined))
    }
}
