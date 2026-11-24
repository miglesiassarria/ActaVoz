import AppKit

/// Salvaguarda para vías externas de salida; el menú usa requestQuit explícito.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let flow = AppBootstrap.shared.recordingFlow
        if flow.blocksTermination {
            flow.requestQuit()
            return .terminateCancel
        }
        return .terminateNow
    }
}
