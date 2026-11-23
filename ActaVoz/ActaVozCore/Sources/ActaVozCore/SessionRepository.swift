import Foundation

/// Repositorio de sesiones sobre una raíz inyectable. Todas las rutas se
/// validan contra la raíz y las escrituras son atómicas.
public struct SessionRepository {
    public var root: URL
    public var fileManager: FileManager

    public init(root: URL, fileManager: FileManager = .default) {
        self.root = root
        self.fileManager = fileManager
    }

    // MARK: - Ubicaciones

    public var inboxDirectory: URL { root.appendingPathComponent("Notas", isDirectory: true) }
    public var directoriesDirectory: URL { root.appendingPathComponent("Directorios", isDirectory: true) }

    public func baseURL(for location: SessionLocation) -> URL {
        switch location {
        case .inbox:
            return inboxDirectory
        case .directory(let name):
            return directoriesDirectory.appendingPathComponent(name, isDirectory: true)
        }
    }

    // MARK: - Directorios

    public func directories() throws -> [String] {
        try contents(of: directoriesDirectory)
            .filter { isRealDirectory($0) }
            .map(\.lastPathComponent)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    @discardableResult
    public func createDirectory(named rawName: String) throws -> String {
        let name = try Self.validatedDirectoryName(rawName)
        try ensureRoot()
        let url = directoriesDirectory.appendingPathComponent(name, isDirectory: true)
        guard !fileManager.fileExists(atPath: url.path) else {
            throw LibraryError.directoryAlreadyExists(name)
        }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
        } catch {
            throw LibraryError.io(url, reason: error.localizedDescription)
        }
        return name
    }

    @discardableResult
    public func renameDirectory(named oldName: String, to newRawName: String) throws -> String {
        try ensureRoot()
        let source = directoriesDirectory.appendingPathComponent(oldName, isDirectory: true)
        try validateUnderRoot(source)
        guard isRealDirectory(source) else { throw LibraryError.directoryNotFound(oldName) }
        let newName = try Self.validatedDirectoryName(newRawName)
        let destination = directoriesDirectory.appendingPathComponent(newName, isDirectory: true)
        guard !fileManager.fileExists(atPath: destination.path) else {
            throw LibraryError.directoryAlreadyExists(newName)
        }
        do {
            try fileManager.moveItem(at: source, to: destination)
        } catch {
            throw LibraryError.io(destination, reason: error.localizedDescription)
        }
        return newName
    }

