/// Abrir el panel o volver de Ajustes nunca debe solicitar permiso.
public enum PermissionRequestPolicy {
    public static func canAttemptStart(options: RecordingOptions, availability: CaptureAvailability) -> Bool {
        options.enabledSources.contains { source in
            let state = availability.permission(for: source)
            return state == .granted || (source == .system && state == .undetermined)
        }
    }
    public static func shouldRequest(userInitiated: Bool, inFlight: Bool, state: PermissionState) -> Bool {
        userInitiated && !inFlight && state != .granted
    }
}
