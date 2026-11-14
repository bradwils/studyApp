import Foundation

enum SessionPhase {
    case idle
    case running
    case paused
}

// Dates are supplied by the caller so timing stays deterministic.
// Clamp each segment at zero to tolerate backwards wall-clock corrections.
enum SessionTiming: Equatable {
    case running(segmentStart: Date, accumulated: TimeInterval)
    case paused(pausedAt: Date, accumulated: TimeInterval)

    static func started(at now: Date) -> SessionTiming {
        .running(segmentStart: now, accumulated: 0)
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    func activeElapsed(at now: Date) -> TimeInterval {
        switch self {
        case .running(let segmentStart, let accumulated):
            accumulated + max(0, now.timeIntervalSince(segmentStart))
        case .paused(_, let accumulated):
            accumulated
        }
    }

    func pausing(at now: Date) -> SessionTiming {
        guard isRunning else { return self }
        return .paused(pausedAt: now, accumulated: activeElapsed(at: now))
    }

    func resuming(at now: Date) -> SessionTiming {
        guard case .paused(_, let accumulated) = self else { return self }
        return .running(segmentStart: now, accumulated: accumulated)
    }

    var elapsedAnchor: Date? {
        guard case .running(let segmentStart, let accumulated) = self else { return nil }
        return segmentStart.addingTimeInterval(-accumulated)
    }
}
