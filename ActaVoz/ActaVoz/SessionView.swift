import Foundation
import SwiftUI

/// Detalle de una sesión: cabecera editable, participantes corregibles y
/// vistas separadas de notas, resumen, chat y transcripción. Las funciones de
/// generación pertenecen a 0007–0009; aquí solo se conserva lo que existe.
struct SessionView: View {
    @ObservedObject var model: SessionModel

    var body: some View {
        Group {
            if let session = model.session {
                content(session)
            } else {
                ProgressView("Abriendo sesión…")
                    .task { model.load() }
            }
        }
        .alert("No se pudo completar", isPresented: errorBinding) {
            Button("Entendido", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .alert("Audio pendiente de decisión", isPresented: audioPromptBinding) {
            Button("Guardar audio") {
                let flow = AppBootstrap.shared.recordingFlow
                flow.beginExternalOperation()
                Task { @MainActor in
                    await model.keepPendingAudio()
                    flow.endExternalOperation(succeeded: model.errorMessage == nil)
                }
            }
            Button("Borrar audio", role: .destructive) { model.discardPendingAudio() }
        } message: {
            Text("Esta sesión cerró sin decidir si conservar el audio. Puedes guardarlo como archivo combinado o borrarlo; las notas y el texto no se tocan.")
        }
    }

    private var audioPromptBinding: Binding<Bool> {
        Binding(get: { !model.pendingAudio.isEmpty }, set: { _ in })
    }

    private func content(_ session: Session) -> some View {
        VStack(spacing: 0) {
            header(session)
            Divider()
            Picker("", selection: tabBinding) {
                ForEach(SessionModel.Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            Divider()
            body(for: session)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func header(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Título", text: titleBinding)
                .font(.largeTitle.bold())
                .textFieldStyle(.plain)

            HStack(spacing: 14) {
                Label(Self.dateFormatter.string(from: session.summary.startDate), systemImage: "calendar")
                Label("\(session.summary.metadata.participants.count) participantes", systemImage: "person.2")
                if session.summary.hasAudio {
                    Label("Audio conservado", systemImage: "waveform")
                }
                if session.summary.hasSummary {
                    Label("Resumen generado", systemImage: "text.alignleft")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if !session.summary.metadata.participants.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(session.summary.metadata.participants) { participant in
                        HStack(spacing: 8) {
                            TextField("Nombre", text: participantBinding(participant))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 170)
                            if !participant.isConfirmed {
                                Text("Sin confirmar")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Button("Confirmar") {
                                    model.confirmSpeaker(id: participant.id)
                                }
                                .font(.caption)
                            }
                            Menu("Fusionar") {
                                ForEach(session.summary.metadata.participants.filter { $0.id != participant.id }) { other in
                                    Button("Con \(other.name)") {
                                        model.mergeSpeakers(source: participant.id, into: other.id)
                                    }
                                }
                            }
                            .font(.caption)
                            .disabled(session.summary.metadata.participants.count < 2)
                        }
                        ForEach(model.nameSuggestions.filter { $0.speakerId == participant.id }) { suggestion in
                            Button("Usar «\(suggestion.name)»") {
                                model.confirmParticipant(id: participant.id, name: suggestion.name)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private func body(for session: Session) -> some View {
        switch model.tab {
        case .notes:
            TextEditor(text: notesBinding)
                .font(.body)
                .padding(8)
        case .summary:
            if session.summaryText.isEmpty {
                empty("Aún no hay resumen", "Se generará en la unidad 0008.")
            } else {
                ScrollView {
                    Text(session.summaryText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
            }
        case .chat:
            if session.chat.messages.isEmpty {
                empty("Sin preguntas todavía", "El chat de la sesión llegará en la unidad 0007.")
            } else {
                List(session.chat.messages) { message in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.role == .user ? "Pregunta" : "Respuesta")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(message.text).textSelection(.enabled)
                    }
                    .padding(.vertical, 3)
                }
            }
        case .transcript:
            if session.transcript.segments.isEmpty {
                empty("Sin transcripción", "La transcripción local llegará en la unidad 0005.")
            } else {
                List(session.transcript.segments) { segment in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(Self.time(segment.start))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(speakerName(segment.speakerId, in: session))
                                .font(.caption.bold())
                            if let source = segment.source {
                                Text(source.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(segment.text).textSelection(.enabled)
                    }
                    .padding(.vertical, 3)
                    .contextMenu {
                        Menu("Reasignar a") {
                            ForEach(session.summary.metadata.participants.filter { $0.id != segment.speakerId }) { participant in
                                Button(participant.name) {
                                    model.reassignSegment(id: segment.id, to: participant.id)
                                }
                            }
                        }
                        Menu("Fusionar interlocutor") {
                            ForEach(session.summary.metadata.participants.filter { $0.id != segment.speakerId }) { participant in
                                Button("Con \(participant.name)") {
                                    model.mergeSpeakers(source: segment.speakerId, into: participant.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func empty(_ title: String, _ description: String) -> some View {
        ContentUnavailableView(title, systemImage: "sparkles", description: Text(description))
    }

    private func speakerName(_ id: String, in session: Session) -> String {
        session.summary.metadata.participants.first(where: { $0.id == id })?.name ?? id
    }

    private static func time(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { model.session?.summary.title ?? "" },
            set: { model.saveTitle($0) }
        )
    }

    private func participantBinding(_ participant: Participant) -> Binding<String> {
        Binding(
            get: {
                model.session?.summary.metadata.participants
                    .first(where: { $0.id == participant.id })?.name ?? participant.name
            },
            set: { model.renameParticipant(id: participant.id, to: $0) }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { model.session?.notes ?? "" },
            set: { model.saveNotes($0) }
        )
    }

    private var tabBinding: Binding<SessionModel.Tab> {
        Binding(get: { model.tab }, set: { model.tab = $0 })
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}
