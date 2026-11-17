//  StarsDesign.swift
//  studyApp
//
//  DEV ONLY — "Stars": a night sky you fill in yourself. Every five minutes of study lights
//  a star; swiping to the focus page turns the whole sky behind a figure that is drawn
//  line by line as the block runs. Pausing lets dawn in.

import SwiftUI

struct StarsDesign: FocusLabScreen {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80

    init(session: FocusLabSession) {
        self.session = session
    }

    func backdrop(_ context: FocusPagerContext) -> some View {
        StarsBackdrop(session: session, context: context)
    }

    func timer(_ context: FocusPagerContext) -> some View {
        FocusLabClock(session: session, idleText: "0:00", digitWidth: timerSize * 0.56)
            .font(StarsFont.timer(timerSize))
            .foregroundStyle(StarsPalette.star)
            .lineLimit(1)
    }

    func trackingHeader(_ context: FocusPagerContext) -> some View {
        StarsTrackingHeader(session: session)
    }

    func trackingBody(_ context: FocusPagerContext) -> some View {
        StarsTrackingPage(session: session)
    }

    func focusHeader(_ context: FocusPagerContext) -> some View {
        StarsFocusHeader(session: session)
    }

    func focusBody(_ context: FocusPagerContext) -> some View {
        StarsFocusPage(session: session)
    }
}

#Preview {
    FocusPagerScaffold(screen: StarsDesign(session: FocusLabSession()))
}
