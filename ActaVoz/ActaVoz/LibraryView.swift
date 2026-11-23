import SwiftUI

/// Biblioteca: barra lateral con «Sin organizar» y directorios, lista central
/// agrupada por fecha y detalle de la sesión. El botón «Nueva nota» queda fijo
/// abajo a la derecha y delega en el flujo de grabación.
struct LibraryView: View {
    @ObservedObject var model: LibraryModel
    var onNewNote: () -> Void = {}

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } content: {
            sessionColumn
                .navigationSplitViewColumnWidth(min: 260, ideal: 330)
        } detail: {
            detailColumn
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: onNewNote) {
                Label("Nueva nota", systemImage: "record.circle")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.borderedProminent)
            .padding(20)
            .help("Inicia el flujo de grabación")
        }
        .task { model.reload() }
    }

    // MARK: - Barra lateral

    private var sidebar: some View {
        List {
            Label("Sin organizar", systemImage: "tray")
                .padding(.vertical, 3)
                .listRowBackground(highlight(model.selection == .inbox))
                .onTapGesture { model.select(.inbox) }

            Section("Directorios") {
                ForEach(model.directories, id: \.self) { name in
                    Label(name, systemImage: "folder")
                        .padding(.vertical, 3)
                        .listRowBackground(highlight(model.selection == .directory(name)))
                        .onTapGesture { model.select(.directory(name)) }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                model.isNamingDirectory = true
            } label: {
                Label("Nuevo directorio", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .sheet(isPresented: namingBinding) {
            newDirectorySheet
        }
    }

    private var newDirectorySheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nuevo directorio")
                .font(.headline)
            TextField("Nombre", text: newDirectoryBinding)
                .textFieldStyle(.roundedBorder)
                .onSubmit { model.createDirectory() }
            HStack {
                Spacer()
                Button("Cancelar") {
                    model.isNamingDirectory = false
                    model.newDirectoryName = ""
                }
                Button("Crear") { model.createDirectory() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.newDirectoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    // MARK: - Lista de sesiones

    private var sessionColumn: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar en la biblioteca", text: queryBinding)
                    .textFieldStyle(.plain)
                if !model.query.isEmpty {
                    Button {
                        model.updateQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            Divider()

            if model.sessions.isEmpty {
                ContentUnavailableView(
                    model.query.isEmpty ? "Sin sesiones" : "Sin resultados",
                    systemImage: model.query.isEmpty ? "square.stack" : "magnifyingglass",
                    description: Text(model.query.isEmpty
                        ? "Las notas y reuniones aparecerán aquí."
                        : "Prueba con otro término.")
                )
            } else {
                List {
                    ForEach(model.groups, id: \.day) { group in
                        Section(header: Text(Self.dayFormatter.string(from: group.day))) {
                            ForEach(group.sessions) { session in
                                sessionRow(session)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .toolbar {
            if let name = model.selectedDirectoryName {
                ToolbarItemGroup {
                    Text(name)
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        model.requestDeleteDirectory()
                    } label: {
                        Label("Eliminar directorio", systemImage: "trash")
                    }
                }
            }
            if model.selectedSession != nil {
                ToolbarItemGroup {
                    Button(role: .destructive) {
                        model.requestDeleteSession()
                    } label: {
                        Label("Eliminar sesión", systemImage: "trash")
                    }
                    Menu {
                        Button("Sin organizar") { model.moveSelectedSession(to: .inbox) }
                        Divider()
                        ForEach(model.directories, id: \.self) { name in
                            Button(name) { model.moveSelectedSession(to: .directory(name)) }
                        }
                    } label: {
                        Label("Mover a", systemImage: "folder.badge.plus")
                    }
                    .disabled(model.directories.isEmpty && model.selection == .inbox)
                }
            }
        }
        .alert("Eliminar", isPresented: deletionBinding) {
            Button("Cancelar", role: .cancel) { model.cancelDeletion() }
            Button("Eliminar", role: .destructive) { model.confirmDeletion() }
        } message: {
            Text(deletionMessage)
        }
    }

    private func sessionRow(_ session: SessionSummary) -> some View {
        Button {
            model.selectedSession = session
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(Self.timeFormatter.string(from: session.startDate))
                    if session.hasAudio {
                        Image(systemName: "waveform")
                    }
                    if session.hasSummary {
                        Image(systemName: "text.alignleft")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .listRowBackground(highlight(model.selectedSession?.id == session.id))
    }

    // MARK: - Detalle

    private var detailColumn: some View {
        Group {
            if let selected = model.selectedSession {
                SessionView(model: SessionModel(repository: model.repository, folderURL: selected.folderURL))
                    .id(selected.id)
            } else {
                ContentUnavailableView(
                    "Selecciona una sesión",
                    systemImage: "rectangle.on.rectangle",
                    description: Text("Elige una nota para ver sus notas, resumen y chat.")
                )
            }
        }
        .frame(minWidth: 520, minHeight: 400)
    }

    // MARK: - Auxiliares

    private var queryBinding: Binding<String> {
        Binding(get: { model.query }, set: { model.updateQuery($0) })
    }

    private var newDirectoryBinding: Binding<String> {
        Binding(get: { model.newDirectoryName }, set: { model.newDirectoryName = $0 })
    }

    private var namingBinding: Binding<Bool> {
        Binding(get: { model.isNamingDirectory }, set: { model.isNamingDirectory = $0 })
    }

    private var deletionBinding: Binding<Bool> {
        Binding(get: { model.deletion != nil }, set: { if !$0 { model.deletion = nil } })
    }

    private var deletionMessage: String {
        switch model.deletion {
        case .session(let session):
            return "Se borrarán el audio conservado, la transcripción y todos los resultados de «\(session.title)». No se puede deshacer."
        case .directory(let name):
            return "Se borrarán el directorio «\(name)» y todas las sesiones que contiene. No se puede deshacer."
        case .none:
            return ""
        }
    }

    private func highlight(_ active: Bool) -> Color {
        active ? Color.accentColor.opacity(0.18) : Color.clear
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
