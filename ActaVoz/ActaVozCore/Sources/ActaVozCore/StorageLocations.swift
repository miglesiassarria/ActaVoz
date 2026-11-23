import Foundation

/// Rutas base de ActaVoz. `root` es inyectable para poder probar sin tocar el home real.
public struct StorageLocations: Equatable, Sendable {
    public var root: URL
    public var configurationDirectory: URL
    public var cachesDirectory: URL

    public init(root: URL, configurationDirectory: URL, cachesDirectory: URL) {
        self.root = root
        self.configurationDirectory = configurationDirectory
        self.cachesDirectory = cachesDirectory
    }

    /// Ubicaciones reales: sesiones bajo `~/.ActaVoz`, configuración en Library y cachés en Caches.
    public static func production(fileManager: FileManager = .default) -> StorageLocations {
        let home = fileManager.homeDirectoryForCurrentUser
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? home.appendingPathComponent("Library/Application Support", isDirectory: true)
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? home.appendingPathComponent("Library/Caches", isDirectory: true)
        return StorageLocations(
            root: home.appendingPathComponent(".ActaVoz", isDirectory: true),
            configurationDirectory: support.appendingPathComponent("ActaVoz", isDirectory: true),
            cachesDirectory: caches.appendingPathComponent("ActaVoz", isDirectory: true)
        )
    }

    /// Ubicaciones aisladas para pruebas: todo cuelga de `root`, nunca del home.
    public static func testing(root: URL) -> StorageLocations {
        StorageLocations(
            root: root,
            configurationDirectory: root.appendingPathComponent("Config", isDirectory: true),
            cachesDirectory: root.appendingPathComponent("Caches", isDirectory: true)
        )
    }

    public var notesDirectory: URL { root.appendingPathComponent("Notas", isDirectory: true) }
    public var userDirectoriesDirectory: URL { root.appendingPathComponent("Directorios", isDirectory: true) }
    public var settingsFile: URL { configurationDirectory.appendingPathComponent("config.json") }
}

public enum StorageError: Error, LocalizedError, Equatable {
    case pathIsNotDirectory(URL)
    case cannotCreateDirectory(URL, reason: String)

    public var errorDescription: String? {
        switch self {
        case .pathIsNotDirectory(let url):
            return "«\(url.path)» existe, pero no es una carpeta."
        case .cannotCreateDirectory(let url, let reason):
            return "No se pudo crear «\(url.path)»: \(reason)"
        }
    }
}

/// Crea la estructura de carpetas sin borrar ni sobrescribir contenido existente.
public struct DirectoryPreparer {
    public var fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func ensureDirectory(_ url: URL) throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else { throw StorageError.pathIsNotDirectory(url) }
            return
        }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw StorageError.cannotCreateDirectory(url, reason: error.localizedDescription)
        }
    }

    /// Raíz de sesiones y sus dos subcarpetas (AC2).
    public func prepareSessionsRoot(_ locations: StorageLocations) throws {
        try ensureDirectory(locations.root)
        try ensureDirectory(locations.notesDirectory)
        try ensureDirectory(locations.userDirectoriesDirectory)
    }

    /// Estructura completa: sesiones, configuración y cachés (AC2 y AC3).
    public func prepare(_ locations: StorageLocations) throws {
        try prepareSessionsRoot(locations)
        try ensureDirectory(locations.configurationDirectory)
        try ensureDirectory(locations.cachesDirectory)
    }
}
