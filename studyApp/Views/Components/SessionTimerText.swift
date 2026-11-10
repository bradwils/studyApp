//
//  SessionTimerText.swift
//  studyApp
//
//  Created by brad wils on 14/7/26.
//

import SwiftUI

/// Text that renders a ``TimerDisplay`` as a self-updating clock.
///
/// ## Declaration
///
/// ```swift
/// struct SessionTimerText: View
/// ```
///
/// Each case drives its own `TimelineView`, so the view model is not consulted on every
/// tick. Counting down uses a countdown numeric transition, and the animation is skipped
/// under Reduce Motion.
struct SessionTimerText: View {
    var display: TimerDisplay

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch display {
        case .idle:
            Text("--:--")
                .accessibilityLabel("No active session")
        case .elapsed(let since):
            countUp(since: since)
                .accessibilityLabel("Study time")
                .accessibilityAddTraits(.updatesFrequently)
        case .breakElapsed(let since):
            countUp(since: since)
                .accessibilityLabel("Break time")
                .accessibilityAddTraits(.updatesFrequently)
        case .countdown(let until, let total):
            countdown(until: until, total: total)
                .accessibilityLabel("Focus time remaining")
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    // A grid schedule anchored to `since` keeps ticks on integer-second boundaries of the
    // elapsed time. A `from: .now` schedule would drift every render and fall out of
    // phase with the actual second changes.
    private func countUp(since: Date) -> some View {
        TimelineView(.periodic(from: since, by: 1)) { context in
            // context.date is the exact tick time, not "now at render time", so the value is deterministic.
            let elapsed = max(0, context.date.timeIntervalSince(since))
            digits(elapsed, countsDown: false)
        }
    }

    // The countdown's grid is anchored to its start (`until - total`, a past date) so ticks
    // land on the same second boundaries as the remaining time. Rounding to the nearest
    // second stops the display showing one second less than it should for most of each second.
    private func countdown(until: Date, total: TimeInterval) -> some View {
        TimelineView(.periodic(from: until.addingTimeInterval(-total), by: 1)) { context in
            let remaining = max(0, until.timeIntervalSince(context.date)).rounded()
            digits(remaining, countsDown: true)
        }
    }

    private func digits(_ value: TimeInterval, countsDown: Bool) -> some View {
        let wholeSeconds = Int(value)
        return Text(formattedElapsed(value))
            .contentTransition(.numericText(countsDown: countsDown))
            // Must track the displayed value; any other formula fires the numeric transition at the wrong moment.
            .animation(reduceMotion ? nil : .linear, value: wholeSeconds)
    }
}
