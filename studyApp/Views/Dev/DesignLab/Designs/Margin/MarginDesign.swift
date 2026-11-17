//  MarginDesign.swift
//  studyApp
//
//  DEV ONLY — "Margin": a notebook page with one fixed margin rule. A highlighter
//  stroke grows behind the timer; the focus page is an ink panel wiping in from the right.

import SwiftUI

struct MarginDesign: FocusLabScreen {

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 92

    func chromeScheme(blend: CGFloat) -> ColorScheme? {
        blend < 0.5 ? .light : .dark
    }

    func backdrop(_ context: FocusLabContext) -> some View {
        MarginBackdrop(context: context, timerSize: timerSize)
    }

    // The timer has to change colour exactly at the ink edge, so it is drawn twice in the backdrop.
    func timer(_ context: FocusLabContext) -> some View {
        EmptyView()
    }

    func trackingHeader(_ context: FocusLabContext) -> some View {
        MarginTrackingHeader(session: context.session)
    }

    func trackingBody(_ context: FocusLabContext) -> some View {
        MarginTrackingPage(session: context.session)
    }

    func focusHeader(_ context: FocusLabContext) -> some View {
        MarginFocusHeader(session: context.session)
    }

    func focusBody(_ context: FocusLabContext) -> some View {
        MarginFocusPage(session: context.session)
    }
}

#Preview {
    FocusLabScaffold(session: FocusLabSession(), design: MarginDesign())
}
