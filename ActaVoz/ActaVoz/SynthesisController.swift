import SwiftUI

@MainActor
final class SynthesisController: ObservableObject {
    @Published var text = ""
    @Published private(set) var isGenerating = false
    @Published var errorMessage: String?
    @Published private(set) var needsUpdate = false

    let folderURL: URL
    private let notes: () -> String
    private let summary: () -> String
    private let service: SynthesisService

    init(folderURL: URL, notes: @escaping () -> String, summary: @escaping () -> String) {
        self.folderURL = folderURL
        self.notes = notes
        self.summary = summary
        self.service = SynthesisService(
            responder: ProviderSynthesisResponder(
                configurationStore: ProviderConfigurationStore(fileURL: StorageLocations.production().providersFile),
                secrets: KeychainSecretStore()
            )
        )
        load()
    }

    var hasSummary: Bool { !summary().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var hasSynthesis: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func load() {
        text = (try? String(contentsOf: folderURL.appendingPathComponent("sintesis.md"), encoding: .utf8)) ?? ""
        refreshState()
    }

    func refreshState() {
        needsUpdate = hasSynthesis && service.needsUpdate(notes: notes(), summary: summary(), at: folderURL)
    }

    func generate() {
        guard hasSummary else {
            errorMessage = SummaryServiceError.summaryRequired.localizedDescription
            return
        }
        isGenerating = true
        errorMessage = nil
        let n = notes(), s = summary()
        Task { @MainActor in
            do {
                let result = try await service.generate(notes: n, summary: s)
                try service.save(result, notes: n, summary: s, at: folderURL)
                text = result
                needsUpdate = false
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }

    func saveEdited() {
        guard hasSynthesis else { return }
        try? text.write(to: folderURL.appendingPathComponent("sintesis.md"), atomically: true, encoding: .utf8)
    }

    func delete() {
        try? service.delete(at: folderURL)
        text = ""
        needsUpdate = false
    }
}

struct SynthesisPanel: View {
    @ObservedObject var model: SynthesisController
    @State private var showingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Síntesis").font(.headline)
                Text("Generada por IA").font(.caption).foregroundStyle(.secondary)
                if model.needsUpdate {
                    Text("Las notas o el resumen cambiaron").font(.caption).foregroundStyle(.orange)
                }
                Spacer()
                Button(model.hasSynthesis ? "Actualizar síntesis" : "Generar síntesis") {
                    model.generate()
                }
                .disabled(model.isGenerating || !model.hasSummary)
                if model.isGenerating { ProgressView().controlSize(.small) }
                Button("Eliminar", role: .destructive) { showingDelete = true }
                    .disabled(!model.hasSynthesis)
            }
            if !model.hasSummary {
                Text("Genera primero el resumen principal.").font(.callout).foregroundStyle(.secondary)
            }
            if let error = model.errorMessage {
                Text(error).font(.callout).foregroundStyle(.orange)
            }
            if model.hasSynthesis {
                TextEditor(text: Binding(get: { model.text }, set: { model.text = $0; model.saveEdited() }))
                    .frame(minHeight: 120)
            }
        }
        .alert("¿Eliminar la síntesis?", isPresented: $showingDelete) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) { model.delete() }
        } message: {
            Text("Se borra la síntesis. Las notas, la transcripción y el resumen no se tocan.")
        }
    }
}
