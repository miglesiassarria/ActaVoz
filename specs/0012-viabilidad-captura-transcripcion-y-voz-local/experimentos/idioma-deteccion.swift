import AVFoundation
import Foundation
import NaturalLanguage
import Speech

@main struct DeteccionIdioma {
    static func transcribir(_ url: URL, _ locale: String) async throws -> String {
        let t = SpeechTranscriber(locale: Locale(identifier: locale), preset: .transcription)
        let analyzer = SpeechAnalyzer(modules: [t])
        let file = try AVAudioFile(forReading: url)
        var text = ""
        let reader = Task {
            for try await result in t.results { text += String(result.text.characters) }
        }
        try await analyzer.start(inputAudioFile: file, finishAfterFile: true)
        try await reader.value
        return text
    }

    static func main() async throws {
        let audio = URL(fileURLWithPath: CommandLine.arguments[1])
        for locale in ["es_ES", "en_US"] {
            let text = try await transcribir(audio, locale)
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)
            let language = recognizer.dominantLanguage?.rawValue ?? "?"
            let confidence = recognizer.languageHypotheses(withMaximum: 1).first?.value ?? 0
            print(String(format: "locale=%@ detectado=%@ confianza=%.3f texto=%@", locale, language, confidence, text))
        }
    }
}
