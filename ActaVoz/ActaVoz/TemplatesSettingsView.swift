import SwiftUI

struct TemplatesSettingsView: View {
    @State private var templates: [SummaryTemplate] = []
    @State private var query = ""
    @State private var editing: SummaryTemplate?
    @State private var showingEditor = false
    @State private var deleteCandidate: SummaryTemplate?
    @State private var errorMessage: String?

    private let store = SummaryTemplateStore(fileURL: StorageLocations.production().templatesFile)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plantillas de resumen").font(.title2.bold())
            HStack {
                TextField("Buscar por nombre", text: $query)
                Button("Nueva plantilla") {
                    editing = SummaryTemplate(name: "", instructions: "", sections: ["Síntesis"])
                    showingEditor = true
                }
                Button("Actualizar") { load() }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.orange).font(.callout) }
            List(filtered) { template in
                HStack {
                    VStack(alignment: .leading) {
                        Text(template.name).font(.headline)
                        Text(template.sections.joined(separator: " · "))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if template.isBuiltIn {
                        Text("Predefinida").font(.caption).foregroundStyle(.secondary)
                        Button("Duplicar") { duplicate(template) }
                    } else {
                        Button("Editar") { editing = template; showingEditor = true }
                        Button("Eliminar", role: .destructive) { deleteCandidate = template }
                    }
                }
            }
        }
        .padding(20)
        .task { load() }
        .sheet(isPresented: $showingEditor) {
            TemplateEditor(template: editing ?? SummaryTemplate(name: "", instructions: "", sections: [])) { saved in
                save(saved)
                showingEditor = false
            } onCancel: { showingEditor = false }
        }
        .alert("¿Eliminar la plantilla?", isPresented: Binding(
            get: { deleteCandidate != nil },
            set: { if !$0 { deleteCandidate = nil } }
        )) {
            Button("Cancelar", role: .cancel) { deleteCandidate = nil }
            Button("Eliminar", role: .destructive) {
                if let candidate = deleteCandidate { delete(candidate) }
                deleteCandidate = nil
            }
        } message: {
            Text("Solo se elimina esta plantilla propia; las predefinidas no cambian.")
        }
    }

    private var filtered: [SummaryTemplate] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return templates }
        return templates.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }

    private func load() {
        do { templates = try store.loadAll() }
        catch { errorMessage = error.localizedDescription }
    }

    private func save(_ template: SummaryTemplate) {
        do {
            if template.id.isEmpty || templates.contains(where: { $0.id == template.id }) {
                if template.isBuiltIn {
                    try store.update(template)
                } else if template.name.isEmpty {
                    throw SummaryTemplateError.emptyName
                } else {
                    try store.update(template)
                }
            } else {
                _ = try store.create(name: template.name, instructions: template.instructions, sections: template.sections)
            }
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    private func duplicate(_ template: SummaryTemplate) {
        do { _ = try store.duplicateBuiltIn(template); load() }
        catch { errorMessage = error.localizedDescription }
    }

    private func delete(_ template: SummaryTemplate) {
        do { try store.delete(id: template.id); load() }
        catch { errorMessage = error.localizedDescription }
    }
}

private struct TemplateEditor: View {
    @State var template: SummaryTemplate
    var onSave: (SummaryTemplate) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(template.name.isEmpty ? "Nueva plantilla" : "Editar plantilla").font(.title3.bold())
            TextField("Nombre", text: $template.name)
            TextField("Instrucciones", text: $template.instructions)
            Text("Apartados (uno por línea)").font(.caption)
            TextEditor(text: Binding(
                get: { template.sections.joined(separator: "\n") },
                set: { template.sections = $0.split(separator: "\n").map(String.init).filter { !$0.isEmpty } }
            ))
            .frame(height: 140)
            HStack {
                Spacer()
                Button("Cancelar", action: onCancel)
                Button("Guardar") { onSave(template) }
                    .disabled(template.name.trimmingCharacters(in: .whitespaces).isEmpty || template.sections.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500, height: 380)
    }
}
