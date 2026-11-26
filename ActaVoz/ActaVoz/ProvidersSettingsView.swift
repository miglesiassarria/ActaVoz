import SwiftUI

struct SettingsRootView: View {
    var body: some View {
        TabView {
            ProfilesSettingsView()
                .tabItem { Label("Perfiles", systemImage: "person.wave.2") }
            ProvidersSettingsView()
                .tabItem { Label("Proveedores", systemImage: "network") }
            TemplatesSettingsView()
                .tabItem { Label("Plantillas", systemImage: "doc.text") }
        }
        .frame(width: 620, height: 520)
    }
}

struct ProvidersSettingsView: View {
    @State private var configuration = ProviderConfiguration()
    @State private var selectedID: String?
    @State private var editing: ProviderConnection?
    @State private var editingSecret = ""
    @State private var errorMessage: String?
    @State private var testMessage: String?
    @State private var testing = false
    @State private var showingEditor = false

    private let store = ProviderConfigurationStore(fileURL: StorageLocations.production().providersFile)
    private let secrets: any SecretStore = KeychainSecretStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proveedores de modelos")
                .font(.title2.bold())
            Text("Las claves se guardan en el Llavero. OAuth de terceros no está disponible; se usa clave o un servicio local.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Picker("Conexión activa", selection: activeBinding) {
                    Text("Sin proveedor").tag(String?.none)
                    ForEach(configuration.connections) { connection in
                        Text(connection.name).tag(Optional(connection.id))
                    }
                }
                .frame(maxWidth: 320)
                Button("Añadir conexión") {
                    editing = ProviderConnection(name: "", kind: .openAI)
                    editingSecret = ""
                    showingEditor = true
                }
            }

            if configuration.connections.isEmpty {
                ContentUnavailableView("Sin conexiones", systemImage: "network.slash", description: Text("Añade OpenAI, Claude, Ollama, OpenCode Go o un proveedor compatible."))
                    .frame(minHeight: 160)
            } else {
                List(selection: $selectedID) {
                    ForEach(configuration.connections) { connection in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(connection.name).font(.headline)
                                Text(connection.kind.displayName).font(.caption).foregroundStyle(.secondary)
                                if connection.id == configuration.activeConnectionID {
                                    Text("Activa").font(.caption.bold()).foregroundStyle(.green)
                                }
                            }
                            Text("\(connection.baseURL) · \(connection.defaultModel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(connection.id)
                    }
                    .onDelete(perform: delete)
                }
                .frame(minHeight: 150)
            }

            HStack {
                Button("Editar") { beginEdit() }
                    .disabled(selectedID == nil)
                Button("Eliminar") {
                    if let selectedID { removeConnection(selectedID) }
                }
                .disabled(selectedID == nil)
                Button(testing ? "Comprobando…" : "Comprobar conexión") { Task { await testConnection() } }
                    .disabled(testing || configuration.activeConnection == nil)
                Spacer()
                Button("Actualizar") { load() }
            }

            if let testMessage {
                Text(testMessage).font(.callout).foregroundStyle(testMessage.hasPrefix("OK") ? .green : .orange)
            }

            Divider()
            Text("Modelos por función").font(.headline)
            Text("El principal se usa para nombres y como respaldo. Puedes asignar otro a preguntas y resúmenes.")
                .font(.caption)
                .foregroundStyle(.secondary)
            modelPicker("Preguntas", selection: $configuration.chatModel)
            modelPicker("Resúmenes", selection: $configuration.summaryModel)
        }
        .padding(22)
        .task { load() }
        .sheet(isPresented: $showingEditor) {
            ProviderEditor(
                connection: editing ?? ProviderConnection(name: "", kind: .openAI),
                secret: $editingSecret,
                onCancel: { showingEditor = false },
                onSave: { connection in save(connection) }
            )
        }
        .alert("No se pudo completar", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Entendido", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var activeBinding: Binding<String?> {
        Binding(
            get: { configuration.activeConnectionID },
            set: { value in
                configuration.activeConnectionID = value
                persist()
            }
        )
    }

    private func modelPicker(_ title: String, selection: Binding<ModelSelection?>) -> some View {
        HStack {
            Picker(title, selection: selection) {
                Text("Principal").tag(ModelSelection?.none)
                ForEach(configuration.connections) { connection in
                    ForEach(connection.models.isEmpty ? [connection.defaultModel] : connection.models, id: \.self) { model in
                        Text("\(connection.name): \(model)")
                            .tag(Optional(ModelSelection(connectionID: connection.id, model: model)))
                    }
                }
            }
        }
    }

    private func load() {
        do {
            configuration = try store.load()
            selectedID = configuration.connections.first?.id
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persist() {
        do { try store.save(configuration) }
        catch { errorMessage = error.localizedDescription }
    }

    private func beginEdit() {
        guard let selectedID,
              let connection = configuration.connections.first(where: { $0.id == selectedID }) else { return }
        editing = connection
        editingSecret = (try? secrets.secret(for: connection.id)) ?? ""
        showingEditor = true
    }

    private func save(_ connection: ProviderConnection) {
        if let index = configuration.connections.firstIndex(where: { $0.id == connection.id }) {
            configuration.connections[index] = connection
        } else {
            configuration.connections.append(connection)
            if configuration.activeConnectionID == nil { configuration.activeConnectionID = connection.id }
        }
        if !editingSecret.isEmpty {
            do { try secrets.set(editingSecret, for: connection.id) }
            catch { errorMessage = error.localizedDescription }
        } else if !connection.kind.requiresKey {
            try? secrets.delete(account: connection.id)
        } else {
            try? secrets.delete(account: connection.id)
        }
        persist()
        showingEditor = false
        selectedID = connection.id
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            removeConnection(configuration.connections[index].id)
        }
    }

    private func removeConnection(_ id: String) {
        configuration.connections.removeAll { $0.id == id }
        if configuration.activeConnectionID == id { configuration.activeConnectionID = configuration.connections.first?.id }
        try? secrets.delete(account: id)
        persist()
        selectedID = configuration.connections.first?.id
    }

    private func testConnection() async {
        guard let connection = configuration.activeConnection else { return }
        testing = true
        defer { testing = false }
        do {
            let client = try ProviderFactory.make(connection: connection, store: secrets)
            try await client.check()
            testMessage = "OK: conexión correcta con \(connection.name)."
        } catch {
            testMessage = "Error: \(error.localizedDescription)"
        }
    }
}

