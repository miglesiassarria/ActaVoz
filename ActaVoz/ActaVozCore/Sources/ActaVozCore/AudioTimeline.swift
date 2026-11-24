import Foundation

/// A CAF remains a single source; these spans locate its frames in session time.
/// Sidecars are additive/versioned: a missing sidecar is legacy, a bad one is an error.
public struct AudioTimelineFragment: Codable, Equatable, Sendable {
    public struct Span: Codable, Equatable, Sendable {
        public var fileStart: Double
        public var sessionStart: Double
        public var duration: Double
        public init(fileStart: Double, sessionStart: Double, duration: Double) {
            self.fileStart = fileStart; self.sessionStart = sessionStart; self.duration = duration
        }
    }
    public var version: Int = 1
    public var source: CaptureSource
    public var segmentID: UUID
    public var spans: [Span]
    public init(source: CaptureSource, segmentID: UUID, spans: [Span] = []) {
        self.source = source; self.segmentID = segmentID; self.spans = spans
    }
    public var end: Double { spans.map { $0.sessionStart + $0.duration }.max() ?? 0 }
    public static func sidecarURL(for audio: URL) -> URL { audio.appendingPathExtension("timeline.json") }
    public func save(for audio: URL) throws {
        try validate()
        try JSONEncoder().encode(self).write(to: Self.sidecarURL(for: audio), options: .atomic)
    }
    public static func load(for audio: URL) throws -> Self? {
        let url = sidecarURL(for: audio)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let result = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        try result.validate()
        return result
    }
    public func validate() throws {
        guard version == 1 else { throw AudioTimelineError.invalidMetadata }
        var fileEnd = 0.0, sessionEnd = 0.0
        for span in spans {
            guard span.fileStart.isFinite, span.sessionStart.isFinite, span.duration.isFinite,
                  abs(span.fileStart - fileEnd) < 0.000001, span.sessionStart >= sessionEnd - 0.000001,
                  span.duration > 0 else { throw AudioTimelineError.invalidMetadata }
            fileEnd = span.fileStart + span.duration
            sessionEnd = span.sessionStart + span.duration
        }
    }
}

public enum AudioTimelineError: Error { case invalidMetadata, mixedLegacyAndTimeline }

/// Host times from both native APIs must be converted with the same host clock.
/// Historical intervals also handle callbacks delivered after a pause/resume.
public struct AudioTimelineClock: Sendable {
    public struct Slice: Equatable, Sendable {
        public let bufferOffset: Double
        public let sessionStart: Double
        public let duration: Double
    }
    private struct Interval: Sendable { var start: Double; var end: Double?; var sessionStart: Double }
    private var intervals: [Interval]
    public init(hostStart: Double, sessionStart: Double) {
        intervals = [Interval(start: hostStart, end: nil, sessionStart: sessionStart)]
    }
    public mutating func pause(at host: Double) {
        guard let last = intervals.last, last.end == nil else { return }
        intervals[intervals.count - 1].end = max(host, last.start)
    }
    public mutating func resume(at host: Double) {
        guard let last = intervals.last, let end = last.end else { return }
        intervals.append(Interval(start: max(host, end), end: nil,
                                  sessionStart: last.sessionStart + end - last.start))
    }
    public func slices(hostStart: Double, duration: Double) -> [Slice] {
        guard hostStart.isFinite, duration.isFinite, duration > 0 else { return [] }
        return intervals.compactMap { interval in
            let start = max(hostStart, interval.start)
            let end = min(hostStart + duration, interval.end ?? .infinity)
            guard end > start else { return nil }
            return Slice(bufferOffset: start - hostStart,
                         sessionStart: interval.sessionStart + start - interval.start, duration: end - start)
        }
    }
}

