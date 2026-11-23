import AVFoundation
import AppKit
import Combine
import SwiftUI

/// Flujo de «Nueva nota»: panel previo, grabación, procesado y política de audio.
@MainActor
final class RecordingFlowModel: ObservableObject {
    enum Phase: Equatable {
        case preparation
        case recording
        case processing
        case finished
    }

    @Published var isPresented = false
    @Published var phase: Phase = .preparation
    @Published var options = RecordingOptions()
    @Published var availability = CaptureAvailability()
    @Published var errorMessage: String?
    @Published var warning: String?
    @Published var elapsed: TimeInterval = 0
    @Published var statusText = ""
    @Published var awaitingAudioDecision = false
    @Published var isStarting = false
    @Published var createdTitle: String?
    @Published var pendingRecovery: (summary: SessionSummary, marker: PendingRecording)?

    var onOpenSession: ((URL) -> Void)?

    private let repository: SessionRepository
    private let retentionPolicy: () -> AudioRetentionPolicy
    private let driver = SystemCaptureDriver()
    @Published var checkingPermissions = false
    private var controller: RecordingController?
    private var folder: URL?
    private var ticker: Task<Void, Never>?

    init(
        repository: SessionRepository,
        retentionPolicy: @escaping () -> AudioRetentionPolicy = { .alwaysKeep }
    ) {
        self.repository = repository
        self.retentionPolicy = retentionPolicy
    }

    var canStart: Bool {
        PermissionRequestPolicy.canAttemptStart(options: options, availability: availability)
    }