private struct ProviderEditor: View {
    @State var connection: ProviderConnection
    @Binding var secret: String
    var onCancel: () -> Void
    var onSave: (ProviderConnection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(connection.name.isEmpty ? "Nueva conexión" : "Editar conexión").font(.title3.bold())
            Form {
                TextField("Nombre", text: $connection.name)
                Picker("Tipo", selection: $connection.kind) {
                    ForEach(ProviderKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                TextField("URL base", text: $connection.baseURL)
                TextField("Modelo principal", text: $connection.defaultModel)
                TextField("Modelos (separados por comas)", text: Binding(
                    get: { connection.models.joined(separator: ", ") },
                    set: { connection.models = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
                if connection.kind.requiresKey {
                    SecureField("Clave (Llavero)", text: $secret)
                } else {
                    Text("Ollama no requiere clave.").font(.caption).foregroundStyle(.secondary)
                }
                if !connection.kind.supportsOAuth {
                    Text("OAuth no disponible para esta app.").font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack {
                Spacer()
                Button("Cancelar", action: onCancel)
                Button("Guardar") {
                    connection.baseURL = connection.baseURL.trimmingCharacters(in: .whitespaces)
                    if connection.baseURL.isEmpty { connection.baseURL = connection.kind.defaultBaseURL }
                    onSave(connection)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(connection.name.trimmingCharacters(in: .whitespaces).isEmpty || connection.defaultModel.isEmpty || connection.baseURL.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480)
    }
}
