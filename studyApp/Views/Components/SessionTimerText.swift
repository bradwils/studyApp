//
//  SessionTimerText.swift
//  studyApp
//
//  Created by brad wils on 14/7/26.
//

import SwiftUI

struct SessionTimerText: View {
    var display: TimerDisplay

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch display {
        case .idle:
            Text("--:--")
                .accessibilityLabel("No active session")
        case .elapsed(let timing, let tickOrigin):
            studyElapsed(timing: timing, tickOrigin: tickOrigin)
                .accessibilityLabel("Study time")
                .accessibilityAddTraits(.updatesFrequently)
        case .breakElapsed(let since):
            countUp(since: since)
                .accessibilityLabel("Break time")
                .accessibilityAddTraits(.updatesFrequently)
        case .countdown(let timing, let target, let tickOrigin):
            countdown(timing: timing, target: target, tickOrigin: tickOrigin)
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

    private func studyElapsed(timing: SessionTiming, tickOrigin: Date) -> some View {
        TimelineView(.periodic(from: tickOrigin, by: 1)) { context in
            digits(timing.activeElapsed(at: context.date), countsDown: false)
        }
    }

    private func countdown(timing: SessionTiming, target: FocusTarget, tickOrigin: Date) -> some View {
        TimelineView(.periodic(from: tickOrigin, by: 1)) { context in
            // Preserve the segment and target clamps when the wall clock moves backwards.
            let remaining = target.remaining(
                sessionActiveElapsed: timing.activeElapsed(at: context.date)
            ).rounded()
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
