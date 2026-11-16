//  TideDesign.swift
//  studyApp
//
//  DEV ONLY — "Tide": time is a water level. One waterline crosses the screen, and the
//  fixed timer changes colour exactly where the water covers it.

import SwiftUI

struct TideDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 88
    @ScaledMetric(relativeTo: .largeTitle) private var timerSlotHeight: CGFloat = 120
    @ScaledMetric(relativeTo: .footnote) private var captionSize: CGFloat = 14

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { metrics in
            TideBackdrop(
                session: session,
                metrics: metrics,
                blend: blend,
                reduceMotion: reduceMotion,
                timerSize: timerSize,
                timerSlotHeight: timerSlotHeight,
                captionSize: captionSize
            )
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
            TideTrackingPage(session: session, timerSlotHeight: timerSlotHeight)
        } focus: {
            TideFocusPage(session: session, timerSlotHeight: timerSlotHeight)
        }
    }
}

#Preview {
    TideDesign(session: FocusLabSession())
}
