//  DaylightDesign.swift
//  studyApp
//
//  DEV ONLY — "Daylight": a study day as the sun crossing the sky. One sun is shared by both
//  pages: a small marker on the day's arc while tracking, a large disc rising behind the timer
//  as a focus block progresses.

import SwiftUI

struct DaylightDesign: FocusLabScreen {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 84

    init(session: FocusLabSession) {
        self.session = session
    }

    func backdrop(_ context: FocusPagerContext) -> some View {
        DaylightBackdrop(session: session, geometry: DaylightGeometry(context: context), blend: context.blend)
    }

    func timer(_ context: FocusPagerContext) -> some View {
        FocusLabClock(session: session, idleText: "0:00", digitWidth: timerSize * 0.6)
            .font(Font.custom("AvenirNext-Medium", size: 84, relativeTo: .largeTitle))
            .foregroundStyle(DaylightPalette.plum)
    }

    func trackingHeader(_ context: FocusPagerContext) -> some View {
        DaylightTrackingHeader(session: session)
    }

    func trackingBody(_ context: FocusPagerContext) -> some View {
        DaylightTrackingPage(session: session)
    }

    func focusHeader(_ context: FocusPagerContext) -> some View {
        DaylightFocusHeader(session: session)
    }

    func focusBody(_ context: FocusPagerContext) -> some View {
        DaylightFocusPage(session: session, geometry: DaylightGeometry(context: context))
    }
}

#Preview {
    FocusPagerScaffold(screen: DaylightDesign(session: FocusLabSession()))
}
