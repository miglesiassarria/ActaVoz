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
    static let shared = AppBootstrap(locations: resolvedLocations())

    /// Permite apuntar a una biblioteca de ejemplo sin tocar el home real:
    /// `ActaVoz -ActaVozRoot /ruta/a/fixtures`. Solo en compilaciones de depuración.
    static func resolvedLocations() -> StorageLocations {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment["ACTAVOZ_ROOT"]
        let arguments = CommandLine.arguments
        if let path = environment ?? (arguments.firstIndex(of: "-ActaVozRoot").flatMap { index in
            arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
        }) {
            let root = URL(fileURLWithPath: path, isDirectory: true)
            return StorageLocations(
                root: root,
                configurationDirectory: root.appendingPathComponent("Config", isDirectory: true),
                cachesDirectory: root.appendingPathComponent("Caches", isDirectory: true)
            )
        }
        #endif
        return .production()
    }

    @Published private(set) var phase: Phase = .preparing

    let locations: StorageLocations
    let repository: SessionRepository
    private(set) lazy var libraryModel = LibraryModel(repository: repository)
    private(set) lazy var recordingFlow = RecordingFlowModel(
        repository: repository,
        retentionPolicy: { [weak self] in
            (try? self?.store.load().audioRetentionPolicy) ?? .alwaysKeep
        }
    )

    private let bootstrap: Bootstrap
    private let store: SettingsStore

    init(locations: StorageLocations, fileManager: FileManager = .default) {
        self.locations = locations
        self.repository = SessionRepository(root: locations.root, fileManager: fileManager)
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
