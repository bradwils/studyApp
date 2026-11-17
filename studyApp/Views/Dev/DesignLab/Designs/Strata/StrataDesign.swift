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

    func trackingHeader(_ context: FocusPagerContext) -> some View {
        StrataTrackingHeader(session: session)
    }

    func trackingBody(_ context: FocusPagerContext) -> some View {
        StrataTrackingPage(session: session)
    }

    func focusHeader(_ context: FocusPagerContext) -> some View {
        StrataFocusHeader(session: session)
    }

    func focusBody(_ context: FocusPagerContext) -> some View {
        StrataFocusPage(session: session)
    }
}

#Preview {
    FocusPagerScaffold(screen: StrataDesign(session: FocusLabSession()))
}
