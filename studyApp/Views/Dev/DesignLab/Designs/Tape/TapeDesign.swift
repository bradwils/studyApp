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

    func header(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            TapeTrackingHeader(session: session)
        case .focus:
            TapeFocusHeader(session: session)
        }
    }

    func content(for page: FocusPage, _ context: FocusPagerContext) -> some View {
        switch page {
        case .tracking:
            TapeTrackingPage(session: session)
        case .focus:
            TapeFocusPage(session: session, isLocked: context.isLocked, onLockChange: context.setLocked)
        }
    }
}

#Preview {
    FocusLabHost(design: .tape)
}
