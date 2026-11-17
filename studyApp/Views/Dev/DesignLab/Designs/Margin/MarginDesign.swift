//  MarginDesign.swift
//  studyApp
//
//  DEV ONLY — "Margin": a notebook page with one fixed margin rule. A highlighter
//  stroke grows behind the timer; the focus page is an ink panel wiping in from the right.

import SwiftUI

struct MarginDesign: FocusLabScreen {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 92

    init(session: FocusLabSession) {
        self.session = session
    }

    func backdrop(_ context: FocusPagerContext) -> some View {
        MarginBackdrop(session: session, context: context, timerSize: timerSize)
            .focusLabChrome(context.blend < 0.5 ? .light : .dark)
    }

    // The timer has to change colour exactly at the ink edge, so it is drawn twice in the backdrop.
    func timer(_ context: FocusPagerContext) -> some View {
        EmptyView()
    }

    func trackingHeader(_ context: FocusPagerContext) -> some View {
        MarginTrackingHeader(session: session)
    }

    func trackingBody(_ context: FocusPagerContext) -> some View {
        MarginTrackingPage(session: session)
    }

    func focusHeader(_ context: FocusPagerContext) -> some View {
        MarginFocusHeader(session: session)
    }

    func focusBody(_ context: FocusPagerContext) -> some View {
        MarginFocusPage(session: session)
    }
}

#Preview {
    FocusPagerScaffold(screen: MarginDesign(session: FocusLabSession()))
}