    public func deleteDirectory(named name: String) throws {
        try ensureRoot()
        let url = directoriesDirectory.appendingPathComponent(name, isDirectory: true)
        try validateUnderRoot(url)
        guard fileManager.fileExists(atPath: url.path) else {
            throw LibraryError.directoryNotFound(name)
        }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw LibraryError.io(url, reason: error.localizedDescription)
        }
    }

    /// Nombres válidos: sin separadores, sin ocultos y sin anidamiento.
    public static func validatedDirectoryName(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              name.count <= 100,
              name != ".",
              name != "..",
              !name.hasPrefix("."),
              !name.contains("/"),
              !name.contains("\\"),
              !name.contains(":")
        else {
            throw LibraryError.invalidDirectoryName(rawName)
        }
        return name
    }

    // MARK: - Sesiones

    public func sessions(in location: SessionLocation) throws -> [SessionSummary] {
        let base = baseURL(for: location)
        if case .directory(let name) = location, !isRealDirectory(base) {
            throw LibraryError.directoryNotFound(name)
        }
        let summaries = try contents(of: base).compactMap { folder -> SessionSummary? in
            guard isRealDirectory(folder) else { return nil }
            let metadataURL = folder.appendingPathComponent("sesion.json")
            guard fileManager.fileExists(atPath: metadataURL.path) else { return nil }
            guard let metadata = try? loadMetadata(at: folder) else { return nil }
            return summary(metadata: metadata, location: location, folder: folder)
        }
        return summaries.sorted { $0.startDate > $1.startDate }
    }

    public func allSessions() throws -> [SessionSummary] {
        var result = try sessions(in: .inbox)
        for name in try directories() {
            result += try sessions(in: .directory(name))
        }
        return result.sorted { $0.startDate > $1.startDate }
    }

    /// Búsqueda por título, transcripción, notas y resumen. Sin texto devuelve todo.
    public func sessions(matching query: String, in location: SessionLocation? = nil) throws -> [SessionSummary] {
        let candidates = try location.map { try sessions(in: $0) } ?? allSessions()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return candidates }

        let search = LibrarySearch()
        return try candidates.filter { summary in
            let session = try loadSession(at: summary.folderURL)
            return search.matches(trimmed, in: [
                summary.title,
                session.transcript.plainText,
                session.notes,
                session.summaryText
            ])
        }
    }

    @discardableResult
    public func createSession(
        in location: SessionLocation,
        startDate: Date = Date(),
        language: SessionLanguage = .spanish,
        id: SessionID = .random()
    ) throws -> SessionSummary {
        let base = baseURL(for: location)
        try ensureDirectory(base)

        var candidate = id
        var folder = Self.folderURL(base: base, startDate: startDate, id: candidate)
        var attempts = 0
        while fileManager.fileExists(atPath: folder.path) {
            attempts += 1
            guard attempts < 10 else { throw LibraryError.collision(folder) }
            candidate = .random()
            folder = Self.folderURL(base: base, startDate: startDate, id: candidate)
        }

        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: false)
        } catch {
            throw LibraryError.io(folder, reason: error.localizedDescription)
        }

        let metadata = SessionMetadata(
            id: candidate.rawValue,
            title: Self.defaultTitle(for: startDate),
            startDate: startDate,
            language: language
        )
        do {
            try writeJSON(metadata, to: folder.appendingPathComponent("sesion.json"))
        } catch {
            try? fileManager.removeItem(at: folder)
            throw error
        }
        return summary(metadata: metadata, location: location, folder: folder)
    }

    public func loadSession(at folder: URL) throws -> Session {
        try validateUnderRoot(folder)
        guard fileManager.fileExists(atPath: folder.appendingPathComponent("sesion.json").path) else {
            throw LibraryError.sessionNotFound(folder)
        }
        let metadata = try loadMetadata(at: folder)
        let transcript = try loadJSON(
            Transcript.self,
            from: folder.appendingPathComponent("transcripcion.json"),
            fallback: Transcript(language: metadata.language)
        )
        let chat = try loadJSON(
            ChatHistory.self,
            from: folder.appendingPathComponent("chat.json"),
            fallback: ChatHistory()
        )
        let summaryText = readText(folder.appendingPathComponent("resumen.md"))
        let location = location(of: folder)
        let base = summary(metadata: metadata, location: location, folder: folder)
        return Session(
            summary: base,
            transcript: transcript,
            notes: readText(folder.appendingPathComponent("notas.md")),
            summaryText: summaryText,
            synthesis: readText(folder.appendingPathComponent("sintesis.md")),
            chat: chat
        )
    }

    public func updateTitle(_ title: String, at folder: URL) throws {
        var metadata = try loadMetadata(at: folder)
        metadata.title = title
        try writeJSON(metadata, to: folder.appendingPathComponent("sesion.json"))
    }

    public func updateParticipants(_ participants: [Participant], at folder: URL) throws {
        var metadata = try loadMetadata(at: folder)
        metadata.participants = participants
        try writeJSON(metadata, to: folder.appendingPathComponent("sesion.json"))
    }

    public func writeTranscript(_ transcript: Transcript, at folder: URL) throws {
        try writeJSON(transcript, to: folder.appendingPathComponent("transcripcion.json"))
    }

    public func writeChat(_ chat: ChatHistory, at folder: URL) throws {
        try writeJSON(chat, to: folder.appendingPathComponent("chat.json"))
    }

    public func writeNotes(_ notes: String, at folder: URL) throws {
        try writeText(notes, to: folder.appendingPathComponent("notas.md"))
    }

    public func writeSummary(_ summary: String, at folder: URL) throws {
        try writeText(summary, to: folder.appendingPathComponent("resumen.md"))
    }

    public func writeSynthesis(_ synthesis: String, at folder: URL) throws {
        try writeText(synthesis, to: folder.appendingPathComponent("sintesis.md"))
    }

    /// Copia el audio final combinado; reemplaza el anterior si existía.
    public func storeAudio(from source: URL, at folder: URL) throws {
        try validateUnderRoot(folder)
        let destination = folder.appendingPathComponent("audio.m4a")
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
        } catch {
            throw LibraryError.io(destination, reason: error.localizedDescription)
        }
    }

    @discardableResult
    public func moveSession(at folder: URL, to location: SessionLocation) throws -> SessionSummary {
        try validateUnderRoot(folder)
        let base = baseURL(for: location)
        try ensureDirectory(base)
        let destination = base.appendingPathComponent(folder.lastPathComponent, isDirectory: true)
        guard !fileManager.fileExists(atPath: destination.path) else {
            throw LibraryError.collision(destination)
        }
        do {
            try fileManager.moveItem(at: folder, to: destination)
        } catch {
            throw LibraryError.io(destination, reason: error.localizedDescription)
        }
        let metadata = try loadMetadata(at: destination)
        return summary(metadata: metadata, location: location, folder: destination)
    }

    public func deleteSession(at folder: URL) throws {
        try validateUnderRoot(folder)
        guard fileManager.fileExists(atPath: folder.path) else {
            throw LibraryError.sessionNotFound(folder)
        }
        do {
            try fileManager.removeItem(at: folder)
        } catch {
            throw LibraryError.io(folder, reason: error.localizedDescription)
        }
    }

    public func audioURL(at folder: URL) -> URL {
        folder.appendingPathComponent("audio.m4a")
    }

    // MARK: - Formato

    public static func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    public static func folderURL(base: URL, startDate: Date, id: SessionID) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return base
            .appendingPathComponent("\(formatter.string(from: startDate))_\(id.rawValue)", isDirectory: true)
    }

    // MARK: - Interno

    private func summary(metadata: SessionMetadata, location: SessionLocation, folder: URL) -> SessionSummary {
        SessionSummary(
            metadata: metadata,
            location: location,
            folderURL: folder,
            hasAudio: fileManager.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path),
            hasSummary: !readText(folder.appendingPathComponent("resumen.md")).isEmpty
        )
    }

    private func location(of folder: URL) -> SessionLocation {
        let standardized = folder.standardizedFileURL
        let inbox = inboxDirectory.standardizedFileURL
        if standardized.deletingLastPathComponent() == inbox { return .inbox }
        return .directory(standardized.deletingLastPathComponent().lastPathComponent)
    }

    private func contents(of directory: URL) throws -> [URL] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        do {
            return try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw LibraryError.io(directory, reason: error.localizedDescription)
        }
    }

    private func isRealDirectory(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        return values?.isDirectory == true && values?.isSymbolicLink != true
    }

    private func ensureRoot() throws {
        try ensureDirectory(root)
        try ensureDirectory(inboxDirectory)
        try ensureDirectory(directoriesDirectory)
    }

    private func ensureDirectory(_ url: URL) throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else { throw LibraryError.notUnderRoot(url) }
            return
        }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw LibraryError.io(url, reason: error.localizedDescription)
        }
    }

    private func validateUnderRoot(_ url: URL) throws {
        let rootPath = root.standardizedFileURL.resolvingSymlinksInPath().path
        let targetPath = url.standardizedFileURL.resolvingSymlinksInPath().path
        guard targetPath == rootPath || targetPath.hasPrefix(rootPath + "/") else {
            throw LibraryError.notUnderRoot(url)
        }
    }

    private func loadMetadata(at folder: URL) throws -> SessionMetadata {
        let url = folder.appendingPathComponent("sesion.json")
        guard fileManager.fileExists(atPath: url.path) else {
            throw LibraryError.sessionNotFound(folder)
        }
        do {
            let data = try Data(contentsOf: url)
            return try Self.decoder.decode(SessionMetadata.self, from: data)
        } catch {
            throw LibraryError.invalidMetadata(url, reason: error.localizedDescription)
        }
    }

    private func loadJSON<T: Decodable>(_ type: T.Type, from url: URL, fallback: @autoclosure () -> T) throws -> T {
        guard fileManager.fileExists(atPath: url.path) else { return fallback() }
        do {
            let data = try Data(contentsOf: url)
            guard !data.isEmpty else { return fallback() }
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw LibraryError.invalidMetadata(url, reason: error.localizedDescription)
        }
    }

    private func readText(_ url: URL) -> String {
        guard fileManager.fileExists(atPath: url.path) else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private func writeText(_ text: String, to url: URL) throws {
        do {
            try Data(text.utf8).write(to: url, options: .atomic)
        } catch {
            throw LibraryError.io(url, reason: error.localizedDescription)
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        do {
            let data = try Self.encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            throw LibraryError.io(url, reason: error.localizedDescription)
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
