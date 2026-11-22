import Foundation
import Speech
import AVFoundation
@main struct Prueba {
 static func main() async throws {
  let audio = try AVAudioFile(forReading: URL(fileURLWithPath: CommandLine.arguments[1]))
  let idioma = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "es_ES"
  let transcriptor = SpeechTranscriber(locale: Locale(identifier: idioma), preset: .transcription)
  print("recursos antes:", await AssetInventory.status(forModules: [transcriptor]))
  if CommandLine.arguments.contains("--instalar"), let descarga = try await AssetInventory.assetInstallationRequest(supporting: [transcriptor]) {
   try await descarga.downloadAndInstall()
  }
  print("recursos después:", await AssetInventory.status(forModules: [transcriptor]))
  let analizador = SpeechAnalyzer(modules: [transcriptor])
  let lector = Task {
   for try await resultado in transcriptor.results {
    print("resultado:", String(resultado.text.characters))
   }
  }
  try await analizador.start(inputAudioFile: audio, finishAfterFile: true)
  try await lector.value
 }
}
