import SwiftUI

struct ChatBar: View {
    @ObservedObject var model: SessionChatModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .foregroundStyle(.secondary)
            Button(model.isPanelVisible ? "Ocultar chat" : "Preguntar") {
                if model.isPanelVisible { model.close() } else { model.open() }
            }
            .buttonStyle(.borderedProminent)
            if !model.pendingQuestions.isEmpty {
                Text("\(model.pendingQuestions.count) en espera")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct ChatOverlay: View {
    @ObservedObject var model: SessionChatModel
    var onConfigureProvider: () -> Void = {}

    var body: some View {
        if model.isPanelVisible {
            ZStack(alignment: .bottomTrailing) {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { model.close() }
                ChatPanel(model: model, onConfigureProvider: onConfigureProvider)
                    .padding(16)
            }
        }
    }
}

struct ChatPanel: View {
    @ObservedObject var model: SessionChatModel
    var onConfigureProvider: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Preguntar a la reunión").font(.headline)
                Spacer()
                Button {
                    model.close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cerrar el chat")
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if model.messages.isEmpty && model.pendingQuestions.isEmpty {
                            Text("Pregunta lo que quieras sobre lo transcrito. No se envían archivos ni audio.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(model.messages) { message in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(message.role == .user ? "Tú" : "ActaVoz")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(message.text)
                                    .textSelection(.enabled)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(message.role == .user ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .id(message.id)
                        }
                        ForEach(model.pendingQuestions, id: \.self) { question in
                            Text("En espera: \(question)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if model.isResponding {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Pensando…").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(4)
                }
                .onChange(of: model.messages.count) { _, _ in
                    if let last = model.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            .frame(minHeight: 220, maxHeight: 340)

            if let error = model.errorMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.orange)
                    HStack {
                        Button("Reintentar") { model.retry() }
                        Button("Cambiar modelo") { onConfigureProvider() }
                    }
                }
            }

            HStack(spacing: 6) {
                TextField("Escribe una pregunta…", text: $model.draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { model.ask() }
                Button("Enviar") { model.ask() }
                    .disabled(!model.canSend)
            }
            Text("Solo se envía texto; el audio permanece en este Mac.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: 390, height: 470)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 12)
    }
}
