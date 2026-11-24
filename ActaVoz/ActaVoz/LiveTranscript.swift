import AVFoundation
import SwiftUI

/// Vista previa en directo: escribe fragmentos de 2 s y los transcribe localmente.
/// El resultado definitivo se recalcula al cerrar la captura.
@MainActor
final class LiveTranscriptModel: ObservableObject {
    @Published private(set) var text = ""
    @Published var isVisible = false
    @Published var errorMessage: String?

    private var active = false
    private var language: SessionLanguage = .spanish
    private var converter: AVAudioConverter?
    private var targetFormat: AVAudioFormat?
    private var writer: AVAudioFile?
    private var chunkURL: URL?
    private var chunkFrames: AVAudioFramePosition = 0
    private var appendBuffer = ""
    private let chunkTargetFrames: AVAudioFramePosition = 32_000 // 2 s a 16 kHz

    func begin(language: SessionLanguage) {
        guard !active else { return }
        active = true
        isVisible = true
        self.language = language
        text = "Escuchando…"
        appendBuffer = ""
        converter = nil
        targetFormat = nil
        writer = nil
        chunkFrames = 0
    }

    func consume(_ buffer: AVAudioPCMBuffer, source: CaptureSource) {
        guard active else { return }
        if converter == nil {
            guard let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false),
                  let created = AVAudioConverter(from: buffer.format, to: target) else {
                errorMessage = "No se pudo preparar el audio en directo."
                active = false
                return
            }
            targetFormat = target
            converter = created
            openChunk()
        }
        guard let converter, let targetFormat else { return }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 4096
        guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }
        var conversionError: NSError?
        var supplied = false
        let status = converter.convert(to: converted, error: &conversionError) { _, outStatus in
            if supplied {
                outStatus.pointee = .noDataNow
                return nil
            }
            supplied = true
            outStatus.pointee = .haveData
            return buffer
        }
        if status == .error {
            errorMessage = conversionError?.localizedDescription
            return
        }
        guard converted.frameLength > 0 else { return }
        do {
            try writer?.write(from: converted)
            chunkFrames += AVAudioFramePosition(converted.frameLength)
            if chunkFrames >= chunkTargetFrames { flushChunk() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openChunk() {
        guard active, let targetFormat else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-live-\(UUID().uuidString).caf")
        do {
            writer = try AVAudioFile(forWriting: url, settings: targetFormat.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            chunkURL = url
            chunkFrames = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func flushChunk() {
        writer = nil
        guard let url = chunkURL else { return }
        chunkURL = nil
        chunkFrames = 0
        let language = self.language
        Task { [weak self] in
            let result = try? await LocalSpeechRecognizer().transcribe(url: url, language: language)
            try? FileManager.default.removeItem(at: url)
            guard let self, let result else { return }
            let fragment = result.utterances.map(\.text).joined(separator: " ")
            await MainActor.run {
                guard !fragment.isEmpty else { return }
                self.appendBuffer += fragment + " "
                self.text = self.appendBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if active { openChunk() }
    }

    func finish() {
        guard active else { return }
        active = false
        if writer != nil { flushChunk() }
        writer = nil
        converter = nil
        targetFormat = nil
    }

    func close() {
        isVisible = false
    }
}
