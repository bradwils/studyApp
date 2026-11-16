//  StarsDesign.swift
//  studyApp
//
//  DEV ONLY — "Stars": a night sky you fill in yourself. Every five minutes of study lights
//  a star; swiping to the focus page turns the whole sky behind a figure that is drawn
//  line by line as the block runs. Pausing lets dawn in.

import SwiftUI

struct StarsDesign: FocusLabScreen {

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80

    func backdrop(_ context: FocusLabContext) -> some View {
        StarsBackdrop(context: context)
    }

    func timer(_ context: FocusLabContext) -> some View {
        FocusLabClock(session: context.session, idleText: "0:00", digitWidth: timerSize * 0.56)
            .font(StarsFont.timer(timerSize))
            .foregroundStyle(StarsPalette.star)
            .lineLimit(1)
    }

    func trackingHeader(_ context: FocusLabContext) -> some View {
        StarsTrackingHeader(session: context.session)
    }

    func trackingBody(_ context: FocusLabContext) -> some View {
        StarsTrackingPage(session: context.session)
    }

    func focusHeader(_ context: FocusLabContext) -> some View {
        StarsFocusHeader(session: context.session)
    }

    func focusBody(_ context: FocusLabContext) -> some View {
        StarsFocusPage(session: context.session)
    }
}

#Preview {
    FocusLabScaffold(session: FocusLabSession(), design: StarsDesign())
}
