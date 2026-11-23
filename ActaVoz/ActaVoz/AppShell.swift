import SwiftUI

/// Estado del panel de primer inicio. Sin macros de SwiftUI para que el
/// proyecto compile también en entornos que no permiten sandbox-exec.
@MainActor
final class FirstRunModel: ObservableObject {
    static let shared = FirstRunModel()

    @Published var showsProviderNotice = false

    func requestProviderSetup() {
        showsProviderNotice = true
    }
}

/// Decide qué mostrar según el estado del arranque. Nada que escriba en disco
/// está habilitado hasta que las ubicaciones existen y la configuración cargó.
struct RootView: View {
    @ObservedObject var bootstrap: AppBootstrap
    @ObservedObject var firstRun: FirstRunModel

    var body: some View {
        Group {
            switch bootstrap.phase {
            case .preparing:
                ProgressView("Preparando ActaVoz…")
                    .task { bootstrap.start() }
            case .ready(let configuration):
                if configuration.hasCompletedFirstRun {
                    MainView()
                } else {
                    FirstRunView(
                        model: firstRun,
                        onConfigureProvider: firstRun.requestProviderSetup,
                        onContinueWithoutProvider: bootstrap.completeFirstRunWithoutProvider
                    )
                }
            case .failed(let message):
                FailureView(message: message, retry: bootstrap.start)
            }
        }
        .frame(minWidth: 900, minHeight: 560)
    }
}

/// Marcador de posición de la ventana principal; la biblioteca real llega en 0003.
struct MainView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("ActaVoz")
                .font(.largeTitle.bold())
            Text("La base de la aplicación está preparada. La biblioteca de sesiones llegará en la unidad 0003.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct FailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("No se pudo preparar ActaVoz")
                .font(.title2.bold())
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
            Button("Reintentar", action: retry)
                .keyboardShortcut(.defaultAction)
        }
        .padding(40)
    }
}
