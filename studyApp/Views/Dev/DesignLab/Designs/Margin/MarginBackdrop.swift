//  MarginBackdrop.swift
//  studyApp
//
//  DEV ONLY — Margin's fixed layer: paper, the ink panel wiping in from the right, the margin
//  rule, and both copies of the timer, each masked to its own side of the ink edge.

import SwiftUI

struct MarginBackdrop: View {

    let context: FocusLabContext
    let timerSize: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let metrics: FocusLabStageMetrics = context.metrics
        let full: CGSize = metrics.fullSize
        let edgeX: CGFloat = full.width * (1 - context.blend)
        let inkWidth: CGFloat = full.width - edgeX
        let ruleX: CGFloat = metrics.backdropX(MarginLayout.marginX)
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(MarginPalette.paper)
            MarginBar(color: MarginPalette.ink, width: inkWidth, alignment: .trailing, full: full)
            MarginRule(color: MarginPalette.rule, x: ruleX, full: full)
            MarginRule(color: MarginPalette.ruleDark, x: ruleX, full: full)
                .mask {
                    MarginBar(color: Color.black, width: inkWidth, alignment: .trailing, full: full)
                }
            timers(edgeX: edgeX)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private func timers(edgeX: CGFloat) -> some View {
        let full: CGSize = context.metrics.fullSize
        let inkWidth: CGFloat = full.width - edgeX
        return TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let fraction: Double = strokeFraction(at: timeline.date)
            ZStack(alignment: .topLeading) {
                timerCopy(onInk: false, fraction: fraction)
                    .mask {
                        MarginBar(color: Color.black, width: edgeX, alignment: .leading, full: full)
                    }
                timerCopy(onInk: true, fraction: fraction)
                    .mask {
                        MarginBar(color: Color.black, width: inkWidth, alignment: .trailing, full: full)
                    }
                    .accessibilityHidden(true)
            }
        }
    }

    private func timerCopy(onInk: Bool, fraction: Double) -> MarginTimer {
        let rect: CGRect = context.timerBackdropRect
        return MarginTimer(
            session: context.session,
            onInk: onInk,
            fraction: fraction,
            animates: !reduceMotion,
            size: timerSize,
            slotHeight: rect.height,
            top: rect.minY,
            leading: context.metrics.backdropX(MarginLayout.contentX),
            full: context.metrics.fullSize
        )
    }

    private func strokeFraction(at date: Date) -> Double {
        let session: FocusLabSession = context.session
        if let progress = session.focusProgress(at: date) { return progress }
        guard session.hasSession else { return 0 }
        let elapsed: TimeInterval = session.studyElapsed(at: date)
        return elapsed.truncatingRemainder(dividingBy: 60) / 60
    }
}
