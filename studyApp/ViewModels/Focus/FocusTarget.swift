import Foundation

/// The duration ranges available in the focus picker.
///
/// ## Declaration
///
/// ```swift
/// struct FocusDurationLimits: Equatable
/// ```
///
/// The ranges populate the picker. Programmatic targets are validated against
/// the combined maximum duration in seconds.
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

/// A countdown goal measured in active study time.
///
/// ## Declaration
///
/// ```swift
/// struct FocusTarget: Equatable
/// ```
///
/// The target stores the session's active elapsed time at the moment it began.
/// Pausing freezes the countdown, and reaching zero leaves the study session active.
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
