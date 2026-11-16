//  FocusLabScaffold.swift
//  studyApp
//
//  DEV ONLY — renders any FocusLabScreen with FocusSessionScreen's structure: a two-page
//  pager over a pinned timer, each page a header band, then the timer gap, then its body.

import SwiftUI

struct FocusLabScaffold<Design: FocusLabScreen>: View {

    let session: FocusLabSession
    let design: Design

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var standardTimerHeight: CGFloat = 120

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    // Reduce Motion gets the destination state rather than a crossfade travelling with the drag.
    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    // Both pages and the timer read this one value, so they can never disagree on where the timer is.
    private var slots: FocusLabSlots {
        design.slots(standard: FocusLabSlots(
            headerHeight: FocusPagerLayout.headerSlotHeight,
            timerHeight: standardTimerHeight
        ))
    }

    var body: some View {
        FocusLabStage { metrics in
            design.backdrop(makeContext(metrics))
        } content: { metrics in
            let context = makeContext(metrics)
            ZStack {
                design.timer(context)
                    .frame(width: context.timerRect.width, height: context.timerRect.height)
                    .position(x: context.timerRect.midX, y: context.timerRect.midY)
                    .allowsHitTesting(false)

                pager(context)
            }
        }
        .focusLabChrome(design.chromeScheme(blend: blend))
    }

    private func makeContext(_ metrics: FocusLabStageMetrics) -> FocusLabContext {
        let slots = self.slots
        return FocusLabContext(
            session: session,
            blend: blend,
            metrics: metrics,
            timerRect: CGRect(
                x: 0,
                y: slots.headerHeight,
                width: metrics.safeSize.width,
                height: slots.timerHeight
            )
        )
    }

    private func pager(_ context: FocusLabContext) -> some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            pageLayout(header: design.trackingHeader(context), content: design.trackingBody(context))
        } focus: {
            pageLayout(header: design.focusHeader(context), content: design.focusBody(context))
        }
    }

    private func pageLayout(header: some View, content: some View) -> some View {
        let slots = self.slots
        return VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: slots.headerHeight)
            Color.clear
                .frame(height: slots.timerHeight)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
