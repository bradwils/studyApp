//  StarsDesign.swift
//  studyApp
//
//  DEV ONLY — "Stars": a night sky you fill in yourself. Every five minutes of study lights
//  a star; swiping to the focus page turns the whole sky behind a figure that is drawn
//  line by line as the block runs. Pausing lets dawn in.

import SwiftUI

struct StarsDesign: View {

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
            StarsBackdrop(
                session: session,
                metrics: metrics,
                blend: blend,
                timerSize: timerSize
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
            StarsTrackingPage(session: session)
        } focus: {
            StarsFocusPage(session: session)
        }
    }
}

#Preview {
    StarsDesign(session: FocusLabSession())
}
