//  DialCenter.swift
//  studyApp
//
//  DEV ONLY — the timer and caption pinned inside Dial's ring.

import SwiftUI

struct DialCenter: View {

    let session: FocusLabSession
    let blend: CGFloat
    let diameter: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 50

    var body: some View {
        let flip: CGFloat = FocusLabMath.window(blend, 0.55, 0.8)
        let textColor: Color = DialPalette.ink.labBlend(DialPalette.white, flip)
        let timerWidth: CGFloat = diameter * 0.74
        let timerFont: Font = Font.system(size: timerSize, weight: .medium).width(.expanded)
        VStack(spacing: 8) {
            FocusLabClock(session: session, idleText: "0:00")
                .font(timerFont)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: timerWidth)
            DialCaption(session: session, blend: blend, color: textColor.opacity(0.65))
        }
    }
}

private struct DialCaption: View {

    let session: FocusLabSession
    let blend: CGFloat
    let color: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let trackingOpacity: Double = Double(1 - blend)
            let focusOpacity: Double = Double(blend)
            ZStack {
                Text(trackingText(at: context.date))
                    .opacity(trackingOpacity)
                Text(focusText(at: context.date))
                    .opacity(focusOpacity)
            }
            .font(DialFont.text(13, .regular))
            .foregroundStyle(color)
        }
    }

    private func trackingText(at date: Date) -> String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Ready" }
            let minutes: Int = max(1, Int((length / 60).rounded()))
            return "Saved \(minutes) min"
        case .running:
            let hour: Int = Int(session.studyElapsed(at: date) / 3600) + 1
            return "Hour \(hour)"
        case .paused:
            return "On a break"
        }
    }

    private func focusText(at date: Date) -> String {
        guard session.hasFocusBlock else { return "No block set" }
        if session.isFocusComplete(at: date) { return "Complete" }
        if session.isPaused { return "On a break" }
        return "of \(blockMinutes) min"
    }

    private var blockMinutes: Int {
        guard let start = session.focusStart, let goal = session.focusGoal else {
            return Int(session.focusDuration / 60)
        }
        return Int((goal.timeIntervalSince(start) / 60).rounded())
    }
}
