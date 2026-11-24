import Foundation

public struct SessionProcessingOptions: Equatable, Sendable {
    public var language: SessionLanguage
    public var savesVoiceProfiles: Bool
    public var labelsMicrophoneAsMe: Bool

    public init(language: SessionLanguage = .spanish, savesVoiceProfiles: Bool = true, labelsMicrophoneAsMe: Bool = true) {
        self.language = language
        self.savesVoiceProfiles = savesVoiceProfiles
        self.labelsMicrophoneAsMe = labelsMicrophoneAsMe
    }
}

public struct SessionProcessingResult: Sendable {
    public var session: Session
    public var warnings: [String]

    public init(session: Session, warnings: [String]) {
        self.session = session
        self.warnings = warnings
    }
}

/// Procesa los CAF de una sesión: micrófono, ASR local, diarización y perfiles.
public struct SessionProcessingService {
    public var repository: SessionRepository
    public var recognizer: any SpeechRecognizing
    public var diarizer: any SpeakerDiarizing
    public var profileStore: SpeakerProfileStore

    public init(
        repository: SessionRepository,
        diarizer: any SpeakerDiarizing,
        profileStore: SpeakerProfileStore,
        recognizer: any SpeechRecognizing = LocalSpeechRecognizer()
    ) {
        self.repository = repository
        self.diarizer = diarizer
        self.profileStore = profileStore
        self.recognizer = recognizer
    }

    public func process(folder: URL, options: SessionProcessingOptions) async throws -> SessionProcessingResult {
        var session = try repository.loadSession(at: folder)
        let temporaryStore = TemporaryVoiceStore(sessionFolder: folder)
        let files = try sourceFiles(in: folder)
        var warnings: [String] = []
        var segments: [TranscriptSegment] = []
        var participants: [Participant] = []
        var usedLanguage = session.transcript.language
        var nextSegment = 0
        var nextNeutral = 1

        for file in files {
            let recognized: (language: SessionLanguage, utterances: [RecognizedUtterance])
            do {
                recognized = try await recognizer.transcribe(url: file.url, language: options.language)
            } catch {
                warnings.append("\(file.url.lastPathComponent): \(error.localizedDescription)")
                continue
            }
            usedLanguage = recognized.language
            let spans = file.spans
            switch file.source {
            case .microphone:
                let speakerId: String
                let name: String
                let confirmed: Bool
                if options.labelsMicrophoneAsMe {
                    speakerId = "me"
                    name = "Yo"
                    confirmed = true
                } else {
                    speakerId = "mic-1"
                    name = "Micrófono"
                    confirmed = false
                }
                if !participants.contains(where: { $0.id == speakerId }) {
                    participants.append(Participant(id: speakerId, name: name, isConfirmed: confirmed))
                }
                for utterance in recognized.utterances {
                    for mapped in Self.map(start: utterance.start, end: utterance.end, spans: spans) {
                        nextSegment += 1
                        segments.append(TranscriptSegment(
                            id: String(format: "seg-%04d", nextSegment),
                            start: mapped.start,
                            end: mapped.end,
                            speakerId: speakerId,
                            text: utterance.text,
                            source: .microphone
                        ))
                    }
                }
            case .system:
                var turns: [SpeakerTurn] = []
                do {
                    turns = try await diarizer.turns(for: file.url)
                } catch {
                    warnings.append("Diarización \(file.url.lastPathComponent): \(error.localizedDescription)")
                }
                let assignments = SpeakerAssignment.assign(utterances: recognized.utterances, turns: turns)
                let speakerIds = Set(turns.map(\.speakerId)).sorted()
                for victim in speakerIds {
                    let localId = "\(file.source.rawValue)-\(victim)"
                    if participants.contains(where: { $0.id == localId }) { continue }
                    let embedding = SpeakerAssignment.centroid(for: victim, turns: turns)
                    var participant = Participant(id: localId, name: "Interlocutor \(nextNeutral)")
                    nextNeutral += 1
                    if options.savesVoiceProfiles, !embedding.isEmpty {
                        try? temporaryStore.save(speakerId: localId, embedding: embedding)
                        if let match = try? profileStore.match(embedding: embedding) {
                            participant.name = match.profile.name
                            participant.profileID = match.profile.id
                        }
                    }
                    participants.append(participant)
                }
                for assignment in assignments {
                    let speakerId = "\(file.source.rawValue)-\(assignment.speakerId)"
                    if !participants.contains(where: { $0.id == speakerId }) {
                        participants.append(Participant(id: speakerId, name: "Interlocutor \(nextNeutral)"))
                        nextNeutral += 1
                    }
                    for mapped in Self.map(start: assignment.utterance.start, end: assignment.utterance.end, spans: spans) {
                        nextSegment += 1
                        segments.append(TranscriptSegment(
                            id: String(format: "seg-%04d", nextSegment),
                            start: mapped.start,
                            end: mapped.end,
                            speakerId: speakerId,
                            text: assignment.utterance.text,
                            source: .system
                        ))
                    }
                }
            }
        }

        guard !segments.isEmpty else {
            throw SpeechRecognitionError.noSpeech
        }

        session.summary.metadata.participants = participants
        var seen = Set<String>()
        let deduplicated = segments.sorted { $0.start < $1.start }.filter { segment in
            let key = "\(segment.speakerId)|\(segment.text)"
            return seen.insert(key).inserted
        }
        session.transcript = TranscriptEditor.normalized(Transcript(
            schemaVersion: Transcript.currentSchemaVersion,
            language: usedLanguage,
            segments: deduplicated
        ))
        session = try SpeakerProfileService.finalize(
            session: session,
            profilesEnabled: options.savesVoiceProfiles,
            store: profileStore,
            temporaryStore: temporaryStore
        )
        try repository.writeTranscript(session.transcript, at: folder)
        try repository.updateParticipants(session.summary.metadata.participants, at: folder)
        // Los CAF ya no son necesarios: la transcripción y el audio final están listos.
        try? FileManager.default.removeItem(at: folder.appendingPathComponent("AudioFuentes", isDirectory: true))
        session = try repository.loadSession(at: folder)
        return SessionProcessingResult(session: session, warnings: warnings)
    }

    private struct SourceFile {
        var url: URL
        var source: CaptureSource
        var spans: [AudioTimelineFragment.Span]
    }

    private func sourceFiles(in folder: URL) throws -> [SourceFile] {
        let directory = folder.appendingPathComponent("AudioFuentes", isDirectory: true)
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "caf" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return urls.compactMap { url in
            let fragment = try? AudioTimelineFragment.load(for: url)
            let source: CaptureSource = fragment?.source
                ?? (url.lastPathComponent.lowercased().contains("microfono") ? .microphone : .system)
            return SourceFile(url: url, source: source, spans: fragment?.spans ?? [])
        }
    }

    static func map(start: Double, end: Double, spans: [AudioTimelineFragment.Span]) -> [(start: Double, end: Double)] {
        guard !spans.isEmpty else { return [(start, end)] }
        var result: [(Double, Double)] = []
        for span in spans {
            let fileEnd = span.fileStart + span.duration
            let overlapStart = max(start, span.fileStart)
            let overlapEnd = min(end, fileEnd)
            guard overlapEnd > overlapStart else { continue }
            let mappedStart = span.sessionStart + (overlapStart - span.fileStart)
            let mappedEnd = span.sessionStart + (overlapEnd - span.fileStart)
            result.append((mappedStart, mappedEnd))
        }
        return result.isEmpty ? [(start, end)] : result
    }
}
