import Foundation

/// What the pinned timer should show, resolved by the view model.
///
/// ## Declaration
///
/// ```swift
/// enum TimerDisplay: Equatable
/// ```
///
/// Each case carries only dates, so a timeline view can derive the text from its own
/// tick date without asking the view model again.
enum TimerDisplay: Equatable {
    case idle
    /// Running with no target: count up from `since`.
    case elapsed(since: Date)
    /// Paused: count up from the start of the pause.
    case breakElapsed(since: Date)
    /// Running with a target: remaining time until `until`. `total` lets the view align its one-second tick grid to `until - total`.
    case countdown(until: Date, total: TimeInterval)
}
