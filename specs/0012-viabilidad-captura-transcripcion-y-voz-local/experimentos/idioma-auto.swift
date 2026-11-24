import AVFoundation
import Foundation
import Speech

@main struct AutoIdioma {
    static func transcribir(_ url: URL, _ locale: String) async throws -> (String, Double) {
        let t = SpeechTranscriber(locale: Locale(identifier: locale), transcriptionOptions: [],
                                  reportingOptions: [.volatileResults],
                                  attributeOptions: [.transcriptionConfidence])
        let analyzer = SpeechAnalyzer(modules: [t])
        let file = try AVAudioFile(forReading: url)
        var text = ""
        var confidences: [Double] = []
        let reader = Task {
            for try await result in t.results {
                text += String(result.text.characters)
                for run in result.text.runs {
                    if let value = run[AttributeScopes.Speech.SpeechAttributes.TranscriptionConfidenceAttribute.self] {
                        confidences.append(value)
                    }
                }
            }
        }
        try await analyzer.start(inputAudioFile: file, finishAfterFile: true)
        try await reader.value
        let mean = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Double(confidences.count)
        return (text, mean)
    }

    static func main() async throws {
        let audio = URL(fileURLWithPath: CommandLine.arguments[1])
        for locale in ["es_ES", "en_US"] {
            let (text, confidence) = try await transcribir(audio, locale)
            print(String(format: "%@ confidence=%.4f text=%@", locale, confidence, text))
        }
    }
}
