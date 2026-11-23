import SwiftUI

@main
struct ActaVozApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("ActaVoz") {
            RootView(bootstrap: .shared, firstRun: .shared, recording: AppBootstrap.shared.recordingFlow)
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
