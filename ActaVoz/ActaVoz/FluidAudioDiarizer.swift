import FluidAudio
import Foundation

/// Adaptador local de FluidAudio. Los modelos se descargan una vez y quedan en caché.
struct FluidAudioDiarizer: SpeakerDiarizing {
    func turns(for url: URL) async throws -> [SpeakerTurn] {
        let manager = OfflineDiarizerManager()
        try await manager.prepareModels()
        let result = try await manager.process(url)
        return result.segments.map {
            SpeakerTurn(
                speakerId: $0.speakerId,
                start: Double($0.startTimeSeconds),
                end: Double($0.endTimeSeconds),
                embedding: $0.embedding
            )
        }
    }
}
