//  DeckDesign.swift
//  studyApp
//
//  DEV ONLY — "Deck": three stacked panels (now playing, timer, leaderboard) in soft rose
//  and wine. Swiping to focus slides the outer two off the top and bottom while the timer
//  panel grows to fill the screen and deepens to wine.

import SwiftUI

struct DeckDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    private var chromeScheme: ColorScheme {
        blend < 0.5 ? ColorScheme.light : ColorScheme.dark
    }

    var body: some View {
        FocusLabStage { metrics in
            DeckBackdrop(session: session, layout: makeLayout(metrics))
        } content: { metrics in
            stageContent(makeLayout(metrics))
        }
        .focusLabChrome(chromeScheme)
    }

    private func makeLayout(_ metrics: FocusLabStageMetrics) -> DeckLayout {
        DeckLayout(size: metrics.safeSize, insets: metrics.insets, blend: blend)
    }

    private func stageContent(_ layout: DeckLayout) -> some View {
        ZStack {
            pager(layout)
            DeckPinned(session: session, layout: layout)
        }
    }

    // Clipping is off so the sheet's fill can run on under the lab bar.
    private func pager(_ layout: DeckLayout) -> some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            DeckTrackingPage(session: session, layout: layout)
        } focus: {
            DeckFocusPage(session: session, layout: layout)
        }
        .scrollClipDisabled()
    }
}

#Preview {
    DeckDesign(session: FocusLabSession())
}
