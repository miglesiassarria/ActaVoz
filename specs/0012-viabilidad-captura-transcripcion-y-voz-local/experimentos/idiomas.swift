import Foundation
import Speech
@main struct Probe {
 static func main() async {
  print("available=\(SpeechTranscriber.isAvailable)")
  let supported = await SpeechTranscriber.supportedLocales.map(\.identifier).sorted()
  let installed = await SpeechTranscriber.installedLocales.map(\.identifier).sorted()
  print("supported_es_en=\(supported.filter { $0.hasPrefix("es") || $0.hasPrefix("en") })")
  print("installed_es_en=\(installed.filter { $0.hasPrefix("es") || $0.hasPrefix("en") })")
 }
}