    var elapsedText: String {
        let total = Int(elapsed.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    func present() {
        phase = .preparation
        errorMessage = nil
        warning = nil
        elapsed = 0
        awaitingAudioDecision = false
        options = RecordingOptions()
        pendingRecovery = findPendingRecording()
        refreshAvailability()
        isPresented = true
    }

    func dismiss() {
        guard !isStarting, phase != .recording, phase != .processing else { return }
        stopTicker()
        isPresented = false
        controller = nil
        folder = nil
        pendingRecovery = nil
    }

    func refreshAvailability() {
        availability = driver.availability()
        // Consulta pasiva: SCShareableContent puede abrir un diálogo TCC.
        // Nunca invocarlo al presentar el panel ni al volver de Ajustes.
        if !canStart {
            warning = "Concede permiso al micrófono o al audio del sistema para poder grabar."
        } else if warning != nil {
            warning = nil
        }
    }

    func requestPermissions() {
        guard !checkingPermissions else { return }
        let snapshot = driver.availability()
        checkingPermissions = true
        Task { @MainActor in
            defer { checkingPermissions = false }
            if options.microphoneEnabled, snapshot.microphone == .undetermined {
                _ = await AVCaptureDevice.requestAccess(for: .audio)
            }
            if options.systemEnabled, PermissionRequestPolicy.shouldRequest(userInitiated: true, inFlight: false, state: snapshot.system) {
                // Una sola vía: ScreenCaptureKit solicita/resuelve el permiso.
                // No encadenar CGRequestScreenCaptureAccess y otra petición.
                _ = await driver.checkSystemAccess()
            }
            refreshAvailability()
        }
    }

    func openPrivacySettings(for source: CaptureSource) {
        let pane = source == .microphone ? "Privacy_Microphone" : "Privacy_ScreenCapture"
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }

    func start() async {
        guard phase == .preparation, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }

        do {
            // El clic en Empezar autoriza la comprobación real; abrir el panel no.
            if options.systemEnabled { _ = await driver.checkSystemAccess() }
            refreshAvailability()
            guard PermissionRequestPolicy.canAttemptStart(options: options, availability: availability) else {
                throw CaptureError.noSourceAvailable
            }
            let summary = try repository.createSession(in: .inbox, language: options.language)
            folder = summary.folderURL
            createdTitle = summary.title

            let controller = RecordingController(
                folder: summary.folderURL,
                options: options,
                driver: driver,
                finalizer: CompositionAudioFinalizer(),
                retentionPolicy: retentionPolicy()
            )
            self.controller = controller
            try await controller.start()
            elapsed = controller.elapsed
            warning = controller.warning
            statusText = controller.status.displayName
            phase = .recording
            startTicker()
        } catch {
            errorMessage = error.localizedDescription
            phase = .preparation
        }
    }

    func resumeInterruptedSession() async {
        guard let pending = pendingRecovery, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            let controller = RecordingController(
                folder: pending.summary.folderURL,
                options: options,
                driver: driver,
                finalizer: CompositionAudioFinalizer(),
                retentionPolicy: retentionPolicy()
            )
            self.controller = controller
            self.folder = pending.summary.folderURL
            createdTitle = pending.summary.title
            try await controller.start()
            pendingRecovery = nil
            phase = .recording
            statusText = controller.status.displayName
            startTicker()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func finishInterruptedSession() {
        guard let pending = pendingRecovery else { return }
        PendingRecordingStore(folder: pending.summary.folderURL).clear()
        pendingRecovery = nil
        onOpenSession?(pending.summary.folderURL)
        dismiss()
    }

    func togglePause() {
        controller?.togglePause()
        tick()
    }

    func stop() async {
        guard let controller else { return }
        phase = .processing
        statusText = "Procesando la reunión"
        do {
            _ = try await controller.stop()
            if controller.status == .awaitingAudioDecision {
                awaitingAudioDecision = true
                phase = .finished
                statusText = "Audio pendiente de decisión"
            } else {
                phase = .finished
                statusText = controller.status.displayName
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .finished
        }
        stopTicker()
    }

    func resolveAudio(keep: Bool) async {
        do {
            try await controller?.resolveAudioDecision(keep: keep)
            awaitingAudioDecision = false
            statusText = "Procesada"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func showSession() {
        if let folder {
            onOpenSession?(folder)
        }
        dismiss()
    }

    private func tick() {
        guard let controller else { return }
        controller.tick()
        elapsed = controller.elapsed
        statusText = controller.status.displayName
        warning = controller.warning
        if controller.status == .awaitingAudioDecision {
            awaitingAudioDecision = true
        }
        if case .failed(let message) = controller.status {
            errorMessage = message
        }
    }

    private func startTicker() {
        stopTicker()
        ticker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                self?.tick()
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func findPendingRecording() -> (SessionSummary, PendingRecording)? {
        guard let sessions = try? repository.allSessions() else { return nil }
        for summary in sessions {
            if let marker = PendingRecordingStore(folder: summary.folderURL).load() {
                return (summary, marker)
            }
        }
        return nil
    }
}

struct RecordingFlowView: View {
    @ObservedObject var model: RecordingFlowModel

    var body: some View {
        Group {
            switch model.phase {
            case .preparation:
                NewNotePanel(model: model)
            case .recording, .processing, .finished:
                RecordingPanel(model: model)
            }
        }
        .frame(width: 540)
        .interactiveDismissDisabled(model.isStarting || model.phase == .recording || model.phase == .processing)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if model.phase == .preparation { model.refreshAvailability() }
        }
        .alert("No se pudo completar", isPresented: errorBinding) {
            Button("Entendido", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
    }
}

// MARK: - Panel previo

struct NewNotePanel: View {
    @ObservedObject var model: RecordingFlowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nueva nota").font(.title2.bold())

            if let pending = model.pendingRecovery {
                recovery(pending)
            }

            Text("ActaVoz necesita acceso al micrófono y al audio del sistema. macOS pedirá permiso la primera vez; puedes grabar con una sola fuente si la otra no está disponible.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker("Idioma", selection: languageBinding) {
                ForEach(SessionLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }

            Toggle("Guardar perfiles de voz al confirmar nombres", isOn: profilesBinding)

            GroupBox("Fuentes") {
                VStack(alignment: .leading, spacing: 10) {
                    sourceRow(.microphone, enabled: micBinding)
                    sourceRow(.system, enabled: systemBinding)
                    if model.options.microphoneEnabled, !model.availability.devices.isEmpty {
                        Picker("Micrófono", selection: deviceBinding) {
                            Text("Predeterminado").tag(String?.none)
                            ForEach(model.availability.devices) { device in
                                Text(device.name).tag(Optional(device.id))
                            }
                        }
                    }
                }
                .padding(6)
            }

            if let warning = model.warning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            HStack {
                Button(model.checkingPermissions ? "Comprobando permisos…" : "Solicitar permisos") { model.requestPermissions() }
                    .disabled(model.checkingPermissions || model.isStarting)
                Spacer()
                Button("Cancelar") { model.dismiss() }.disabled(model.isStarting)
                Button("Empezar") { Task { await model.start() } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canStart || model.isStarting || model.checkingPermissions)
            }
        }
        .padding(22)
    }

    private func recovery(_ pending: (summary: SessionSummary, marker: PendingRecording)) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sesión interrumpida").font(.headline)
                Text("«\(pending.summary.title)» conserva lo capturado. Puedes reanudarla o darla por terminada.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Reanudar") { Task { await model.resumeInterruptedSession() } }.disabled(model.isStarting)
                    Button("Dar por terminada") { model.finishInterruptedSession() }.disabled(model.isStarting)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
    }

    private func sourceRow(_ source: CaptureSource, enabled: Binding<Bool>) -> some View {
        let permission = model.availability.permission(for: source)
        return HStack {
            Toggle(source.displayName, isOn: enabled)
            Spacer()
            switch permission {
            case .granted:
                Label("Permitido", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .denied:
                Button("Abrir Ajustes") { model.openPrivacySettings(for: source) }
                    .font(.caption)
            case .undetermined:
                Text(source == .system ? "Sin verificar" : "Sin solicitar").font(.caption).foregroundStyle(.secondary)
            case .unavailable:
                Text("No disponible").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var languageBinding: Binding<SessionLanguage> {
        Binding(get: { model.options.language }, set: { model.options.language = $0 })
    }
    private var profilesBinding: Binding<Bool> {
        Binding(get: { model.options.savesVoiceProfiles }, set: { model.options.savesVoiceProfiles = $0 })
    }
    private var micBinding: Binding<Bool> {
        Binding(get: { model.options.microphoneEnabled }, set: { model.options.microphoneEnabled = $0 })
    }
    private var systemBinding: Binding<Bool> {
        Binding(get: { model.options.systemEnabled }, set: { model.options.systemEnabled = $0 })
    }
    private var deviceBinding: Binding<String?> {
        Binding(get: { model.options.microphoneDeviceID }, set: { model.options.microphoneDeviceID = $0 })
    }
}

// MARK: - Grabación

struct RecordingPanel: View {
    @ObservedObject var model: RecordingFlowModel

    var body: some View {
        VStack(spacing: 18) {
            if let title = model.createdTitle {
                Text(title).font(.headline)
            }
            Text(model.elapsedText)
                .font(.system(size: 46, design: .monospaced))
            Text(model.statusText).foregroundStyle(.secondary)

            if let warning = model.warning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            switch model.phase {
            case .recording:
                HStack(spacing: 12) {
                    Button(model.statusText == "En pausa" ? "Reanudar" : "Pausar") { model.togglePause() }
                    Button("Detener", role: .destructive) { Task { await model.stop() } }
                }
            case .processing:
                ProgressView("Procesando la reunión…")
            case .finished:
                if model.awaitingAudioDecision {
                    VStack(spacing: 10) {
                        Text("¿Conservar el audio de esta sesión?").font(.headline)
                        HStack {
                            Button("Borrar audio") { Task { await model.resolveAudio(keep: false) } }
                            Button("Guardar audio") { Task { await model.resolveAudio(keep: true) } }
                                .keyboardShortcut(.defaultAction)
                        }
                    }
                } else {
                    Button("Generar resumen") { model.showSession() }
                        .keyboardShortcut(.defaultAction)
                }
            case .preparation:
                EmptyView()
            }
        }
        .padding(26)
    }
}
