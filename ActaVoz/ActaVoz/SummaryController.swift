import Foundation
import SwiftUI

@MainActor
final class SummaryController: ObservableObject {
    @Published var templates: [SummaryTemplate] = []
    @Published var selectedTemplateID: String = SummaryTemplateCatalog.builtIns[0].id
    @Published var summaryText = ""
    @Published private(set) var isGenerating = false
    @Published var errorMessage: String?
    @Published var showingOverwriteConfirmation = false

    let folderURL: URL
    private let transcript: () -> String
    private let store: SummaryTemplateStore
    private let service: SummaryService
    private var pendingTemplate: SummaryTemplate?
    private var generatedText = ""

    init(folderURL: URL, transcript: @escaping () -> String) {
        self.folderURL = folderURL
        self.transcript = transcript
        self.store = SummaryTemplateStore(fileURL: StorageLocations.production().templatesFile)
        self.service = SummaryService(
            responder: ProviderSummaryResponder(
                configurationStore: ProviderConfigurationStore(fileURL: StorageLocations.production().providersFile),
                secrets: KeychainSecretStore()
            )
        )
        load()
    }

    var selectedTemplate: SummaryTemplate? {
        templates.first { $0.id == selectedTemplateID }
    }

    var hasSummary: Bool { !summaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var canGenerate: Bool { !isGenerating && !transcript().isEmpty }

    private func load() {
        templates = (try? store.loadAll()) ?? SummaryTemplateCatalog.builtIns
        summaryText = (try? String(contentsOf: folderURL.appendingPathComponent("resumen.md"), encoding: .utf8)) ?? ""
        generatedText = summaryText
    }

    func requestGenerate() {
        guard let template = selectedTemplate else { return }
        if hasSummary && service.wasManuallyEdited(at: folderURL) {
            pendingTemplate = template
            showingOverwriteConfirmation = true
        } else {
            generate(template)
        }
    }

    func confirmOverwrite() {
        showingOverwriteConfirmation = false
        if let pendingTemplate { generate(pendingTemplate) }
        pendingTemplate = nil
    }

    func cancelOverwrite() {
        showingOverwriteConfirmation = false
        pendingTemplate = nil
    }

    private func generate(_ template: SummaryTemplate) {
        isGenerating = true
        errorMessage = nil
        let text = transcript()
        Task { @MainActor in
            do {
                let result = try await service.generate(template: template, transcript: text)
                try service.save(result, at: folderURL)
                summaryText = result
                generatedText = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }

    func saveEdited() {
        do {
            try summaryText.write(to: folderURL.appendingPathComponent("resumen.md"), atomically: true, encoding: .utf8)
            if summaryText != generatedText {
                try service.markEdited(true, at: folderURL)
            } else {
                try service.markEdited(false, at: folderURL)
            }
        } catch {
            errorMessage = "No se pudo guardar el resumen: \(error.localizedDescription)"
        }
    }

    func delete() {
        do {
            try service.delete(at: folderURL)
            summaryText = ""
            generatedText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadTemplates() {
        templates = (try? store.loadAll()) ?? templates
    }
}

struct SummaryPanel: View {
    @ObservedObject var model: SummaryController
    var onConfigureProvider: () -> Void = {}
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("Plantilla", selection: $model.selectedTemplateID) {
                    ForEach(model.templates) { template in
                        Text(template.name).tag(template.id)
                    }
                }
                .frame(maxWidth: 280)
                Button(model.hasSummary ? "Regenerar resumen" : "Generar resumen") {
                    model.requestGenerate()
                }
                .disabled(!model.canGenerate)
                if model.isGenerating { ProgressView().controlSize(.small) }
                Spacer()
                Button("Eliminar", role: .destructive) { showingDeleteConfirmation = true }
                    .disabled(!model.hasSummary)
            }
            .padding(12)
            Divider()
            if let error = model.errorMessage {
                HStack {
                    Text(error).font(.callout).foregroundStyle(.orange)
                    Button("Cambiar modelo") { onConfigureProvider() }
                    Button("Reintentar") { model.requestGenerate() }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            TextEditor(text: Binding(
                get: { model.summaryText },
                set: { model.summaryText = $0; model.saveEdited() }
            ))
            .font(.body)
            .padding(8)
        }
        .alert("¿Sobrescribir el resumen editado?", isPresented: $model.showingOverwriteConfirmation) {
            Button("Cancelar", role: .cancel) { model.cancelOverwrite() }
            Button("Sobrescribir", role: .destructive) { model.confirmOverwrite() }
        } message: {
            Text("El resumen tiene ediciones manuales. Regenerarlo las sustituirá.")
        }
        .alert("¿Eliminar el resumen?", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) { model.delete() }
        } message: {
            Text("Se borrará el resumen. La transcripción y las notas no se tocan.")
        }
    }
}
