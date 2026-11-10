import Foundation

/// The lifecycle phase of the study session being tracked.
///
/// ## Declaration
///
/// ```swift
/// enum SessionPhase
/// ```
///
/// Derived from ``SessionTiming``: no timing means `idle`.
enum SessionPhase {
    case idle
    case running
    case paused
}

/// A pure clock for one study session, expressed as a running or paused segment.
///
/// ## Declaration
///
/// ```swift
/// enum SessionTiming: Equatable
/// ```
///
/// Every calculation takes the current date as an argument and never reads the system
/// clock, so behaviour is deterministic and testable. Pausing folds the running segment
/// into `accumulated`; resuming starts a new segment.
///
/// > Important: Elapsed time is clamped at zero per segment, so a backwards wall-clock
/// > correction never produces negative study time.
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

    /// Study time accumulated so far, excluding paused time.
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

    /// The date a count-up timer measures from while running, or `nil` when paused.
    var elapsedAnchor: Date? {
        guard case .running(let segmentStart, let accumulated) = self else { return nil }
        return segmentStart.addingTimeInterval(-accumulated)
    }
}
