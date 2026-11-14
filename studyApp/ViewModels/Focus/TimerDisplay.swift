import Foundation

// Date-based cases let the timer tick without consulting the session owner.
enum TimerDisplay: Equatable {
    case idle
    case elapsed(since: Date)
    case breakElapsed(since: Date)
    // total anchors the tick grid to the target start (until - total).
    case countdown(until: Date, total: TimeInterval)
}
