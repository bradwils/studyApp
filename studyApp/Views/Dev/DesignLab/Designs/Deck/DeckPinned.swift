//  DeckPinned.swift
//  studyApp
//
//  DEV ONLY — Deck's fixed layer above the pager: the timer, its status line and the
//  focus progress bar, all placed from the shown timer panel.

import SwiftUI

struct DeckPinned: View {

    let session: FocusLabSession
    let layout: DeckLayout

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 72

    private var textColor: Color {
        let flip: CGFloat = FocusLabMath.window(layout.blend, 0.45, 0.75)
        return DeckPalette.wine.labBlend(DeckPalette.petal, flip)
    }

    var body: some View {
        let center: CGPoint = layout.timerCenter
        return ZStack {
            timer
                .position(x: center.x, y: center.y)
            DeckStatus(session: session, blend: layout.blend, color: textColor)
                .position(x: center.x, y: center.y + 46)
            progressBar
                .position(x: center.x, y: center.y + 84)
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .allowsHitTesting(false)
    }

    private var timer: some View {
        let width: CGFloat = max(layout.size.width - 80, 0)
        return FocusLabClock(session: session, idleText: "0:00")
            .font(.system(size: timerSize, weight: .semibold, design: .rounded))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: width)
            .scaleEffect(layout.timerScale)
    }

    private var progressBar: some View {
        let width: CGFloat = max(layout.size.width - 96, 0)
        let visible: Double = Double(FocusLabMath.window(layout.blend, 0.6, 1))
        return DeckFocusBar(session: session, width: width)
            .opacity(visible)
    }
}

private struct DeckStatus: View {

    let session: FocusLabSession
    let blend: CGFloat
    let color: Color

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 15

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                Text(trackingText)
                    .opacity(Double(1 - blend))
                Text(focusText(at: context.date))
                    .opacity(Double(blend))
            }
            .font(.system(size: textSize))
            .foregroundStyle(color.opacity(0.7))
            .lineLimit(1)
        }
    }

    private var trackingText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Ready" }
            return "Saved \(DeckFormat.savedMinutes(length)) min"
        case .running:
            return "Studying \(session.selectedSubject.code)"
        case .paused:
            return "On a break"
        }
    }

    private var blockMinutes: Int {
        guard let start = session.focusStart, let goal = session.focusGoal else {
            return Int(session.focusDuration / 60)
        }
        return Int((goal.timeIntervalSince(start) / 60).rounded())
    }

    private func focusText(at date: Date) -> String {
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "No block yet" }
        if session.isFocusComplete(at: date) { return "Block complete" }
        return "left of \(blockMinutes) minutes"
    }
}

private struct DeckFocusBar: View {

    let session: FocusLabSession
    let width: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            bar(progress: session.focusProgress(at: context.date) ?? 0)
        }
    }

    private func bar(progress: Double) -> some View {
        let fillWidth: CGFloat = width * CGFloat(progress)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(DeckPalette.petal.opacity(0.2))
            Capsule()
                .fill(DeckPalette.lime)
                .frame(width: fillWidth)
        }
        .frame(width: width, height: 6)
        .animation(.linear(duration: 1), value: progress)
    }
}
