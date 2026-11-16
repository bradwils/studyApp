//  DeckKit.swift
//  studyApp
//
//  DEV ONLY — shared palette, formatting, button style and the one layout struct that
//  owns every number in Deck. The backdrop, the pinned layer and both pages read from it.

import SwiftUI

enum DeckPalette {

    static let rosewater = Color(labHex: 0xF5DDE0)
    static let petal = Color(labHex: 0xFFF7F6)
    static let wine = Color(labHex: 0x4A1128)
    static let mulberry = Color(labHex: 0x8A4A63)
    static let lime = Color(labHex: 0xC7E86B)
    static let butter = Color(labHex: 0xFFE9A6)
}

enum DeckFormat {

    static func hoursMinutes(_ interval: TimeInterval) -> String {
        let total: Int = Int(interval / 60)
        let hours: Int = total / 60
        let mins: Int = total % 60
        if hours == 0 { return "\(mins) min" }
        return "\(hours) h \(mins) min"
    }

    static func savedMinutes(_ length: TimeInterval) -> Int {
        max(1, Int((length / 60).rounded()))
    }
}

struct DeckPressStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct DeckLayout {

    let size: CGSize
    let insets: EdgeInsets
    let blend: CGFloat

    static let sideInset: CGFloat = 14
    static let stripTop: CGFloat = 8
    static let stripHeight: CGFloat = 64
    static let stripRadius: CGFloat = 22
    static let stripLineY: CGFloat = 78
    static let panelTop: CGFloat = 84
    static let panelRadius: CGFloat = 34
    static let sheetGap: CGFloat = 12
    static let sheetRadius: CGFloat = 30
    static let sheetOpenLift: CGFloat = 150
    static let sheetContentHeight: CGFloat = 220

    var ease: CGFloat {
        FocusLabMath.smoothstep(blend)
    }

    var trackingPanel: CGRect {
        let side: CGFloat = DeckLayout.sideInset
        let width: CGFloat = max(size.width - side * 2, 0)
        let height: CGFloat = size.height * 0.44
        return CGRect(x: side, y: DeckLayout.panelTop, width: width, height: height)
    }

    var focusPanel: CGRect {
        CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }

    var shownPanel: CGRect {
        let small: CGRect = trackingPanel
        let full: CGRect = focusPanel
        let eased: CGFloat = ease
        let left: CGFloat = FocusLabMath.lerp(small.minX, full.minX, eased)
        let top: CGFloat = FocusLabMath.lerp(small.minY, full.minY, eased)
        let wide: CGFloat = FocusLabMath.lerp(small.width, full.width, eased)
        let tall: CGFloat = FocusLabMath.lerp(small.height, full.height, eased)
        return CGRect(x: left, y: top, width: wide, height: tall)
    }

    var shownRadius: CGFloat {
        FocusLabMath.lerp(DeckLayout.panelRadius, 0, ease)
    }

    // Backdrop coordinates, grown outward by the safe-area insets so that at e = 1 it covers everything.
    var backdropPanel: CGRect {
        let shown: CGRect = shownPanel
        let eased: CGFloat = ease
        let left: CGFloat = shown.minX + insets.leading - eased * insets.leading
        let top: CGFloat = shown.minY + insets.top - eased * insets.top
        let right: CGFloat = shown.maxX + insets.leading + eased * insets.trailing
        let bottom: CGFloat = shown.maxY + insets.top + eased * insets.bottom
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    var timerCenter: CGPoint {
        let shown: CGRect = shownPanel
        let centerY: CGFloat = shown.minY + shown.height * 0.40
        return CGPoint(x: shown.midX, y: centerY)
    }

    var timerScale: CGFloat {
        FocusLabMath.lerp(1, 1.15, ease)
    }

    var stripOffset: CGFloat {
        -ease * 110
    }

    var sheetTop: CGFloat {
        DeckLayout.panelTop + size.height * 0.44 + DeckLayout.sheetGap
    }

    var sheetOffset: CGFloat {
        ease * (size.height * 0.6)
    }

    var sheetWidth: CGFloat {
        max(size.width - DeckLayout.sideInset * 2, 0)
    }

    // The sheet's fill reaches well below the page so it still covers the lab bar area when lifted.
    var sheetFillHeight: CGFloat {
        max(size.height - sheetTop, 0) + 400
    }
}
