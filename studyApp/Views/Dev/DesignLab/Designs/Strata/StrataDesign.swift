//  StrataDesign.swift
//  studyApp
//
//  DEV ONLY — "Strata": the session settles like sediment, one flat band per stretch of
//  study. The focus page zooms into the band being laid right now.

import SwiftUI

struct StrataDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80
    @ScaledMetric(relativeTo: .largeTitle) private var timerSlotHeight: CGFloat = 100

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

    private var pager: some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            StrataTrackingPage(session: session, slotHeight: timerSlotHeight)
        } focus: {
            StrataFocusPage(session: session, slotHeight: timerSlotHeight)
        }
    }

    private func backdrop(_ metrics: FocusLabStageMetrics) -> some View {
        StrataBackdrop(
            session: session,
            blend: blend,
            metrics: metrics,
            timerSize: timerSize,
            timerSlotHeight: timerSlotHeight
        )
    }
}

#Preview {
    StrataDesign(session: FocusLabSession())
}
