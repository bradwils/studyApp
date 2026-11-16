//  DialDesign.swift
//  studyApp
//
//  DEV ONLY — "Dial": a watch face. One ring around the timer never leaves the screen;
//  swiping turns its hairline hour dial into a bold focus-block band on a cobalt face.

import SwiftUI

struct DialDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { metrics in
            backdrop(metrics)
        } content: { metrics in
            pager(metrics)
        }
        .focusLabChrome(blend < 0.5 ? .light : .dark)
    }

    // MARK: - Pager

    private func pager(_ metrics: FocusLabStageMetrics) -> some View {
        let diameter: CGFloat = DialLayout.ringDiameter(width: metrics.safeSize.width)
        return FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            DialTrackingPage(session: session, ringDiameter: diameter)
        } focus: {
            DialFocusPage(session: session, ringDiameter: diameter)
        }
    }

    // MARK: - Backdrop

    private func backdrop(_ metrics: FocusLabStageMetrics) -> some View {
        let full: CGSize = metrics.fullSize
        let diameter: CGFloat = DialLayout.ringDiameter(width: metrics.safeSize.width)
        let centerX: CGFloat = metrics.backdropX(metrics.safeSize.width / 2)
        let centerY: CGFloat = metrics.backdropY(DialLayout.ringCenterY(diameter: diameter))
        let face: Color = DialPalette.porcelain.labBlend(DialPalette.cobalt, blend)
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(face)
            ringLayer(diameter: diameter)
                .position(x: centerX, y: centerY)
            DialCenter(session: session, blend: blend, diameter: diameter)
                .position(x: centerX, y: centerY)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private func ringLayer(diameter: CGFloat) -> some View {
        let tickAnimation: Animation? = reduceMotion ? nil : .linear(duration: 1)
        return TimelineView(.periodic(from: .now, by: 1)) { context in
            let hour: CGFloat = hourFraction(at: context.date)
            let block: CGFloat = CGFloat(session.focusProgress(at: context.date) ?? 0)
            let fraction: CGFloat = FocusLabMath.lerp(hour, block, blend)
            let driver: Double = Double(hour + block)
            DialRing(diameter: diameter, blend: blend, fraction: fraction, hasSession: session.hasSession)
                .animation(tickAnimation, value: driver)
        }
    }

    private func hourFraction(at date: Date) -> CGFloat {
        guard session.hasSession else { return 0 }
        let elapsed: TimeInterval = session.studyElapsed(at: date)
        let remainder: Double = elapsed.truncatingRemainder(dividingBy: 3600)
        return CGFloat(remainder / 3600)
    }
}

#Preview {
    DialDesign(session: FocusLabSession())
}
