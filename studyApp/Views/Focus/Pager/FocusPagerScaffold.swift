//  FocusPagerScaffold.swift
//  studyApp
//
//  Renders any FocusPagerScreen with FocusSessionScreen's structure: a two-page pager over
//  a pinned timer, each page a header band, then the timer gap, then its body. The backdrop
//  and the pager run full width; the pages' content and the timer share one centred column.

import SwiftUI

/// A view that renders a focus screen as a two-page pager over a pinned timer.
///
/// ## Declaration
///
/// ```swift
/// struct FocusPagerScaffold<Screen: FocusPagerScreen>: View
/// ```
///
/// The backdrop and the swipe area span the full width. Each page's header, timer gap and body,
/// and the timer itself, share one column capped at `FocusPagerLayout.maxContentWidth` and centred.
///
/// ```swift
/// FocusPagerScaffold(screen: MyScreen(vm: vm))
/// ```
struct FocusPagerScaffold<Screen: FocusPagerScreen>: View {

    let screen: Screen

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
    private var slots: FocusPagerSlots {
        screen.slots(standard: FocusPagerSlots(
            headerHeight: FocusPagerLayout.headerSlotHeight,
            timerHeight: standardTimerHeight
        ))
    }

    var body: some View {
        FocusPagerStage { metrics in
            screen.backdrop(makeContext(metrics))
        } content: { metrics in
            let context = makeContext(metrics)
            ZStack {
                screen.timer(context)
                    .frame(width: context.timerRect.width, height: context.timerRect.height)
                    .position(x: context.timerRect.midX, y: context.timerRect.midY)
                    .allowsHitTesting(false)

                pager(context)
            }
        }
    }

    private func makeContext(_ metrics: FocusPagerStageMetrics) -> FocusPagerContext {
        let slots = self.slots
        let column = metrics.contentRect
        return FocusPagerContext(
            blend: blend,
            metrics: metrics,
            timerRect: CGRect(
                x: column.minX,
                y: slots.headerHeight,
                width: column.width,
                height: slots.timerHeight
            )
        )
    }

    private func pager(_ context: FocusPagerContext) -> some View {
        FocusPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: screen.showsFocusPage,
            isLocked: screen.isLocked
        ) {
            pageLayout(header: screen.trackingHeader(context), content: screen.trackingBody(context))
        } focus: {
            pageLayout(header: screen.focusHeader(context), content: screen.focusBody(context))
        }
    }

    // The pager centres this inside its full-width page, so it lands on the same column as the timer.
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
        .frame(maxWidth: FocusPagerLayout.maxContentWidth)
    }
}
