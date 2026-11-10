import Foundation

/// The hour and minute ranges a focus target may be chosen from.
///
/// ## Declaration
///
/// ```swift
/// struct FocusDurationLimits: Equatable
/// ```
///
/// Read-only configuration shared by the duration picker and the validation in
/// ``FocusTarget``.
struct FocusDurationLimits: Equatable {
    var hours: ClosedRange<Int> = 0...8
    var minutes: ClosedRange<Int> = 0...59

    static let standard = FocusDurationLimits()

    var maximumDuration: TimeInterval {
        TimeInterval(hours.upperBound * 3600 + minutes.upperBound * 60)
    }

    /// Whether `duration` is finite, positive and within ``maximumDuration``.
    func allows(_ duration: TimeInterval) -> Bool {
        duration.isFinite && duration > 0 && duration <= maximumDuration
    }
}

/// A focus goal measured against a session's active study time.
///
/// ## Declaration
///
/// ```swift
/// struct FocusTarget: Equatable
/// ```
///
/// The target stores the session's active elapsed time at the moment it began, so it
/// freezes while the session is paused and needs no deadline adjusting on resume.
struct FocusTarget: Equatable {
    let duration: TimeInterval
    let activeElapsedAtStart: TimeInterval

    /// Returns `nil` when `limits` do not allow `duration`.
    init?(duration: TimeInterval, activeElapsedAtStart: TimeInterval, limits: FocusDurationLimits = .standard) {
        guard limits.allows(duration) else { return nil }
        self.duration = duration
        self.activeElapsedAtStart = activeElapsedAtStart
    }

    func elapsed(sessionActiveElapsed: TimeInterval) -> TimeInterval {
        max(0, sessionActiveElapsed - activeElapsedAtStart)
    }

    func remaining(sessionActiveElapsed: TimeInterval) -> TimeInterval {
        max(0, duration - elapsed(sessionActiveElapsed: sessionActiveElapsed))
    }

    func progress(sessionActiveElapsed: TimeInterval) -> Double {
        min(max(elapsed(sessionActiveElapsed: sessionActiveElapsed) / duration, 0), 1)
    }
}
