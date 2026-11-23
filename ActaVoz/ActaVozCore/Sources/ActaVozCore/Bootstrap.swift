import Foundation

/// Secuencia de arranque sin estado de interfaz: prepara rutas y carga configuración.
/// Se puede probar de forma síncrona con una raíz temporal.
public struct Bootstrap {
    public var locations: StorageLocations
    public var fileManager: FileManager

    public init(locations: StorageLocations, fileManager: FileManager = .default) {
        self.locations = locations
        self.fileManager = fileManager
    }

    public func prepare() throws -> AppConfiguration {
        try DirectoryPreparer(fileManager: fileManager).prepare(locations)
        return try SettingsStore(fileURL: locations.settingsFile, fileManager: fileManager).load()
    }
}
