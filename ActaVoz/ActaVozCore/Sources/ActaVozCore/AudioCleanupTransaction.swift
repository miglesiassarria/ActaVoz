import Foundation

/// Diario durable: después de publicar audio.m4a, un fallo de limpieza no debe
/// volver a exportar usando solo los fragmentos que quedaron.
public struct AudioCleanupTransaction {
    private struct Journal: Codable { let paths: [String] }
    private var preparedURL: URL { folder.appendingPathComponent("audio-limpieza-preparada.json") }
    public let folder: URL
    public var journalURL: URL { folder.appendingPathComponent("audio-limpieza.json") }
    public init(folder: URL) { self.folder = folder }

    public func prepare(_ files: [URL]) throws {
        let root = folder.resolvingSymlinksInPath().standardizedFileURL.path + "/"
        let paths = try files.map { file -> String in
            let path = file.resolvingSymlinksInPath().standardizedFileURL.path
            guard path.hasPrefix(root) else { throw CaptureError.driverFailed("Una fuente está fuera de la sesión.") }
            return String(path.dropFirst(root.count))
        }
        try JSONEncoder().encode(Journal(paths: paths)).write(to: preparedURL, options: .atomic)
    }

    public func commit() throws {
        if FileManager.default.fileExists(atPath: journalURL.path) { throw CaptureError.driverFailed("Ya existe una limpieza pendiente.") }
        try FileManager.default.moveItem(at: preparedURL, to: journalURL)
    }

    public func begin(_ files: [URL]) throws { try prepare(files); try commit() }

    public func complete(remove: (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) }) throws {
        guard FileManager.default.fileExists(atPath: journalURL.path) else { return }
        let journal = try JSONDecoder().decode(Journal.self, from: Data(contentsOf: journalURL))
        let root = folder.resolvingSymlinksInPath().standardizedFileURL.path + "/"
        for path in journal.paths {
            guard !path.hasPrefix("/"), !path.split(separator: "/").contains("..") else { throw CaptureError.driverFailed("Ruta de limpieza inválida.") }
            let file = folder.appendingPathComponent(path)
            for target in [file, AudioTimelineFragment.sidecarURL(for: file)] {
                guard target.resolvingSymlinksInPath().standardizedFileURL.path.hasPrefix(root) else { throw CaptureError.driverFailed("La ruta de limpieza sale de la sesión.") }
                if FileManager.default.fileExists(atPath: target.path) { try remove(target) }
                // Restos de escritura atómica interrumpida (.sb-*) del sidecar.
                let prefix = target.lastPathComponent + ".sb-"
                let siblings = (try? FileManager.default.contentsOfDirectory(at: target.deletingLastPathComponent(), includingPropertiesForKeys: nil)) ?? []
                for sibling in siblings where sibling.lastPathComponent.hasPrefix(prefix) { try remove(sibling) }
            }
        }
    }

    public func finish() throws {
        if FileManager.default.fileExists(atPath: journalURL.path) { try FileManager.default.removeItem(at: journalURL) }
    }
}
