import Combine
import Foundation

public protocol AudioFinalizing {
    func combine(_ sources: [URL], to destination: URL) throws
}

/// Marca de grabación en curso para recuperarla tras un cierre inesperado.
public struct PendingRecordingStore {
    public let folder: URL
    public let fileName: String

    public init(folder: URL, fileName: String = "grabacion.json") {
        self.folder = folder
        self.fileName = fileName
    }

    public var fileURL: URL { folder.appendingPathComponent(fileName) }

    public func save(_ pending: PendingRecording) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(pending).write(to: fileURL, options: .atomic)
    }

    public func load() -> PendingRecording? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PendingRecording.self, from: data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

/// Coordina permisos, fuentes, pausa, interrupciones y política de audio.
/// La captura real la aporta un `CaptureDriver`; las pruebas usan dobles.
@MainActor
public final class RecordingController: ObservableObject {
    @Published public private(set) var status: CaptureStatus = .idle
    @Published public private(set) var elapsed: TimeInterval = 0
    @Published public private(set) var warning: String?
    @Published public private(set) var availability = CaptureAvailability()
    @Published public private(set) var activeSources: Set<CaptureSource> = []
    @Published public private(set) var missingSources: Set<CaptureSource> = []

    public let folder: URL
    public let options: RecordingOptions
    public var retentionPolicy: AudioRetentionPolicy

    private let driver: any CaptureDriver
    private let finalizer: any AudioFinalizing
    private let marker: PendingRecordingStore
    private let now: () -> Date

    private var accumulated: TimeInterval = 0
    private var segmentStart: Date?
    private var pendingSources: [URL] = []

    public init(
        folder: URL,
        options: RecordingOptions,
        driver: any CaptureDriver,
        finalizer: any AudioFinalizing,
        marker: PendingRecordingStore? = nil,
        retentionPolicy: AudioRetentionPolicy = .alwaysKeep,
        now: @escaping () -> Date = Date.init
    ) {
        self.folder = folder
        self.options = options
        self.driver = driver
        self.finalizer = finalizer
        self.marker = marker ?? PendingRecordingStore(folder: folder)
        self.retentionPolicy = retentionPolicy
        self.now = now
    }

    // MARK: - Preparación

    public func refreshAvailability() {
        availability = driver.availability()
        var missing: Set<CaptureSource> = []
        for source in options.enabledSources where availability.permission(for: source) != .granted {
            missing.insert(source)
        }
        missingSources = missing
    }

    /// Fuentes con permiso que se van a capturar.
    public func plannedSources() -> Set<CaptureSource> {
        options.enabledSources.filter { availability.permission(for: $0) == .granted }
    }

    public var canStart: Bool {
        !plannedSources().isEmpty
    }

    // MARK: - Grabación

    public func start() throws {
        guard !status.isActive, status != .processing else { throw CaptureError.alreadyRecording }
        refreshAvailability()
        let plan = plannedSources()
        guard !plan.isEmpty else {
            status = .failed(CaptureError.noSourceAvailable.localizedDescription)
            throw CaptureError.noSourceAvailable
        }

        // Contrato del driver: los eventos llegan en el hilo principal.
        driver.onEvent = { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }
        do {
            try driver.start(CapturePlan(sources: plan, microphoneDeviceID: options.microphoneDeviceID), folder: folder)
        } catch {
            status = .failed(error.localizedDescription)
            throw CaptureError.driverFailed(error.localizedDescription)
        }

        accumulated = 0
        elapsed = 0
        segmentStart = now()
        activeSources = plan
        warning = warningIfMissing()
        status = .recording
        persistMarker()
    }

    public func tick() {
        guard status == .recording, let segmentStart else {
            return
        }
        elapsed = accumulated + now().timeIntervalSince(segmentStart)
    }

    public func togglePause() {
        switch status {
        case .recording:
            pause(reason: .user)
        case .paused:
            resume()
        default:
            break
        }
    }

    public func pause(reason: PauseReason) {
        guard status == .recording else { return }
        if let segmentStart {
            accumulated += now().timeIntervalSince(segmentStart)
            self.segmentStart = nil
        }
        elapsed = accumulated
        driver.pause()
        status = .paused(reason)
        persistMarker()
    }

    public func resume() {
        guard case .paused = status, !activeSources.isEmpty else { return }
        driver.resume()
        segmentStart = now()
        status = .recording
        warning = nil
        persistMarker()
    }

