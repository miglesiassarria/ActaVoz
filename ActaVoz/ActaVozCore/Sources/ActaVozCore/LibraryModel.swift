import Combine
import Foundation

/// Estado de la biblioteca. Toda la verdad está en el repositorio; el modelo
/// solo refleja el disco y presenta errores sin afirmar éxito.
@MainActor
final class LibraryModel: ObservableObject {
    enum Selection: Hashable {
        case inbox
        case directory(String)
    }

    enum Deletion: Equatable {
        case session(SessionSummary)
        case directory(String)
    }

    @Published private(set) var directories: [String] = []
    @Published private(set) var sessions: [SessionSummary] = []
    @Published var selection: Selection = .inbox
    @Published var selectedSession: SessionSummary?
    @Published var query: String = ""
    @Published var errorMessage: String?
    @Published var deletion: Deletion?
    @Published var isNamingDirectory = false
    @Published var newDirectoryName = ""
    @Published var showsNewNoteNotice = false

    let repository: SessionRepository
    private let search = LibrarySearch()

    init(repository: SessionRepository) {
        self.repository = repository
    }

    var location: SessionLocation {
        switch selection {
        case .inbox: return .inbox
        case .directory(let name): return .directory(name)
        }
    }

    var selectedDirectoryName: String? {
        if case .directory(let name) = selection { return name }
        return nil
    }

    /// Sesiones agrupadas por día de inicio, de más reciente a más antigua.
    var groups: [(day: Date, sessions: [SessionSummary])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.startDate) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0]!.sorted { $0.startDate > $1.startDate }) }
    }

    func reload() {
        do {
            directories = try repository.directories()
            sessions = try repository.sessions(matching: query, in: location)
            if case .directory(let name) = selection, !directories.contains(name) {
                selection = .inbox
                selectedSession = nil
                sessions = try repository.sessions(matching: query, in: .inbox)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Abre una sesión por su carpeta, útil al terminar una grabación.
    func selectSession(at folder: URL) {
        reload()
        selectedSession = sessions.first { $0.folderURL.standardizedFileURL == folder.standardizedFileURL }
    }

    func select(_ newSelection: Selection) {
        selection = newSelection
        selectedSession = nil
        reload()
    }

    func updateQuery(_ text: String) {
        query = text
        reload()
    }

    func createDirectory() {
        do {
            let name = try repository.createDirectory(named: newDirectoryName)
            newDirectoryName = ""
            isNamingDirectory = false
            directories = try repository.directories()
            select(.directory(name))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestDeleteDirectory() {
        guard let name = selectedDirectoryName else { return }
        deletion = .directory(name)
    }

    func requestDeleteSession() {
        guard let session = selectedSession else { return }
        deletion = .session(session)
    }

    func confirmDeletion() {
        guard let deletion else { return }
        do {
            switch deletion {
            case .session(let session):
                try repository.deleteSession(at: session.folderURL)
                selectedSession = nil
            case .directory(let name):
                try repository.deleteDirectory(named: name)
                selectedSession = nil
                selection = .inbox
            }
            self.deletion = nil
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelDeletion() {
        deletion = nil
    }

    /// Punto de entrada de «Nueva nota». La grabación real llega en 0004.
    func requestNewNote() {
        showsNewNoteNotice = true
    }

    func moveSelectedSession(to selection: Selection) {
        guard let session = selectedSession else { return }
        let destination: SessionLocation
        switch selection {
        case .inbox: destination = .inbox
        case .directory(let name): destination = .directory(name)
        }
        do {
            let moved = try repository.moveSession(at: session.folderURL, to: destination)
            self.selection = selection
            selectedSession = moved
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Estado de una sesión abierta. Guarda al cambiar, como acordó el producto.
@MainActor
final class SessionModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case notes = "Mis notas"
        case summary = "Resumen"
        case chat = "Chat"
        case transcript = "Transcripción"

        var id: String { rawValue }
    }

    @Published private(set) var session: Session?
    @Published var errorMessage: String?
    @Published var tab: Tab = .notes
    /// Audio que quedó sin decidir al cerrar; se vuelve a preguntar al abrir.
    @Published private(set) var pendingAudio: [URL] = []
    @Published private(set) var resolvingAudio = false

    let folderURL: URL
    private let repository: SessionRepository
    private let finalizer: (any AudioFinalizing)?

    init(repository: SessionRepository, folderURL: URL, finalizer: (any AudioFinalizing)? = nil) {
        self.repository = repository
        self.folderURL = folderURL
        self.finalizer = finalizer
        self.pendingAudio = RecordingController.pendingAudioFiles(in: folderURL)
    }

    func load() {
        do {
            session = try repository.loadSession(at: folderURL)
            pendingAudio = RecordingController.pendingAudioFiles(in: folderURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func keepPendingAudio() async {
        guard !pendingAudio.isEmpty, !resolvingAudio, let finalizer else { return }
        resolvingAudio = true
        errorMessage = nil
        defer { resolvingAudio = false }
        do {
            let cleanup = AudioCleanupTransaction(folder: folderURL)
            if !FileManager.default.fileExists(atPath: cleanup.journalURL.path) {
                try cleanup.prepare(pendingAudio)
                try await finalizer.combine(pendingAudio, to: folderURL.appendingPathComponent("audio.m4a"))
                try cleanup.commit()
            }
            try cleanup.complete()
            try RecordingController.clearPendingAudioMarker(in: folderURL)
            try cleanup.finish()
            pendingAudio = []
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func discardPendingAudio() {
        guard !resolvingAudio else { return }
        errorMessage = nil
        do { try removePendingFiles() }
        catch { errorMessage = error.localizedDescription }
    }

    private func removePendingFiles() throws {
        for file in pendingAudio {
            if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
            let sidecar = AudioTimelineFragment.sidecarURL(for: file)
            if FileManager.default.fileExists(atPath: sidecar.path) { try FileManager.default.removeItem(at: sidecar) }
        }
        try RecordingController.clearPendingAudioMarker(in: folderURL)
        pendingAudio = []
        load()
    }

    func saveTitle(_ title: String) {
        guard let session else { return }
        var metadata = session.summary.metadata
        metadata.title = title
        do {
            try repository.updateTitle(title, at: folderURL)
            self.session = Session(
                summary: SessionSummary(
                    metadata: metadata,
                    location: session.summary.location,
                    folderURL: session.summary.folderURL,
                    hasAudio: session.summary.hasAudio,
                    hasSummary: session.summary.hasSummary
                ),
                transcript: session.transcript,
                notes: session.notes,
                summaryText: session.summaryText,
                synthesis: session.synthesis,
                chat: session.chat
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveNotes(_ notes: String) {
        guard var current = session else { return }
        current.notes = notes
        session = current
        do {
            try repository.writeNotes(notes, at: folderURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameParticipant(id: String, to name: String) {
        guard var current = session else { return }
        var participants = current.summary.metadata.participants
        guard let index = participants.firstIndex(where: { $0.id == id }) else { return }
        participants[index].name = name
        do {
            try repository.updateParticipants(participants, at: folderURL)
            current.summary.metadata.participants = participants
            session = current
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
