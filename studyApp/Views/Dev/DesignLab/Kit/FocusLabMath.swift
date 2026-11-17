//  FocusLabMath.swift
//  studyApp
//
//  DEV ONLY — small helpers for driving Focus Design Lab visuals off the page blend.

import SwiftUI

// nonisolated so Shape.path(in:) and Animatable code can call these too.
nonisolated enum FocusLabMath {

    static func lerp(_ from: CGFloat, _ to: CGFloat, _ fraction: CGFloat) -> CGFloat {
        from + (to - from) * fraction
    }

    static func clamp(_ value: CGFloat, _ lower: CGFloat = 0, _ upper: CGFloat = 1) -> CGFloat {
        min(max(value, lower), upper)
    }

    /// Remaps `value` from `start...end` onto 0...1, clamped. Use it to make one part of
    /// a swipe finish early or start late: `window(blend, 0.5, 1)` only moves in the second half.
    static func window(_ value: CGFloat, _ start: CGFloat, _ end: CGFloat) -> CGFloat {
        guard end > start else { return value >= end ? 1 : 0 }
        return clamp((value - start) / (end - start))
    }

    static func smoothstep(_ value: CGFloat) -> CGFloat {
        let clamped = clamp(value)
        return clamped * clamped * (3 - 2 * clamped)
    }
}

nonisolated extension Color {

    /// `Color(labHex: 0x1F6F78)`
    init(labHex hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    func labBlend(_ other: Color, _ fraction: CGFloat) -> Color {
        mix(with: other, by: Double(FocusLabMath.clamp(fraction)))
    }
}