    @discardableResult
    public func stop() throws -> URL? {
        guard status.isActive else { throw CaptureError.notRecording }
        if let segmentStart {
            accumulated += now().timeIntervalSince(segmentStart)
            self.segmentStart = nil
        }
        elapsed = accumulated
        status = .processing

        let files: [URL]
        do {
            let captured = try driver.stop()
            let onDisk = audioFragments()
            files = onDisk.isEmpty ? captured.values.sorted { $0.path < $1.path } : onDisk
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
        activeSources = []
        marker.clear()
        return try applyPolicy(to: files)
    }

    /// Resuelve el audio cuando la política es «preguntar» y la persona responde.
    public func resolveAudioDecision(keep: Bool) throws {
        guard status == .awaitingAudioDecision else { return }
        let files = pendingSources
        defer { pendingSources = [] }
        if keep {
            _ = try keepAudio(files)
        } else {
            remove(files)
        }
        try removePendingMarker()
        status = .finished
    }

    public var hasPendingAudioDecision: Bool {
        status == .awaitingAudioDecision
    }

    // MARK: - Interrupciones

    private func handle(_ event: CaptureEvent) {
        switch event {
        case .chunk:
            break
        case .sourceLost(let source):
            sourceUnavailable(source, message: "Se perdió la fuente: \(source.displayName).")
        case .sourceRecovered(let source):
            activeSources.insert(source)
            if case .paused(.sourcesLost) = status {
                resume()
            }
        case .failed(let source, let message):
            sourceUnavailable(source, message: "\(source.displayName): \(message)")
        }
    }

    private func sourceUnavailable(_ source: CaptureSource, message: String) {
        activeSources.remove(source)
        warning = message
        if activeSources.isEmpty, status == .recording {
            pause(reason: .sourcesLost)
        }
    }

    // MARK: - Política de audio

    private func applyPolicy(to files: [URL]) throws -> URL? {
        switch retentionPolicy {
        case .alwaysDelete:
            remove(files)
            status = .finished
            return nil
        case .alwaysKeep:
            let destination = try keepAudio(files)
            status = .finished
            return destination
        case .askEachTime:
            pendingSources = files
            try writePendingMarker(files)
            status = .awaitingAudioDecision
            return nil
        }
    }

    private func keepAudio(_ files: [URL]) throws -> URL? {
        guard !files.isEmpty else { return nil }
        let destination = folder.appendingPathComponent("audio.m4a")
        do {
            try finalizer.combine(files, to: destination)
        } catch {
            status = .failed("No se pudo combinar el audio: \(error.localizedDescription)")
            throw error
        }
        remove(files)
        return destination
    }

    /// Fragmentos de audio de esta y anteriores ejecuciones dentro de la sesión.
    private func audioFragments() -> [URL] {
        let folder = self.folder.appendingPathComponent("AudioFuentes", isDirectory: true)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        ) else { return [] }
        return contents
            .filter { $0.pathExtension.lowercased() == "caf" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func remove(_ files: [URL]) {
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Marcadores

    private func persistMarker() {
        let pending = PendingRecording(
            startedAt: now(),
            elapsed: elapsed,
            sources: Array(activeSources),
            paused: status != .recording,
            language: options.language,
            savesVoiceProfiles: options.savesVoiceProfiles
        )
        try? marker.save(pending)
    }

    private var pendingAudioURL: URL { folder.appendingPathComponent("audio-pendiente.json") }

    private func writePendingMarker(_ files: [URL]) throws {
        let paths = files.map(\.lastPathComponent)
        let data = try JSONSerialization.data(withJSONObject: ["files": paths], options: [.prettyPrinted, .sortedKeys])
        try data.write(to: pendingAudioURL, options: .atomic)
    }

    private func removePendingMarker() throws {
        guard FileManager.default.fileExists(atPath: pendingAudioURL.path) else { return }
        try FileManager.default.removeItem(at: pendingAudioURL)
    }

    /// Archivos de audio pendientes de decisión, si el marcador existe.
    public static func pendingAudioFiles(in folder: URL) -> [URL] {
        let marker = folder.appendingPathComponent("audio-pendiente.json")
        guard let data = try? Data(contentsOf: marker),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: [String]],
              let names = object["files"] else { return [] }
        return names.map { folder.appendingPathComponent($0) }
    }

    private func warningIfMissing() -> String? {
        guard !missingSources.isEmpty else { return nil }
        let names = missingSources.map(\.displayName).sorted().joined(separator: " y ")
        return "Sin permiso para \(names). Se grabará con el resto."
    }
}
