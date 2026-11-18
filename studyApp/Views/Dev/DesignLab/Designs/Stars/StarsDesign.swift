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

    func header(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            StarsTrackingHeader(session: session)
        case .focus:
            StarsFocusHeader(session: session)
        }
    }

    func content(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            StarsTrackingPage(session: session)
        case .focus:
            StarsFocusPage(session: session, isLocked: context.isLocked, onLockChange: context.setLocked)
        }
    }
}

#Preview {
    FocusLabHost(design: .stars)
}
