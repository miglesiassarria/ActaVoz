import AVFoundation
import AppKit
import SwiftUI

@MainActor
final class SessionAudioPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published var errorMessage: String?

    private var player: AVAudioPlayer?
    private var timer: Task<Void, Never>?
    let audioURL: URL

    init(folderURL: URL) {
        self.audioURL = folderURL.appendingPathComponent("audio.m4a")
        guard FileManager.default.fileExists(atPath: audioURL.path) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.prepareToPlay()
            self.player = player
            duration = player.duration
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var isAvailable: Bool { player != nil }

    var timeText: String { "\(Self.time(currentTime)) / \(Self.time(duration))" }

    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.cancel()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func seek(to value: Double) {
        guard let player else { return }
        player.currentTime = min(max(value, 0), duration)
        currentTime = player.currentTime
    }

    private func startTimer() {
        timer?.cancel()
        timer = Task { @MainActor in
            while !Task.isCancelled {
                currentTime = player?.currentTime ?? 0
                if player?.isPlaying == false { isPlaying = false; break }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    private static func time(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

struct AudioPlayerView: View {
    @ObservedObject var model: SessionAudioPlayer

    var body: some View {
        HStack(spacing: 8) {
            Button {
                model.toggle()
            } label: {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.borderless)
            Slider(value: Binding(get: { model.currentTime }, set: { model.seek(to: $0) }), in: 0...max(model.duration, 1))
                .frame(width: 160)
            Text(model.timeText).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
}

struct ExportMenu: View {
    let session: Session
    private let service = ExportService()

    var body: some View {
        Menu("Exportar") {
            ForEach(ExportContent.allCases, id: \.self) { content in
                Menu(contentLabel(content)) {
                    Button("Markdown") { export(content, format: .markdown, includeSynthesis: false) }
                    Button("Texto plano") { export(content, format: .plainText, includeSynthesis: false) }
                    if content == .notes && !session.synthesis.isEmpty {
                        Divider()
                        Button("Markdown con síntesis") { export(content, format: .markdown, includeSynthesis: true) }
                        Button("Texto plano con síntesis") { export(content, format: .plainText, includeSynthesis: true) }
                    }
                }
            }
            Divider()
            Menu("Copiar") {
                ForEach(ExportContent.allCases, id: \.self) { content in
                    Button(contentLabel(content)) { copy(content) }
                }
            }
        }
    }

    private func contentLabel(_ content: ExportContent) -> String {
        switch content {
        case .transcript: return "Transcripción"
        case .summary: return "Resumen"
        case .notes: return "Notas"
        }
    }

    private func export(_ content: ExportContent, format: ExportFormat, includeSynthesis: Bool) {
        let text = service.render(content, session: session, format: format, includeSynthesis: includeSynthesis)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = service.suggestedFilename(content, title: session.summary.title, format: format)
        panel.allowedContentTypes = []
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func copy(_ content: ExportContent) {
        let text = service.render(content, session: session, format: .plainText, includeSynthesis: false)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
