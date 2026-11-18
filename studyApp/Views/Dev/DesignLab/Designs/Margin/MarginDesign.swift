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

    func header(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            MarginTrackingHeader(session: session)
        case .focus:
            MarginFocusHeader(session: session)
        }
    }

    func content(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            MarginTrackingPage(session: session)
        case .focus:
            MarginFocusPage(session: session, isLocked: context.isLocked, onLockChange: context.setLocked)
        }
    }
}

#Preview {
    FocusLabHost(design: .margin)
}
