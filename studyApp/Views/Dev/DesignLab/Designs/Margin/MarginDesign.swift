//  MarginDesign.swift
//  studyApp
//
//  DEV ONLY — "Margin": a notebook page with one fixed margin rule. A highlighter
//  stroke grows behind the timer; the focus page is an ink panel wiping in from the right.

import SwiftUI

struct MarginDesign: FocusLabScreen {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 92

    func chromeScheme(blend: CGFloat) -> ColorScheme? {
        blend < 0.5 ? .light : .dark
    }

    func timer(_ context: FocusLabContext) -> some View {
        EmptyView()
    }

    func trackingHeader(_ context: FocusLabContext) -> some View {
        MarginTrackingHeader(session: context.session)
    }

    func trackingBody(_ context: FocusLabContext) -> some View {
        MarginTrackingPage(session: context.session)
    }

    func focusHeader(_ context: FocusLabContext) -> some View {
        MarginFocusHeader(session: context.session)
    }

    func focusBody(_ context: FocusLabContext) -> some View {
        MarginFocusPage(session: context.session)
    }

    func backdrop(_ context: FocusLabContext) -> some View {
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
            timers(context, edgeX: edgeX)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private func timers(_ context: FocusLabContext, edgeX: CGFloat) -> some View {
        let full: CGSize = context.metrics.fullSize
        let inkWidth: CGFloat = full.width - edgeX
        return TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let fraction: Double = strokeFraction(context.session, at: timeline.date)
            ZStack(alignment: .topLeading) {
                timerCopy(onInk: false, fraction: fraction, context: context)
                    .mask {
                        MarginBar(color: Color.black, width: edgeX, alignment: .leading, full: full)
                    }
                timerCopy(onInk: true, fraction: fraction, context: context)
                    .mask {
                        MarginBar(color: Color.black, width: inkWidth, alignment: .trailing, full: full)
                    }
                    .accessibilityHidden(true)
            }
        }
    }

    private func timerCopy(onInk: Bool, fraction: Double, context: FocusLabContext) -> MarginTimer {
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

    private func strokeFraction(_ session: FocusLabSession, at date: Date) -> Double {
        if let progress = session.focusProgress(at: date) { return progress }
        guard session.hasSession else { return 0 }
        let elapsed: TimeInterval = session.studyElapsed(at: date)
        return elapsed.truncatingRemainder(dividingBy: 60) / 60
    }
}

#Preview {
    FocusLabScaffold(session: FocusLabSession(), design: MarginDesign())
}
