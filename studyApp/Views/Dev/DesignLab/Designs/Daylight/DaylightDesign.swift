//  DaylightDesign.swift
//  studyApp
//
//  DEV ONLY — "Daylight": a study day as the sun crossing the sky. One sun is shared by both
//  pages: a small marker on the day's arc while tracking, a large disc rising behind the timer
//  as a focus block progresses.

import SwiftUI

struct DaylightDesign: FocusLabScreen {

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 84

    func backdrop(_ context: FocusLabContext) -> some View {
        DaylightBackdrop(session: context.session, geometry: DaylightGeometry(context: context), blend: context.blend)
    }

    func timer(_ context: FocusLabContext) -> some View {
        FocusLabClock(session: context.session, idleText: "0:00", digitWidth: timerSize * 0.6)
            .font(Font.custom("AvenirNext-Medium", size: 84, relativeTo: .largeTitle))
            .foregroundStyle(DaylightPalette.plum)
    }

    func trackingHeader(_ context: FocusLabContext) -> some View {
        DaylightTrackingHeader(session: context.session)
    }

    func trackingBody(_ context: FocusLabContext) -> some View {
        DaylightTrackingPage(session: context.session)
    }

    func focusHeader(_ context: FocusLabContext) -> some View {
        DaylightFocusHeader(session: context.session)
    }

    func focusBody(_ context: FocusLabContext) -> some View {
        DaylightFocusPage(session: context.session, geometry: DaylightGeometry(context: context))
    }
}

#Preview {
    FocusLabScaffold(session: FocusLabSession(), design: DaylightDesign())
}
