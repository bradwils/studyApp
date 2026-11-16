//  MarginDesign.swift
//  studyApp
//
//  DEV ONLY — "Margin": a notebook page with one fixed margin rule. A highlighter
//  stroke grows behind the timer; the focus page is an ink panel wiping in from the right.

import SwiftUI

struct MarginDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 92
    @ScaledMetric(relativeTo: .largeTitle) private var timerSlotHeight: CGFloat = 112

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { metrics in
            backdrop(metrics)
        } content: { _ in
            pager
        }
    }

    // MARK: - Pager

    private var pager: some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            MarginTrackingPage(session: session, slotHeight: timerSlotHeight)
        } focus: {
            MarginFocusPage(session: session, slotHeight: timerSlotHeight)
        }
    }

    // MARK: - Backdrop

    private func backdrop(_ metrics: FocusLabStageMetrics) -> some View {
        let full: CGSize = metrics.fullSize
        let edgeX: CGFloat = full.width * (1 - blend)
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
            timers(metrics, edgeX: edgeX)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private func timers(_ metrics: FocusLabStageMetrics, edgeX: CGFloat) -> some View {
        let full: CGSize = metrics.fullSize
        let inkWidth: CGFloat = full.width - edgeX
        return TimelineView(.periodic(from: .now, by: 1)) { context in
            let fraction: Double = strokeFraction(at: context.date)
            ZStack(alignment: .topLeading) {
                timerCopy(onInk: false, fraction: fraction, metrics: metrics)
                    .mask {
                        MarginBar(color: Color.black, width: edgeX, alignment: .leading, full: full)
                    }
                timerCopy(onInk: true, fraction: fraction, metrics: metrics)
                    .mask {
                        MarginBar(color: Color.black, width: inkWidth, alignment: .trailing, full: full)
                    }
                    .accessibilityHidden(true)
            }
        }
    }

    private func timerCopy(onInk: Bool, fraction: Double, metrics: FocusLabStageMetrics) -> MarginTimer {
        MarginTimer(
            session: session,
            onInk: onInk,
            fraction: fraction,
            animates: !reduceMotion,
            size: timerSize,
            slotHeight: timerSlotHeight,
            top: metrics.backdropY(MarginLayout.timerTop),
            leading: metrics.backdropX(MarginLayout.contentX),
            full: metrics.fullSize
        )
    }

    private func strokeFraction(at date: Date) -> Double {
        if let progress = session.focusProgress(at: date) { return progress }
        guard session.hasSession else { return 0 }
        let elapsed: TimeInterval = session.studyElapsed(at: date)
        return elapsed.truncatingRemainder(dividingBy: 60) / 60
    }
}

#Preview {
    MarginDesign(session: FocusLabSession())
}
