import Foundation

public enum TranscriptEditingError: Error, LocalizedError, Equatable {
    case segmentNotFound(String)
    case participantNotFound(String)
    case sameSpeaker

    public var errorDescription: String? {
        switch self {
        case .segmentNotFound(let id): return "No se encontró la intervención «\(id)»."
        case .participantNotFound(let id): return "No se encontró el interlocutor «\(id)»."
        case .sameSpeaker: return "Los interlocutores ya son el mismo."
        }
    }
}

/// Sugerencia local de nombre a partir de una pista explícita en el texto.
public struct NameSuggestion: Equatable, Sendable, Identifiable {
    public var id: String { "\(speakerId):\(name)" }
    public var speakerId: String
    public var name: String
    public var evidence: String
    public var confidence: Double

    public init(speakerId: String, name: String, evidence: String, confidence: Double) {
        self.speakerId = speakerId
        self.name = name
        self.evidence = evidence
        self.confidence = confidence
    }
}

/// Operaciones explícitas sobre la atribución. No cambian audio ni texto.
public enum TranscriptEditor {
    @discardableResult
    public static func rename(speakerId: String, to rawName: String, in session: Session) throws -> Session {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw TranscriptEditingError.participantNotFound(speakerId) }
        var updated = session
        var participants = updated.summary.metadata.participants
        if let index = participants.firstIndex(where: { $0.id == speakerId }) {
            participants[index].name = name
            participants[index].isConfirmed = true
        } else {
            participants.append(Participant(id: speakerId, name: name, isConfirmed: true))
        }
        updated.summary.metadata.participants = participants
        return updated
    }

    @discardableResult
    public static func confirm(speakerId: String, in session: Session) throws -> Session {
        var updated = session
        guard let index = updated.summary.metadata.participants.firstIndex(where: { $0.id == speakerId }) else {
            throw TranscriptEditingError.participantNotFound(speakerId)
        }
        updated.summary.metadata.participants[index].isConfirmed = true
        return updated
    }

    @discardableResult
    public static func reassign(segmentId: String, to speakerId: String, in session: Session) throws -> Session {
        var updated = session
        guard let index = updated.transcript.segments.firstIndex(where: { $0.id == segmentId }) else {
            throw TranscriptEditingError.segmentNotFound(segmentId)
        }
        if !updated.summary.metadata.participants.contains(where: { $0.id == speakerId }) {
            updated.summary.metadata.participants.append(Participant(id: speakerId, name: speakerId))
        }
        updated.transcript.segments[index].speakerId = speakerId
        return updated
    }

    /// Fusiona `source` en `target`: mueve sus intervenciones y elimina el interlocutor origen.
    @discardableResult
    public static func merge(source: String, into target: String, in session: Session) throws -> Session {
        guard source != target else { throw TranscriptEditingError.sameSpeaker }
        var updated = session
        var participants = updated.summary.metadata.participants
        guard let sourceIndex = participants.firstIndex(where: { $0.id == source }) else {
            throw TranscriptEditingError.participantNotFound(source)
        }
        guard let targetIndex = participants.firstIndex(where: { $0.id == target }) else {
            throw TranscriptEditingError.participantNotFound(target)
        }
        let sourceParticipant = participants[sourceIndex]
        let targetParticipant = participants[targetIndex]
        for index in updated.transcript.segments.indices where updated.transcript.segments[index].speakerId == source {
            updated.transcript.segments[index].speakerId = target
        }
        participants[targetIndex].isConfirmed = targetParticipant.isConfirmed || sourceParticipant.isConfirmed
        participants[targetIndex].profileID = targetParticipant.profileID ?? sourceParticipant.profileID
        if participants[targetIndex].name.trimmingCharacters(in: .whitespaces).isEmpty {
            participants[targetIndex].name = sourceParticipant.name
        }
        participants.remove(at: sourceIndex)
        updated.summary.metadata.participants = participants
        return updated
    }

    /// Ordena los segmentos por tiempo de sesión y elimina ids duplicados.
    public static func normalized(_ transcript: Transcript) -> Transcript {
        var seen = Set<String>()
        let segments = transcript.segments
            .sorted { ($0.start, $0.end) < ($1.start, $1.end) }
            .filter { seen.insert($0.id).inserted }
        var copy = transcript
        copy.segments = segments
        return copy
    }
}

/// Heurística local y acotada: solo propone nombres con una frase explícita.
public enum NameDeducer {
    private static let stopWords: Set<String> = [
        "el", "la", "los", "las", "un", "una", "de", "del", "que", "y", "o", "en", "con", "por", "para",
        "the", "a", "an", "of", "and", "or", "in", "with", "for", "this", "that", "it", "we", "you"
    ]

    private static let patterns: [(String, Double)] = [
        (#"(?:me llamo|mi nombre es)\s+(\p{Lu}\p{L}{1,30})"#, 0.95),
        (#"(?:soy)\s+(\p{Lu}\p{L}{1,30})"#, 0.70),
        (#"(\p{Lu}\p{L}{1,30})\s+al habla"#, 0.85),
        (#"(?:my name is|i am|i'm)\s+(\p{Lu}\p{L}{1,30})"#, 0.95),
        (#"this is\s+(\p{Lu}\p{L}{1,30})"#, 0.80)
    ]

    public static func suggestions(in transcript: Transcript) -> [NameSuggestion] {
        var bySpeaker: [String: [NameSuggestion]] = [:]
        for segment in transcript.segments {
            for suggestion in suggestions(in: segment.text, speakerId: segment.speakerId) {
                bySpeaker[segment.speakerId, default: []].append(suggestion)
            }
        }
        return bySpeaker.values.compactMap { list in
            let grouped = Dictionary(grouping: list, by: \.name)
            guard let (name, matches) = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
            let confidence = min(0.99, (matches.map(\.confidence).max() ?? 0) + Double(max(0, matches.count - 1)) * 0.03)
            return NameSuggestion(
                speakerId: matches[0].speakerId,
                name: name,
                evidence: matches[0].evidence,
                confidence: confidence
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public static func suggestions(in text: String, speakerId: String) -> [NameSuggestion] {
        var result: [NameSuggestion] = []
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for (pattern, confidence) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            for match in regex.matches(in: text, range: range) {
                guard match.numberOfRanges > 1,
                      let nameRange = Range(match.range(at: 1), in: text) else { continue }
                let name = String(text[nameRange])
                let normalized = name.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
                guard normalized.count >= 2, normalized.count <= 30,
                      !stopWords.contains(normalized.lowercased()) else { continue }
                result.append(NameSuggestion(
                    speakerId: speakerId,
                    name: normalized,
                    evidence: String(text[Range(match.range, in: text)!]),
                    confidence: confidence
                ))
            }
        }
        return result
    }
}
