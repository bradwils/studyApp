//  VellumDesign.swift
//  studyApp
//
//  DEV ONLY — "Vellum": five sheets of coloured tracing paper. Fanned behind the controls while
//  tracking, they slide up one after another into a single tile behind the timer, then rotate
//  apart into a rosette as the focus block runs.

import SwiftUI

struct VellumDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80

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
        .focusLabChrome(.light)
    }

    private func backdropLayer(_ metrics: FocusLabStageMetrics) -> some View {
        let layout = VellumLayout(metrics: metrics)
        return VellumBackdrop(session: session, layout: layout, blend: blend, timerSize: timerSize)
    }

    private func pagerLayer(_ metrics: FocusLabStageMetrics) -> some View {
        let layout = VellumLayout(metrics: metrics)
        return FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            VellumTrackingPage(session: session, layout: layout)
        } focus: {
            VellumFocusPage(session: session, layout: layout, blend: blend)
        }
    }
}

#Preview {
    VellumDesign(session: FocusLabSession())
}
