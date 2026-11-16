//  PosterNumerals.swift
//  studyApp
//
//  DEV ONLY — Poster's pinned timer: rendered at the large size, scaled down on the
//  tracking page, filling with orange from the bottom during a focus block.

import SwiftUI

struct PosterNumerals: View {

    let session: FocusLabSession
    let layout: PosterLayout
    let blend: CGFloat

    var body: some View {
        let eased: CGFloat = FocusLabMath.smoothstep(blend)
        let scale: CGFloat = FocusLabMath.lerp(PosterLayout.smallScale, 1, eased)
        let top: CGFloat = FocusLabMath.lerp(PosterLayout.trackingTop, layout.focusTop, eased)
        return TimelineView(.periodic(from: .now, by: 1)) { context in
            let progress: CGFloat = CGFloat(session.focusProgress(at: context.date) ?? 0)
            PosterNumeralStack(session: session, layout: layout, progress: progress, blend: blend)
        }
        .scaleEffect(scale, anchor: .topLeading)
        .padding(.top, top)
        .padding(.leading, PosterLayout.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct PosterNumeralStack: View {

    let session: FocusLabSession
    let layout: PosterLayout
    let progress: CGFloat
    let blend: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let fill: CGFloat = progress * blend
        // The glyphs only occupy the middle ~70% of their box (cap height), so map the fill
        // onto that span; otherwise the first and last sixth of a block would show no change.
        let glyphFill: CGFloat = 0.145 + 0.705 * fill
        let maskHeight: CGFloat = fill > 0 ? layout.bigSize * glyphFill : 0
        let fillAnimation: Animation? = reduceMotion ? nil : Animation.linear(duration: 1)
        return ZStack(alignment: .topLeading) {
            clock(PosterPalette.forest)
            clock(PosterPalette.tangerine)
                .accessibilityHidden(true)
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(height: maskHeight)
                        .animation(fillAnimation, value: progress)
                }
        }
    }

    private func clock(_ color: Color) -> some View {
        let boxWidth: CGFloat = layout.width - 2 * PosterLayout.margin
        return FocusLabClock(session: session, idleText: "00:00")
            .font(PosterFont.heavy(layout.bigSize))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(width: boxWidth, height: layout.bigSize, alignment: .leading)
    }
}
