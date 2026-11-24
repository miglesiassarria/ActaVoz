import AVFoundation
import Speech
import SwiftUI

/// Vista previa en directo. Si el sistema no ofrece el conversor de entrada,
/// se desactiva en vez de arriesgar un formato incompatible.
@MainActor
final class LiveTranscriptModel: ObservableObject {
    @Published private(set) var text = ""
    @Published var isVisible = false
    @Published var errorMessage: String?

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var continuation: AsyncStream<AnalyzerInput>.Continuation?
    private var converter: AnyObject?
    private var reader: Task<Void, Never>?
    private var finalText = ""
    private var volatileText = ""
    private var active = false

    func begin(language: SessionLanguage) {
        guard !active else { return }
        guard #available(macOS 27, *) else {
            errorMessage = "La vista previa en directo requiere macOS 27; la transcripción final sigue disponible."
            isVisible = false
            return
        }
        active = true
        isVisible = true
        finalText = ""
        volatileText = ""
        text = "Escuchando…"
        let locale = language == .english ? "en_US" : "es_ES"
        let transcriber = SpeechTranscriber(locale: Locale(identifier: locale), preset: .progressiveTranscription)
        self.transcriber = transcriber
        let stream = AsyncStream<AnalyzerInput> { continuation in
            self.continuation = continuation
        }
        let analyzer = SpeechAnalyzer(inputSequence: stream, modules: [transcriber])
        self.analyzer = analyzer
        reader = Task { [weak self] in
            guard let self else { return }
            do {
                for try await result in transcriber.results {
                    let value = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
                    await MainActor.run {
                        guard !value.isEmpty else { return }
                        if result.isFinal {
                            self.finalText += value + " "
                        } else {
                            self.volatileText = value
                        }
                        self.text = (self.finalText + self.volatileText).trimmingCharacters(in: .whitespacesAndNewlines)
                        if self.text.isEmpty { self.text = "Escuchando…" }
                    }
                }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription }
            }
        }
        Task { [weak self] in
            do {
                try await analyzer.start(inputSequence: stream)
            } catch {
                await MainActor.run { self?.errorMessage = error.localizedDescription }
            }
        }
        Task { [weak self] in
            do {
                let started = try await AnalyzerInputConverter.converter(compatibleWith: [transcriber])
                await MainActor.run { self?.converter = started }
            } catch {
                await MainActor.run {
                    self?.errorMessage = error.localizedDescription
                    self?.active = false
                    self?.isVisible = false
                }
            }
        }
    }

    func consume(_ buffer: AVAudioPCMBuffer, source: CaptureSource) {
        guard active, #available(macOS 27, *), let continuation,
              let converter = converter as? AnalyzerInputConverter else { return }
        do {
            for input in try converter.convert(buffer, at: nil) {
                continuation.yield(input)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func finish() {
        guard active else { return }
        active = false
        continuation?.finish()
        continuation = nil
        reader?.cancel()
        reader = nil
        let analyzer = self.analyzer
        Task {
            try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        }
        self.analyzer = nil
        converter = nil
        transcriber = nil
    }

    func close() {
        isVisible = false
    }
}
