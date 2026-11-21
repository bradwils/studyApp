//  StrataDesign.swift
//  studyApp
//
//  DEV ONLY — "Strata": the session settles like sediment, one flat band per stretch of
//  study. The focus page zooms into the band being laid right now.

import SwiftUI

struct StrataDesign: FocusLabScreen {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80

    init(session: FocusLabSession) {
        self.session = session
    }

    func backdrop(_ context: FocusPagerContext) -> some View {
        StrataBackdrop(session: session, blend: context.blend, metrics: context.metrics)
    }

    func timer(_ context: FocusPagerContext) -> some View {
        FocusLabClock(session: session, idleText: "0:00", digitWidth: timerSize * 0.56)
            .font(Font.custom("DINAlternate-Bold", size: 80, relativeTo: .largeTitle))
            .foregroundStyle(StrataPalette.ink)
            .padding(.leading, StrataLayout.contentX)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func header(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            StrataTrackingHeader(session: session)
        case .focus:
            StrataFocusHeader(session: session)
        }
    }

    func content(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            StrataTrackingPage(session: session)
        case .focus:
            StrataFocusPage(session: session, isLocked: context.isLocked, onLockChange: context.setLocked)
        }
    }
}

#Preview {
    FocusLabHost(design: .strata)
}
