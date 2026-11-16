//  TicketDesign.swift
//  studyApp
//
//  DEV ONLY — "Ticket": the session is a paper ticket. Swiping to focus grows it to nearly
//  fill the screen, the timer rides to the middle of its face and the stub swaps its facts
//  for the focus controls. Pausing stamps it.

import SwiftUI

struct TicketDesign: View {

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
            backdrop
        } content: { metrics in
            stageContent(TicketLayout(size: metrics.safeSize, blend: blend))
        }
        .focusLabChrome(blend < 0.5 ? .light : .dark)
    }

    private var backdrop: some View {
        TicketPalette.background(isPaused: session.isPaused, blend: blend)
            .animation(.smooth(duration: 0.45), value: session.isPaused)
    }

    // The paper sits under the pager so the pages' stub content lands on it; the timer,
    // punches and stamp sit above so they never slide with the pages.
    private func stageContent(_ layout: TicketLayout) -> some View {
        ZStack {
            TicketPaper(session: session, layout: layout, blend: blend)
                .allowsHitTesting(false)
            pager(layout)
            TicketPinned(session: session, layout: layout, blend: blend)
                .allowsHitTesting(false)
        }
    }

    private func pager(_ layout: TicketLayout) -> some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            TicketTrackingPage(session: session, layout: layout, blend: blend, page: $page)
        } focus: {
            TicketFocusPage(session: session, layout: layout, blend: blend, page: $page)
        }
    }
}

#Preview {
    TicketDesign(session: FocusLabSession())
}
