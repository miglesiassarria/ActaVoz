import Foundation
import SwiftUI

/// Chat de una sesión: cola serial, historial persistido y snapshot de transcripción.
@MainActor
public final class SessionChatModel: ObservableObject {
    @Published public private(set) var messages: [ChatMessage] = []
    @Published public private(set) var pendingQuestions: [String] = []
    @Published public private(set) var isResponding = false
    @Published public var errorMessage: String?
    @Published public var draft = ""
    @Published public var isPanelVisible = false

    public let folderURL: URL
    private let responder: any ChatResponding
    private let transcriptProvider: () -> String
    private var lastFailedQuestion: String?
    private var processing = false

    public init(
        folderURL: URL,
        responder: any ChatResponding,
        transcriptProvider: @escaping () -> String
    ) {
        self.folderURL = folderURL
        self.responder = responder
        self.transcriptProvider = transcriptProvider
        load()
    }

    public var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !processing
    }

    public func open() { isPanelVisible = true }
    public func close() { isPanelVisible = false }

    public func ask() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        draft = ""
        enqueue(question, transcript: transcriptProvider(), retry: false)
        processNext()
    }

    public func retry() {
        guard let question = lastFailedQuestion else { return }
        errorMessage = nil
        enqueue(question, transcript: transcriptProvider(), retry: true)
        processNext()
    }

    private struct Pending {
        var question: String
        var transcript: String
        var retry: Bool
    }

    private var queue: [Pending] = []

    private func enqueue(_ question: String, transcript: String, retry: Bool) {
        queue.append(Pending(question: question, transcript: transcript, retry: retry))
        pendingQuestions = queue.map { $0.question }
    }

    private func processNext() {
        guard !processing, queue.isEmpty == false else { return }
        processing = true
        isResponding = true
        let item = queue.removeFirst()
        pendingQuestions = queue.map { $0.question }

        if !item.retry {
            messages.append(ChatMessage(id: UUID().uuidString, role: .user, text: item.question, createdAt: Date()))
            persist()
        }

        let history = Array(messages.dropLast())
        Task { @MainActor in
            do {
                let answer = try await responder.answer(
                    transcript: item.transcript,
                    history: history,
                    question: item.question
                )
                messages.append(ChatMessage(id: UUID().uuidString, role: .assistant, text: answer, createdAt: Date()))
                lastFailedQuestion = nil
                errorMessage = nil
                persist()
                processing = false
                isResponding = false
                processNext()
            } catch {
                errorMessage = error.localizedDescription
                lastFailedQuestion = item.question
                processing = false
                isResponding = false
                persist()
            }
        }
    }

    private func load() {
        let url = folderURL.appendingPathComponent("chat.json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: url),
              let history = try? decoder.decode(ChatHistory.self, from: data) else { return }
        messages = history.messages
    }

    private func persist() {
        let history = ChatHistory(messages: messages)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(history).write(
                to: folderURL.appendingPathComponent("chat.json"),
                options: .atomic
            )
        } catch {
            errorMessage = "No se pudo guardar el chat: \(error.localizedDescription)"
        }
    }
}
