//  TapeDesign.swift
//  studyApp
//
//  DEV ONLY — "Tape": time as a measuring tape. A white tape slides under a fixed needle,
//  study time inked on it; swiping to the focus page zooms it out until the whole focus
//  block fits.

import SwiftUI

struct TapeDesign: FocusLabScreen {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 76

    func backdrop(_ context: FocusLabContext) -> some View {
        TapeBackdrop(context: context, reduceMotion: reduceMotion)
    }

    func timer(_ context: FocusLabContext) -> some View {
        let size: CGFloat = min(timerSize, 88)
        let color: Color = TapePalette.ink.labBlend(TapePalette.tape, FocusLabMath.window(context.blend, 0.4, 0.7))
        return FocusLabClock(session: context.session, idleText: "0:00")
            .font(Font.system(size: size, weight: .semibold).width(.condensed))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
    }

    func trackingHeader(_ context: FocusLabContext) -> some View {
        TapeTrackingHeader(session: context.session)
    }

    func trackingBody(_ context: FocusLabContext) -> some View {
        TapeTrackingBody(session: context.session)
    }

    func focusHeader(_ context: FocusLabContext) -> some View {
        TapeFocusHeader(session: context.session)
    }

    func focusBody(_ context: FocusLabContext) -> some View {
        TapeFocusBody(session: context.session)
    }

    func chromeScheme(blend: CGFloat) -> ColorScheme? {
        blend < 0.5 ? .light : .dark
    }
}

#Preview {
    FocusLabScaffold(session: FocusLabSession(), design: TapeDesign())
}
