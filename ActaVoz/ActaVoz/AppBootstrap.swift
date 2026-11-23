import Combine
import Foundation

/// Estado observable del arranque para la interfaz. La lógica vive en ActaVozCore.
@MainActor
final class AppBootstrap: ObservableObject {
    enum Phase: Equatable {
        case preparing
        case ready(AppConfiguration)
        case failed(String)
    }

    /// Instancia única de la aplicación; la interfaz solo la observa.
    static let shared = AppBootstrap(locations: .production())

    @Published private(set) var phase: Phase = .preparing

    private let bootstrap: Bootstrap
    private let store: SettingsStore

    init(locations: StorageLocations, fileManager: FileManager = .default) {
        self.bootstrap = Bootstrap(locations: locations, fileManager: fileManager)
        self.store = SettingsStore(fileURL: locations.settingsFile, fileManager: fileManager)
    }

    func start() {
        phase = .preparing
        do {
            phase = .ready(try bootstrap.prepare())
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Marca el primer inicio como completado cuando la persona decide continuar sin proveedor.
    func completeFirstRunWithoutProvider() {
        guard case .ready(var configuration) = phase else { return }
        configuration.hasCompletedFirstRun = true
        do {
            try store.save(configuration)
            phase = .ready(configuration)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
