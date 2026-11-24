import Foundation

public struct SpeakerTurn: Equatable, Sendable {
    public var speakerId: String
    public var start: Double
    public var end: Double
    public var embedding: [Float]

    public init(speakerId: String, start: Double, end: Double, embedding: [Float] = []) {
        self.speakerId = speakerId
        self.start = start
        self.end = end
        self.embedding = embedding
    }
}

public protocol SpeakerDiarizing: Sendable {
    func turns(for url: URL) async throws -> [SpeakerTurn]
}

public enum SpeakerAssignment {
    /// Asigna cada intervención al hablante con más solapamiento; si no hay, al más cercano.
    public static func assign(
        utterances: [RecognizedUtterance],
        turns: [SpeakerTurn]
    ) -> [(utterance: RecognizedUtterance, speakerId: String)] {
        guard !turns.isEmpty else { return utterances.map { ($0, "system-1") } }
        return utterances.map { utterance in
            var best = turns[0]
            var bestOverlap = -Double.infinity
            for turn in turns {
                let overlap = max(0, min(utterance.end, turn.end) - max(utterance.start, turn.start))
                if overlap > bestOverlap {
                    bestOverlap = overlap
                    best = turn
                }
            }
            if bestOverlap <= 0 {
                best = turns.min { abs($0.start - utterance.start) < abs($1.start - utterance.start) } ?? turns[0]
            }
            return (utterance, best.speakerId)
        }
    }

    /// Media normalizada de los vectores de un hablante.
    public static func centroid(for speakerId: String, turns: [SpeakerTurn]) -> [Float] {
        let vectors = turns.filter { $0.speakerId == speakerId && !$0.embedding.isEmpty }.map(\.embedding)
        guard let first = vectors.first else { return [] }
        let count = Float(vectors.count)
        var sum = [Float](repeating: 0, count: first.count)
        for vector in vectors where vector.count == first.count {
            for index in vector.indices { sum[index] += vector[index] }
        }
        let mean = sum.map { $0 / count }
        let norm = sqrt(mean.reduce(0) { $0 + Double($1 * $1) })
        guard norm > 0 else { return [] }
        return mean.map { Float(Double($0) / norm) }
    }
}
