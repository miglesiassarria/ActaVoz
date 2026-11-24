import AVFoundation
import CoreMedia
import Foundation
import NaturalLanguage
import Speech

public struct RecognizedUtterance: Equatable, Sendable {
    public var text: String
    public var start: Double
    public var end: Double

    public init(text: String, start: Double, end: Double) {
        self.text = text
        self.start = start
        self.end = end
    }
}

public enum SpeechRecognitionError: Error, LocalizedError, Equatable {
    case unavailable
    case resourcesNotInstalled(String)
    case cannotReadAudio(URL)
    case emptyAudio
    case noSpeech

    public var errorDescription: String? {
        switch self {
        case .unavailable: return "El reconocimiento de voz local no está disponible en este Mac."
        case .resourcesNotInstalled(let locale): return "Faltan los recursos de voz para «\(locale)». Instálalos y vuelve a intentarlo."
        case .cannotReadAudio(let url): return "No se pudo leer el audio «\(url.lastPathComponent)»."
        case .emptyAudio: return "El audio está vacío."
        case .noSpeech: return "No se detectó voz en el audio."
        }
    }
}

extension SessionLanguage {
    public var localeIdentifier: String {
        switch self {
        case .spanish: return "es_ES"
        case .english: return "en_US"
        case .automatic: return "es_ES"
        }
    }
}

/// Transcripción local de un archivo. Respeta el locale y no envía audio fuera del Mac.
private final class UtteranceCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var utterances: [RecognizedUtterance] = []

    func append(_ utterance: RecognizedUtterance) {
        lock.lock(); defer { lock.unlock() }
        utterances.append(utterance)
    }

    func snapshot() -> [RecognizedUtterance] {
        lock.lock(); defer { lock.unlock() }
        return utterances
    }
}

public protocol SpeechRecognizing: Sendable {
    func transcribe(url: URL, language: SessionLanguage) async throws -> (language: SessionLanguage, utterances: [RecognizedUtterance])
}

public struct LocalSpeechRecognizer: SpeechRecognizing {
    public init() {}

    public func transcribe(url: URL, language: SessionLanguage) async throws -> (language: SessionLanguage, utterances: [RecognizedUtterance]) {
        guard SpeechTranscriber.isAvailable else { throw SpeechRecognitionError.unavailable }
        let prepared = try prepareAudio(url)
        defer { try? FileManager.default.removeItem(at: prepared) }

        switch language {
        case .spanish, .english:
            let utterances = try await transcribeFile(prepared, locale: language.localeIdentifier)
            guard !utterances.isEmpty else { throw SpeechRecognitionError.noSpeech }
            return (language, utterances)
        case .automatic:
            let spanish = try await transcribeFile(prepared, locale: SessionLanguage.spanish.localeIdentifier)
            let english = try await transcribeFile(prepared, locale: SessionLanguage.english.localeIdentifier)
            let chosen = choose(spanish: spanish, english: english)
            guard !chosen.utterances.isEmpty else { throw SpeechRecognitionError.noSpeech }
            return chosen
        }
    }

    private func transcribeFile(_ url: URL, locale: String) async throws -> [RecognizedUtterance] {
        let transcriber = SpeechTranscriber(
            locale: Locale(identifier: locale),
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: [.audioTimeRange]
        )
        let status = await AssetInventory.status(forModules: [transcriber])
        guard status != .unsupported else {
            throw SpeechRecognitionError.resourcesNotInstalled(locale)
        }
        if status != .installed, let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch {
            throw SpeechRecognitionError.cannotReadAudio(url)
        }
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let collector = UtteranceCollector()
        let reader = Task {
            for try await result in transcriber.results where result.isFinal {
                let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                let start = CMTimeGetSeconds(result.range.start)
                let end = CMTimeGetSeconds(CMTimeRangeGetEnd(result.range))
                collector.append(RecognizedUtterance(text: text, start: max(0, start), end: max(start, end)))
            }
        }
        try await analyzer.start(inputAudioFile: file, finishAfterFile: true)
        try await reader.value
        return collector.snapshot().sorted { $0.start < $1.start }
    }

    private func choose(
        spanish: [RecognizedUtterance],
        english: [RecognizedUtterance]
    ) -> (language: SessionLanguage, utterances: [RecognizedUtterance]) {
        let spanishText = spanish.map(\.text).joined(separator: " ")
        let englishText = english.map(\.text).joined(separator: " ")
        let spanishLanguage = detect(spanishText)
        let englishLanguage = detect(englishText)
        let spanishScore = score(text: spanishText, language: "es", detected: spanishLanguage)
        let englishScore = score(text: englishText, language: "en", detected: englishLanguage)
        if englishScore > spanishScore {
            return (.english, english)
        }
        return (.spanish, spanish)
    }

    private func detect(_ text: String) -> (code: String, confidence: Double)? {
        guard !text.isEmpty else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        let confidence = recognizer.languageHypotheses(withMaximum: 1).first?.value ?? 0
        return (language.rawValue, confidence)
    }

    private func score(text: String, language: String, detected: (code: String, confidence: Double)?) -> Double {
        guard let detected else { return 0 }
        let base = detected.code.hasPrefix(language) ? detected.confidence : 0.1
        return base + min(Double(text.count), 400) / 10_000
    }

    /// Convierte a 16 kHz mono Float32 en un CAF temporal para el reconocedor.
    private func prepareAudio(_ url: URL) throws -> URL {
        let source: AVAudioFile
        do {
            source = try AVAudioFile(forReading: url)
        } catch {
            throw SpeechRecognitionError.cannotReadAudio(url)
        }
        guard source.length > 0 else { throw SpeechRecognitionError.emptyAudio }
        let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false)!
        if source.processingFormat.sampleRate == target.sampleRate,
           source.processingFormat.channelCount == 1,
           source.processingFormat.commonFormat == .pcmFormatFloat32 {
            return url
        }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("actavoz-speech-\(UUID().uuidString).caf")
        let output = try AVAudioFile(forWriting: destination, settings: target.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        guard let converter = AVAudioConverter(from: source.processingFormat, to: target) else {
            throw SpeechRecognitionError.cannotReadAudio(url)
        }
        let frames = AVAudioFrameCount(source.length)
        guard frames > 0, let input = AVAudioPCMBuffer(pcmFormat: source.processingFormat, frameCapacity: frames) else {
            throw SpeechRecognitionError.emptyAudio
        }
        do {
            try source.read(into: input)
        } catch let error as NSError where error.code == -39 {
            // El archivo puede terminar antes del último frame teórico.
        }
        guard input.frameLength > 0 else { throw SpeechRecognitionError.emptyAudio }
        let ratio = target.sampleRate / source.processingFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(input.frameLength) * ratio) + 4096
        guard let converted = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else {
            throw SpeechRecognitionError.emptyAudio
        }
        var conversionError: NSError?
        var supplied = false
        let status = converter.convert(to: converted, error: &conversionError) { _, outStatus in
            if supplied {
                outStatus.pointee = .endOfStream
                return nil
            }
            supplied = true
            outStatus.pointee = .haveData
            return input
        }
        if status == .error { throw conversionError ?? SpeechRecognitionError.cannotReadAudio(url) }
        guard converted.frameLength > 0 else { throw SpeechRecognitionError.emptyAudio }
        try output.write(from: converted)
        return destination
    }
}
