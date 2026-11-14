import Foundation

struct FocusDurationLimits: Equatable {
    var hours: ClosedRange<Int> = 0...8
    var minutes: ClosedRange<Int> = 0...59

    static let standard = FocusDurationLimits()

    var maximumDuration: TimeInterval {
        TimeInterval(hours.upperBound * 3600 + minutes.upperBound * 60)
    }

    func allows(_ duration: TimeInterval) -> Bool {
        duration.isFinite && duration > 0 && duration <= maximumDuration
    }
}

// Active elapsed time freezes during pauses, so targets need no deadline adjustment.
struct FocusTarget: Equatable {
    let duration: TimeInterval
    let activeElapsedAtStart: TimeInterval

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
