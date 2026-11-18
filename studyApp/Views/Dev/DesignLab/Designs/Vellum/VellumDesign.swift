//  VellumDesign.swift
//  studyApp
//
//  DEV ONLY — "Vellum": five sheets of coloured tracing paper. Fanned behind the controls while
//  tracking, they slide up one after another into a single tile behind the timer, then rotate
//  apart into a rosette as the focus block runs.

import SwiftUI

struct VellumDesign: FocusLabScreen {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 80

    init(session: FocusLabSession) {
        self.session = session
    }

    // Tall enough for the stacked tile to sit in the timer slot without touching the header.
    func slots(standard: FocusPagerSlots) -> FocusPagerSlots {
        FocusPagerSlots(headerHeight: standard.headerHeight, timerHeight: 250)
    }

    func backdrop(_ context: FocusPagerContext) -> some View {
        VellumBackdrop(session: session, layout: VellumLayout(context: context), blend: context.blend)
    }

    func timer(_ context: FocusPagerContext) -> some View {
        let flip: CGFloat = FocusLabMath.window(context.blend, 0.55, 0.85)
        return FocusLabClock(session: session, idleText: "0:00")
            .font(Font.system(size: timerSize, weight: .medium, design: .rounded))
            .foregroundStyle(VellumPalette.ink.labBlend(VellumPalette.white, flip))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: 220)
    }

    func header(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            VellumTrackingHeader(session: session)
        case .focus:
            VellumFocusHeader(session: session)
        }
    }

    func content(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            VellumTrackingPage(session: session, layout: VellumLayout(context: context))
        case .focus:
            VellumFocusPage(
                session: session,
                blend: context.blend,
                isLocked: context.isLocked,
                onLockChange: context.setLocked
            )
        }
    }
}

#Preview {
    FocusLabHost(design: .vellum)
}
