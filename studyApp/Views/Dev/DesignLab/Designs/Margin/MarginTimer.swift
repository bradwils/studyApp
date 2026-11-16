//  MarginTimer.swift
//  studyApp
//
//  DEV ONLY — the timer and its highlighter stroke. The design draws two of these in
//  the same full-size frame, so they register pixel for pixel; a mask shows each one.

import SwiftUI

struct MarginTimer: View {

    let session: FocusLabSession
    let onInk: Bool
    let fraction: Double
    let animates: Bool
    let size: CGFloat
    let slotHeight: CGFloat
    let top: CGFloat
    let leading: CGFloat
    let full: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: top)
            digits
                .frame(height: slotHeight)
            Spacer(minLength: 0)
        }
        .padding(.leading, leading)
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    // The stroke is a background so it can never change where the digits sit.
    private var digits: some View {
        FocusLabClock(session: session, idleText: "0:00")
            .font(MarginFont.serif(size, .regular))
            .foregroundStyle(onInk ? MarginPalette.paper : MarginPalette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .background(alignment: .leading) { stroke }
    }

    private var stroke: some View {
        let strokeWidth: CGFloat = size * 2.9 * CGFloat(fraction)
        let strokeHeight: CGFloat = onInk ? 5 : size * 0.42
        let drop: CGFloat = onInk ? size * 0.46 : size * 0.14
        let alpha: Double = onInk ? 0.9 : 1
        let animation: Animation? = animates ? Animation.linear(duration: 1) : nil
        return RoundedRectangle(cornerRadius: 3)
            .fill(MarginPalette.highlighter)
            .opacity(alpha)
            .frame(width: strokeWidth, height: strokeHeight)
            .animation(animation, value: fraction)
            .offset(x: -6, y: drop)
    }
}
