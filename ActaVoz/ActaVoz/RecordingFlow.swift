import AVFoundation
import AppKit
import Combine
import SwiftUI

/// Resuelve una continuación una sola vez, aunque TCC responda tarde.
private final class OnceContinuation<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Never>?

    init(_ continuation: CheckedContinuation<T, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: T) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}

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
    @Published var showsQuitConfirmation = false
    @Published var waitingToQuit = false
    @Published var pendingRecovery: (summary: SessionSummary, marker: PendingRecording)?

    var onOpenSession: ((URL) -> Void)?
    let liveTranscript = LiveTranscriptModel()
    @Published var chat: SessionChatModel?

    private let repository: SessionRepository
    private let retentionPolicy: () -> AudioRetentionPolicy
    private let profileStore: SpeakerProfileStore
    private let driver = SystemCaptureDriver()
    @Published var checkingPermissions = false
    private var controller: RecordingController?
    private var folder: URL?
    private var ticker: Task<Void, Never>?
    private var externalOperations = 0
    private var quitAfterStart = false
    private var terminationScheduled = false

    init(
        repository: SessionRepository,
        retentionPolicy: @escaping () -> AudioRetentionPolicy = { .alwaysKeep },
        profileStore: SpeakerProfileStore? = nil
    ) {
        self.repository = repository
        self.retentionPolicy = retentionPolicy
        self.profileStore = profileStore ?? SpeakerProfileStore(fileURL: StorageLocations.production().profilesFile)
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
        liveTranscript.close()
        chat = nil
        pendingRecovery = findPendingRecording()
        refreshAvailability()
        isPresented = true
    }

    /// Al abrir la app, si quedó una grabación interrumpida, ofrecer recuperarla.
    func presentRecoveryIfNeeded() {
        guard !isPresented, phase == .preparation else { return }
        guard findPendingRecording() != nil else { return }
        present()
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
                // TCC puede no mostrar diálogo con una firma ad hoc nueva y dejar
                // la espera abierta para siempre. La interfaz no debe bloquearse.
                _ = await Self.withTimeout(seconds: 8, fallback: false) {
                    await AVCaptureDevice.requestAccess(for: .audio)
                }
            }
            if options.systemEnabled, PermissionRequestPolicy.shouldRequest(userInitiated: true, inFlight: false, state: snapshot.system) {
                _ = await Self.withTimeout(seconds: 8, fallback: PermissionState.undetermined) {
                    await self.driver.checkSystemAccess()
                }
            }
            refreshAvailability()
        }
    }

    private static func withTimeout<T>(seconds: Double, fallback: T, operation: @escaping () async -> T) async -> T {
        await withCheckedContinuation { continuation in
            let once = OnceContinuation(continuation)
            Task { once.resume(await operation()) }
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { once.resume(fallback) }
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
        errorMessage = nil
        defer { finishStarting() }

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
            let providerStore = ProviderConfigurationStore(fileURL: StorageLocations.production().providersFile)
            chat = SessionChatModel(
                folderURL: summary.folderURL,
                responder: ProviderChatResponder(configurationStore: providerStore, secrets: KeychainSecretStore()),
                transcriptProvider: { [weak self] in self?.liveTranscript.text ?? "" }
            )

            let controller = RecordingController(
                folder: summary.folderURL,
                options: options,
                driver: driver,
                finalizer: CompositionAudioFinalizer(),
                retentionPolicy: retentionPolicy(),
                preserveSourceAudio: true
            )
            self.controller = controller
            driver.onAudioBuffer = { [weak self] buffer, source in
                self?.liveTranscript.consume(buffer, source: source)
            }
            liveTranscript.begin(language: options.language)
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
        errorMessage = nil
        defer { finishStarting() }
        do {
            var resumed = options
            resumed.microphoneEnabled = pending.marker.sources.contains(.microphone)
            resumed.systemEnabled = pending.marker.sources.contains(.system)
            resumed.language = pending.marker.language
            resumed.savesVoiceProfiles = pending.marker.savesVoiceProfiles
            options = resumed
            if resumed.systemEnabled { _ = await driver.checkSystemAccess() }
            refreshAvailability()
            guard PermissionRequestPolicy.canAttemptStart(options: resumed, availability: availability) else {
                throw CaptureError.noSourceAvailable
            }
            let controller = RecordingController(
                folder: pending.summary.folderURL,
                options: resumed,
                driver: driver,
                finalizer: CompositionAudioFinalizer(),
                retentionPolicy: retentionPolicy(),
                restoredElapsed: pending.marker.elapsed,
                preserveSourceAudio: true
            )
            self.controller = controller
            self.folder = pending.summary.folderURL
            createdTitle = pending.summary.title
            try await controller.start()
            elapsed = controller.elapsed
            pendingRecovery = nil
            phase = .recording
            statusText = controller.status.displayName
            startTicker()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func finishInterruptedSession() async {
        guard let pending = pendingRecovery, !isStarting else { return }
        isStarting = true
        errorMessage = nil
        defer { finishStarting() }
        folder = pending.summary.folderURL
        createdTitle = pending.summary.title
        let recovered = RecordingController(folder: pending.summary.folderURL,
            options: options, driver: driver, finalizer: CompositionAudioFinalizer(),
            retentionPolicy: retentionPolicy(), restoredElapsed: pending.marker.elapsed,
            preserveSourceAudio: true)
        controller = recovered
        phase = .processing
        statusText = "Procesando la reunión"
        do {
            try await recovered.finishInterruptedRecording()
            liveTranscript.finish()
            pendingRecovery = nil
            elapsed = recovered.elapsed
            awaitingAudioDecision = recovered.hasPendingAudioDecision
            await processSession()
            statusText = recovered.status.displayName
            phase = .finished
        } catch {
            errorMessage = error.localizedDescription
            phase = .preparation
        }
    }

    var blocksTermination: Bool {
        isStarting || phase == .recording || phase == .processing || externalOperations > 0
    }

    func beginExternalOperation() { externalOperations += 1 }

    func endExternalOperation(succeeded: Bool) {
        externalOperations = max(0, externalOperations - 1)
        completeDeferredQuit(succeeded: succeeded)
    }

    private func finishStarting() {
        isStarting = false
        guard quitAfterStart else {
            completeDeferredQuit(succeeded: errorMessage == nil)
            return
        }
        quitAfterStart = false
        guard errorMessage == nil else { waitingToQuit = false; return }
        if phase == .recording {
            Task { await stopAndQuit() }
        } else {
            completeDeferredQuit(succeeded: true)
        }
    }

    private func completeDeferredQuit(succeeded: Bool) {
        guard waitingToQuit else { return }
        guard succeeded else { waitingToQuit = false; return }
        guard !blocksTermination, !terminationScheduled else { return }
        waitingToQuit = false
        terminationScheduled = true
        // La terminación se solicita desde el onDismiss del sheet, una vez que
        // AppKit ha terminado realmente la animación y liberado la modalidad.
        if isPresented {
            isPresented = false
        } else {
            finishQuitAfterDismissal()
        }
    }

    func finishQuitAfterDismissal() {
        guard terminationScheduled else { return }
        terminationScheduled = false
        NSApplication.shared.terminate(nil)
    }

    func requestQuit() {
        guard !terminationScheduled else { return }
        if phase == .processing || externalOperations > 0 {
            waitingToQuit = true
        } else if phase == .recording || isStarting {
            showsQuitConfirmation = true
        } else {
            NSApplication.shared.terminate(nil)
        }
    }

    func stopAndQuit() async {
        showsQuitConfirmation = false
        waitingToQuit = true
        if isStarting { quitAfterStart = true; return }
        if phase == .processing { return }
        if phase == .recording {
            _ = await stop()
        } else {
            completeDeferredQuit(succeeded: errorMessage == nil)
        }
    }

    func togglePause() {
        controller?.togglePause()
        tick()
    }

    @discardableResult
    func stop() async -> Bool {
        guard let controller, phase == .recording else { return false }
        errorMessage = nil
        phase = .processing
        statusText = "Procesando la reunión"
        do {
            _ = try await controller.stop()
            liveTranscript.finish()
            await processSession()
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
        completeDeferredQuit(succeeded: errorMessage == nil)
        return errorMessage == nil
    }

    func resolveAudio(keep: Bool) async {
        guard let controller, !isStarting, phase == .finished else { return }
        errorMessage = nil
        phase = .processing
        defer { completeDeferredQuit(succeeded: errorMessage == nil) }
        do {
            try await controller.resolveAudioDecision(keep: keep)
            awaitingAudioDecision = false
            await processSession()
            statusText = "Procesada"
        } catch {
            errorMessage = error.localizedDescription
        }
        phase = .finished
    }

    func showSession() {
        if let folder {
            onOpenSession?(folder)
        }
        dismiss()
    }

    /// Transcripción y diarización locales sobre los CAF, una vez cerrada la captura.
    private func processSession() async {
        guard let folder else { return }
        statusText = "Transcribiendo y separando voces…"
        do {
            let service = SessionProcessingService(
                repository: repository,
                diarizer: FluidAudioDiarizer(),
                profileStore: profileStore
            )
            let result = try await service.process(
                folder: folder,
                options: SessionProcessingOptions(
                    language: options.language,
                    savesVoiceProfiles: options.savesVoiceProfiles,
                    labelsMicrophoneAsMe: options.labelsMicrophoneAsMe
                )
            )
            if let first = result.warnings.first {
                warning = first
            }
            statusText = "Transcripción lista"
        } catch {
            warning = "No se pudo transcribir: \(error.localizedDescription)"
        }
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
        .frame(width: 620, height: model.phase == .preparation ? nil : 620)
        .interactiveDismissDisabled(model.isStarting || model.phase == .recording || model.phase == .processing)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if model.phase == .preparation { model.refreshAvailability() }
        }
        .alert("Se está grabando", isPresented: Binding(
            get: { model.showsQuitConfirmation },
            set: { model.showsQuitConfirmation = $0 }
        )) {
            Button("Seguir grabando", role: .cancel) { model.showsQuitConfirmation = false }
            Button("Detener y cerrar", role: .destructive) { Task { await model.stopAndQuit() } }
        } message: {
            Text("Puedes seguir grabando o detener la sesión y cerrar ActaVoz.")
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
            Text(model.pendingRecovery == nil ? "Nueva nota" : "Recuperar grabación").font(.title2.bold())

            if let pending = model.pendingRecovery {
                recovery(pending)
                HStack {
                    Spacer()
                    Button("Ahora no") { model.dismiss() }.disabled(model.isStarting)
                }
            } else {
            Text("ActaVoz necesita acceso al micrófono y al audio del sistema. macOS pedirá permiso la primera vez; puedes grabar con una sola fuente si la otra no está disponible.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker("Idioma", selection: languageBinding) {
                ForEach(SessionLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }

            Toggle("Guardar perfiles de voz al confirmar nombres", isOn: profilesBinding)
            Toggle("Etiquetar el micrófono como «Yo»", isOn: labelsMeBinding)

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
                    Button("Dar por terminada") { Task { await model.finishInterruptedSession() } }.disabled(model.isStarting)
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
    private var labelsMeBinding: Binding<Bool> {
        Binding(get: { model.options.labelsMicrophoneAsMe }, set: { model.options.labelsMicrophoneAsMe = $0 })
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
                    Button("Salir de ActaVoz") { model.requestQuit() }
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
            if let chat = model.chat { ChatBar(model: chat) }
        }
        .padding(26)
        .contentShape(Rectangle())
        .onTapGesture {
            if model.liveTranscript.isVisible { model.liveTranscript.close() }
            model.chat?.close()
        }
        .overlay(alignment: .bottomLeading) {
            if model.liveTranscript.isVisible {
                LiveTranscriptPanel(model: model.liveTranscript)
                    .padding(16)
                    .padding(.bottom, 90)
            }
        }
        .overlay {
            if let chat = model.chat {
                ChatOverlay(model: chat) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
        }
    }
}

struct LiveTranscriptPanel: View {
    @ObservedObject var model: LiveTranscriptModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Transcripción en directo", systemImage: "waveform")
                    .font(.caption.bold())
                Spacer()
                Button {
                    model.close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .help("Cerrar la transcripción en directo")
            }
            ScrollView {
                Text(model.text)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 130)
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .frame(width: 360, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
    }
}
