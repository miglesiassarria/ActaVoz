import Foundation

/// Decide cuándo una fuente dejó de entregar audio y cuándo reintentar.
/// No usa amplitud: el silencio es audio válido; solo cuenta búferes escritos.
public struct CaptureHealthMonitor: Sendable {
    public var timeout: TimeInterval
    public var retryDelay: TimeInterval
    private var segmentStartedAt: Date
    private var lastAttemptAt: Date

    public init(timeout: TimeInterval = 4, retryDelay: TimeInterval = 5, now: Date = Date()) {
        self.timeout = timeout
        self.retryDelay = retryDelay
        self.segmentStartedAt = now
        self.lastAttemptAt = now
    }

    /// Cada tramo nuevo concede el mismo margen antes de declarar pérdida.
    public mutating func beginSegment(at now: Date) {
        segmentStartedAt = now
        lastAttemptAt = now
    }

    public func stalled(sources: Set<CaptureSource>, lastWrite: [CaptureSource: Date], now: Date) -> Set<CaptureSource> {
        Set(sources.filter { source in
            let reference = lastWrite[source] ?? segmentStartedAt
            return now.timeIntervalSince(reference) > timeout
        })
    }

    /// Solo reintenta cuando no queda ninguna fuente sana; reiniciar una sana
    /// alargaría el hueco sin necesidad.
    public func shouldRetry(sources: Set<CaptureSource>, recovering: Set<CaptureSource>, now: Date) -> Bool {
        sources.isEmpty && !recovering.isEmpty && now.timeIntervalSince(lastAttemptAt) >= retryDelay
    }

    public mutating func recordAttempt(at now: Date) {
        lastAttemptAt = now
    }
}
