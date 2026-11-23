import AppKit

/// Intercepta el cierre mientras se graba (AC12) y ofrece continuar o parar.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let flow = AppBootstrap.shared.recordingFlow
        guard flow.phase == .recording || flow.phase == .processing else {
            return .terminateNow
        }
        if flow.phase == .processing {
            return .terminateNow
        }

        let alert = NSAlert()
        alert.messageText = "Se está grabando"
        alert.informativeText = "Puedes seguir grabando o detener la sesión y cerrar ActaVoz."
        alert.addButton(withTitle: "Seguir grabando")
        alert.addButton(withTitle: "Detener y cerrar")
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            Task { @MainActor in
                await flow.stop()
                sender.reply(toApplicationShouldTerminate: true)
            }
            return .terminateLater
        }
        return .terminateCancel
    }
}
