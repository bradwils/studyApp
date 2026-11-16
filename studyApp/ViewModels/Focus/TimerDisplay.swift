import Foundation

/// What the pinned timer should show, resolved by the view model.
///
/// ## Declaration
///
/// ```swift
/// enum TimerDisplay: Equatable
/// ```
///
/// Each case carries value snapshots rather than a live reference to the session owner, so a
/// timeline view can derive the text from its own tick date without asking the view model again.
enum TimerDisplay: Equatable {
    case idle
    /// Running with no target: count up from the snapshot's active time, anchored at `tickOrigin`.
    case elapsed(timing: SessionTiming, tickOrigin: Date)
    /// Paused: count up from the start of the pause.
    case breakElapsed(since: Date)
    /// Running with a target: remaining time derived from the timing and target snapshots.
    case countdown(timing: SessionTiming, target: FocusTarget, tickOrigin: Date)
}
