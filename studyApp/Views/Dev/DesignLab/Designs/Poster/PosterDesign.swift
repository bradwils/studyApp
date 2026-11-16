//  PosterDesign.swift
//  studyApp
//
//  DEV ONLY — "Poster": one flat field of colour and one set of numerals. Swiping to the
//  focus page makes the timer itself travel and grow to span the screen; during a focus
//  block it fills with orange from the bottom.

import SwiftUI

struct PosterDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { _ in
            PosterPalette.pistachio
        } content: { metrics in
            stageContent(PosterLayout(size: metrics.safeSize))
        }
        .focusLabChrome(.light)
    }

    private func stageContent(_ layout: PosterLayout) -> some View {
        ZStack {
            pager(layout)
            PosterNumerals(session: session, layout: layout, blend: blend)
                .allowsHitTesting(false)
        }
    }

    private func pager(_ layout: PosterLayout) -> some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            PosterTrackingPage(session: session, layout: layout, blend: blend)
        } focus: {
            PosterFocusPage(session: session, layout: layout, blend: blend)
        }
    }
}

#Preview {
    PosterDesign(session: FocusLabSession())
}
