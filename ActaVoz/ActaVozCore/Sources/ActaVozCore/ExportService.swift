import Foundation

public enum ExportFormat: String, CaseIterable, Sendable {
    case markdown
    case plainText

    public var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .plainText: return "txt"
        }
    }

    public var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .plainText: return "Texto plano"
        }
    }
}

public enum ExportContent: String, CaseIterable, Sendable {
    case transcript
    case summary
    case notes
}

public struct ExportService {
    public init() {}

    public func transcript(_ session: Session) -> String {
        session.transcript.segments.map { segment in
            let name = session.summary.metadata.participants.first { $0.id == segment.speakerId }?.name ?? segment.speakerId
            return "[\(Self.time(segment.start))] \(name): \(segment.text)"
        }.joined(separator: "\n")
    }

    public func summary(_ session: Session) -> String {
        session.summaryText
    }

    public func notes(_ session: Session, includeSynthesis: Bool) -> String {
        var result = session.notes
        if includeSynthesis && !session.synthesis.isEmpty {
            result += "\n\n## Síntesis (generada por IA)\n\n\(session.synthesis)"
        }
        return result
    }

    public func render(_ content: ExportContent, session: Session, format: ExportFormat, includeSynthesis: Bool = false) -> String {
        let body: String
        switch content {
        case .transcript: body = transcript(session)
        case .summary: body = summary(session)
        case .notes: body = notes(session, includeSynthesis: includeSynthesis)
        }
        switch format {
        case .plainText: return body
        case .markdown: return "# \(session.summary.title)\n\n\(body)\n"
        }
    }

    public func suggestedFilename(_ content: ExportContent, title: String, format: ExportFormat) -> String {
        let base = title.replacingOccurrences(of: "/", with: "-")
        let suffix: String
        switch content {
        case .transcript: suffix = "transcripcion"
        case .summary: suffix = "resumen"
        case .notes: suffix = "notas"
        }
        return "\(base)-\(suffix).\(format.fileExtension)"
    }

    private static func time(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
