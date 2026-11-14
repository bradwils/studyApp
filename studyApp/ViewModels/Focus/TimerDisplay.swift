import Foundation

// Value snapshots let the timer tick without consulting the session owner.
enum TimerDisplay: Equatable {
    case idle
    case elapsed(timing: SessionTiming, tickOrigin: Date)
    case breakElapsed(since: Date)
    case countdown(timing: SessionTiming, target: FocusTarget, tickOrigin: Date)
}
