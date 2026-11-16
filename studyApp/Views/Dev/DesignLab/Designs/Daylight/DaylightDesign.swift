//  DaylightDesign.swift
//  studyApp
//
//  DEV ONLY — "Daylight": a study day as the sun crossing the sky. One sun is shared by both
//  pages: a small marker on the day's arc while tracking, a large disc rising behind the timer
//  as a focus block progresses.

import SwiftUI

struct DaylightDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 84
    @ScaledMetric(relativeTo: .largeTitle) private var timerSlotHeight: CGFloat = 110

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { metrics in
            backdropLayer(metrics)
        } content: { metrics in
            pagerLayer(metrics)
        }
    }

    private func backdropLayer(_ metrics: FocusLabStageMetrics) -> some View {
        let layout = DaylightGeometry(metrics: metrics, timerSlotHeight: timerSlotHeight)
        return DaylightBackdrop(session: session, geometry: layout, blend: blend, timerSize: timerSize)
    }

    private func pagerLayer(_ metrics: FocusLabStageMetrics) -> some View {
        let layout = DaylightGeometry(metrics: metrics, timerSlotHeight: timerSlotHeight)
        return FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            DaylightTrackingPage(session: session, geometry: layout)
        } focus: {
            DaylightFocusPage(session: session, geometry: layout)
        }
    }
}

#Preview {
    DaylightDesign(session: FocusLabSession())
}
