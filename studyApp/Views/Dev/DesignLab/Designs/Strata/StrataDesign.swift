//  StrataDesign.swift
//  studyApp
//
//  DEV ONLY — "Strata": the session settles like sediment, one flat band per stretch of
//  study. The focus page zooms into the band being laid right now.

import SwiftUI

struct StrataDesign: FocusLabScreen {

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80

    func backdrop(_ context: FocusLabContext) -> some View {
        StrataBackdrop(session: context.session, blend: context.blend, metrics: context.metrics)
    }

    func timer(_ context: FocusLabContext) -> some View {
        FocusLabClock(session: context.session, idleText: "0:00", digitWidth: timerSize * 0.56)
            .font(Font.custom("DINAlternate-Bold", size: 80, relativeTo: .largeTitle))
            .foregroundStyle(StrataPalette.ink)
            .padding(.leading, StrataLayout.contentX)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func trackingHeader(_ context: FocusLabContext) -> some View {
        StrataTrackingHeader(session: context.session)
    }

    func trackingBody(_ context: FocusLabContext) -> some View {
        StrataTrackingPage(session: context.session)
    }

    func focusHeader(_ context: FocusLabContext) -> some View {
        StrataFocusHeader(session: context.session)
    }

    func focusBody(_ context: FocusLabContext) -> some View {
        StrataFocusPage(session: context.session)
    }
}

#Preview {
    FocusLabScaffold(session: FocusLabSession(), design: StrataDesign())
}
