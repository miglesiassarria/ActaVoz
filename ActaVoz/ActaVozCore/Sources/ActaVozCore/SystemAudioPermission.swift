import Foundation

public enum SystemAudioPermission {
    public enum Probe: Sendable { case notChecked, accessible, denied, unavailable }
    public static func resolve(preflightGranted: Bool, probe: Probe) -> PermissionState {
        switch probe {
        case .accessible: return .granted
        case .denied: return .denied
        case .unavailable: return .unavailable
        case .notChecked: return preflightGranted ? .granted : .undetermined
        }
    }
}
