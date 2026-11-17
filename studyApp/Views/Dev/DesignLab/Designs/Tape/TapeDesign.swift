//  TapeDesign.swift
//  studyApp
//
//  DEV ONLY — "Tape": time as a measuring tape. A white tape slides under a fixed needle,
//  study time inked on it; swiping to the focus page zooms it out until the whole focus
//  block fits.

import SwiftUI

struct TapeDesign: FocusLabScreen {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 76

    init(session: FocusLabSession) {
        self.session = session
    }

    func backdrop(_ context: FocusPagerContext) -> some View {
        TapeBackdrop(session: session, context: context, reduceMotion: reduceMotion)
            .focusLabChrome(context.blend < 0.5 ? .light : .dark)
    }

    func timer(_ context: FocusPagerContext) -> some View {
        let size: CGFloat = min(timerSize, 88)
        let color: Color = TapePalette.ink.labBlend(TapePalette.tape, FocusLabMath.window(context.blend, 0.4, 0.7))
        return FocusLabClock(session: session, idleText: "0:00")
            .font(Font.system(size: size, weight: .semibold).width(.condensed))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
    }

    func trackingHeader(_ context: FocusPagerContext) -> some View {
        TapeTrackingHeader(session: session)
    }

    func trackingBody(_ context: FocusPagerContext) -> some View {
        TapeTrackingPage(session: session)
    }

    func focusHeader(_ context: FocusPagerContext) -> some View {
        TapeFocusHeader(session: session)
    }

    func focusBody(_ context: FocusPagerContext) -> some View {
        TapeFocusPage(session: session)
    }
}

#Preview {
    FocusPagerScaffold(screen: TapeDesign(session: FocusLabSession()))
}