public enum AudioTimelinePlanner {
    public struct Input: Sendable {
        public let url: URL
        public let duration: Double
        public let metadata: AudioTimelineFragment?
        public init(url: URL, duration: Double, metadata: AudioTimelineFragment?) {
            self.url = url; self.duration = duration; self.metadata = metadata
        }
    }
    public struct Placement: Equatable, Sendable {
        public let url: URL
        public let fileStart: Double
        public let sessionStart: Double
        public let duration: Double
    }
    /// Explicit legacy fallback: old dual-source CAFs share a UUID suffix and mix
    /// within one segment. Multiple legacy segments have unknowable order and are rejected.
    /// Mixed sessions retain the legacy prefix; timed recovery must start after it.
    public static func plan(_ inputs: [Input]) throws -> [Placement] {
        guard inputs.allSatisfy({ $0.duration.isFinite && $0.duration > 0 }) else {
            throw AudioTimelineError.invalidMetadata
        }
        let legacyInputs = inputs.filter { $0.metadata == nil }
        let keys = Set(legacyInputs.map { legacyKey($0.url) })
        guard keys.count <= 1 else { throw AudioTimelineError.mixedLegacyAndTimeline }
        if inputs.allSatisfy({ $0.metadata == nil }) { return legacyPlan(inputs) }
        let legacy = legacyPlan(legacyInputs)
        let legacyEnd = legacy.map { $0.sessionStart + $0.duration }.max() ?? 0
        let timed = try inputs.filter { $0.metadata != nil }.flatMap { input in
            var metadata = input.metadata!
            try metadata.validate()
            let name = input.url.deletingPathExtension().lastPathComponent
            for (prefix, expected) in [("microfono-", CaptureSource.microphone), ("sistema-", CaptureSource.system)] where name.hasPrefix(prefix) {
                guard metadata.source == expected else { throw AudioTimelineError.invalidMetadata }
                let suffix = String(name.dropFirst(prefix.count))
                if let id = UUID(uuidString: suffix), id != metadata.segmentID { throw AudioTimelineError.invalidMetadata }
            }
            guard var last = metadata.spans.last else { throw AudioTimelineError.invalidMetadata }
            let tail = input.duration - (last.fileStart + last.duration)
            guard tail >= -0.001 else { throw AudioTimelineError.invalidMetadata }
            if tail > 0 {
                // Un checkpoint interrumpido deja el CAF por delante del sidecar.
                // Esas muestras existen: se incorporan y la planificación detecta
                // si invadieran el siguiente tramo.
                last.duration += tail
                metadata.spans[metadata.spans.count - 1] = last
            }
            return try metadata.spans.map { span in
                guard span.sessionStart >= legacyEnd - 0.000001,
                      span.fileStart + span.duration <= input.duration + 0.01 else {
                    throw AudioTimelineError.invalidMetadata
                }
                return Placement(url: input.url, fileStart: span.fileStart,
                                 sessionStart: span.sessionStart, duration: min(span.duration, input.duration - span.fileStart))
            }
        }
        let placements = (legacy + timed).sorted {
            if $0.sessionStart != $1.sessionStart { return $0.sessionStart < $1.sessionStart }
            return $0.url.path < $1.url.path
        }
        let sourceByURL = Dictionary(inputs.compactMap { input in input.metadata.map { (input.url, $0.source) } },
                                     uniquingKeysWith: { first, _ in first })
        var endsBySource: [CaptureSource: Double] = [:]
        for placement in placements {
            let source = sourceByURL[placement.url]
                ?? (placement.url.lastPathComponent.hasPrefix("microfono-") ? .microphone : .system)
            if let end = endsBySource[source], placement.sessionStart < end - 0.000001 {
                throw AudioTimelineError.invalidMetadata
            }
            endsBySource[source] = max(endsBySource[source] ?? 0, placement.sessionStart + placement.duration)
        }
        return placements
    }
    private static func legacyKey(_ url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        for prefix in ["microfono-", "sistema-"] where name.hasPrefix(prefix) {
            return String(name.dropFirst(prefix.count))
        }
        return name
    }
    private static func legacyPlan(_ inputs: [Input]) -> [Placement] {
        let groups = Dictionary(grouping: inputs, by: { legacyKey($0.url) })
        var offset = 0.0
        return groups.keys.sorted().flatMap { key -> [Placement] in
            let group = groups[key]!
            let result = group.sorted { $0.url.path < $1.url.path }.map {
                Placement(url: $0.url, fileStart: 0, sessionStart: offset, duration: $0.duration)
            }
            offset += group.map(\.duration).max() ?? 0
            return result
        }
    }
}
