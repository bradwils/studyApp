//  VellumDesign.swift
//  studyApp
//
//  DEV ONLY — "Vellum": five sheets of coloured tracing paper. Fanned behind the controls while
//  tracking, they slide up one after another into a single tile behind the timer, then rotate
//  apart into a rosette as the focus block runs.

import SwiftUI

struct VellumDesign: FocusLabScreen {

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80

    // Tall enough for the stacked tile to sit in the timer slot without touching the header.
    func slots(standard: FocusLabSlots) -> FocusLabSlots {
        FocusLabSlots(headerHeight: standard.headerHeight, timerHeight: 250)
    }

    func backdrop(_ context: FocusLabContext) -> some View {
        VellumBackdrop(session: context.session, layout: VellumLayout(context: context), blend: context.blend)
    }

    func timer(_ context: FocusLabContext) -> some View {
        let flip: CGFloat = FocusLabMath.window(context.blend, 0.55, 0.85)
        return FocusLabClock(session: context.session, idleText: "0:00")
            .font(Font.system(size: timerSize, weight: .medium, design: .rounded))
            .foregroundStyle(VellumPalette.ink.labBlend(VellumPalette.white, flip))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: 220)
    }

    func trackingHeader(_ context: FocusLabContext) -> some View {
        VellumTrackingPage(session: context.session, layout: VellumLayout(context: context)).header
    }

    func trackingBody(_ context: FocusLabContext) -> some View {
        VellumTrackingPage(session: context.session, layout: VellumLayout(context: context)).content
    }

    func focusHeader(_ context: FocusLabContext) -> some View {
        VellumFocusPage(session: context.session, blend: context.blend).header
    }

    func focusBody(_ context: FocusLabContext) -> some View {
        VellumFocusPage(session: context.session, blend: context.blend).content
    }
}

#Preview {
    FocusLabScaffold(session: FocusLabSession(), design: VellumDesign())
}
