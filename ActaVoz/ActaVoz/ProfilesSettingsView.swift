import SwiftUI

/// Ajustes de perfiles: consultar, renombrar y eliminar. No muestra audio.
struct ProfilesSettingsView: View {
    @State private var profiles: [SpeakerProfile] = []
    @State private var errorMessage: String?
    @State private var newNames: [String: String] = [:]

    private let store = SpeakerProfileStore(fileURL: StorageLocations.production().profilesFile)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Perfiles de voz")
                .font(.title2.bold())
            Text("Solo se guardan voces con nombre confirmado. Puedes renombrarlas o eliminarlas.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if profiles.isEmpty {
                ContentUnavailableView("Sin perfiles", systemImage: "person.wave.2", description: Text("Confirma un nombre en una sesión para crear un perfil."))
                    .frame(minHeight: 180)
            } else {
                List(profiles) { profile in
                    HStack {
                        TextField("Nombre", text: Binding(
                            get: { newNames[profile.id] ?? profile.name },
                            set: { newNames[profile.id] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        Button("Guardar") {
                            do {
                                try store.rename(id: profile.id, to: newNames[profile.id] ?? profile.name)
                                reload()
                            } catch { errorMessage = error.localizedDescription }
                        }
                        .disabled((newNames[profile.id] ?? profile.name) == profile.name)
                        Button(role: .destructive) {
                            do {
                                try store.delete(id: profile.id)
                                reload()
                            } catch { errorMessage = error.localizedDescription }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Actualizar") { reload() }
            }
        }
        .padding(22)
        .frame(width: 520, height: 420)
        .task { reload() }
        .alert("No se pudo completar", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Entendido", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func reload() {
        do {
            profiles = try store.load()
            newNames = [:]
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
