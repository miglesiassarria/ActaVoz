import Foundation

/// Configuración básica de la aplicación. Los proveedores y sus credenciales pertenecen a 0006.
public struct AppConfiguration: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var hasCompletedFirstRun: Bool

    public static let current = AppConfiguration(schemaVersion: 1, hasCompletedFirstRun: false)

    public init(schemaVersion: Int = 1, hasCompletedFirstRun: Bool = false) {
        self.schemaVersion = schemaVersion
        self.hasCompletedFirstRun = hasCompletedFirstRun
    }
}

public enum SettingsError: Error, LocalizedError, Equatable {
    case cannotRead(URL, reason: String)
    case invalidContents(URL, reason: String)
    case cannotWrite(URL, reason: String)

    public var errorDescription: String? {
        switch self {
        case .cannotRead(let url, let reason):
            return "No se pudo leer la configuración «\(url.path)»: \(reason)"
        case .invalidContents(let url, let reason):
            return "La configuración «\(url.path)» no es válida: \(reason)"
        case .cannotWrite(let url, let reason):
            return "No se pudo guardar la configuración «\(url.path)»: \(reason)"
        }
    }
}

/// Guarda la configuración como JSON con reemplazo atómico.
public struct SettingsStore {
    public var fileURL: URL
    public var fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func load() throws -> AppConfiguration {
        guard fileManager.fileExists(atPath: fileURL.path) else { return .current }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw SettingsError.cannotRead(fileURL, reason: error.localizedDescription)
        }
        guard !data.isEmpty else { return .current }

        do {
            return try JSONDecoder().decode(AppConfiguration.self, from: data)
        } catch {
            throw SettingsError.invalidContents(fileURL, reason: error.localizedDescription)
        }
    }

    public func save(_ configuration: AppConfiguration) throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(configuration)
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw SettingsError.cannotWrite(fileURL, reason: error.localizedDescription)
        }
    }
}
