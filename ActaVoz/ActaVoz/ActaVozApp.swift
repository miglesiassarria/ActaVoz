import SwiftUI

@main
struct ActaVozApp: App {
    var body: some Scene {
        WindowGroup("ActaVoz") {
            RootView(bootstrap: .shared, firstRun: .shared)
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
