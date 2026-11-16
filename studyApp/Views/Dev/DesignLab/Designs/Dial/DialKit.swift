//  DialKit.swift
//  studyApp
//
//  DEV ONLY — shared palette, geometry and small helpers for the Dial design.

import SwiftUI

enum DialPalette {
    static let porcelain = Color(labHex: 0xF4F5F7)
    static let cobalt = Color(labHex: 0x1F3FBF)
    static let ink = Color(labHex: 0x141B34)
    static let tick = Color(labHex: 0xA9AEBD)
    static let signal = Color(labHex: 0xFF6B2C)
    static let white = Color(labHex: 0xFFFFFF)
}

enum DialLayout {
    static let headerHeight: CGFloat = 64
    static let slotTop: CGFloat = 16
    static let sidePadding: CGFloat = 24

    static func ringDiameter(width: CGFloat) -> CGFloat {
        min(width - 88, 290)
    }

    static func slotSide(diameter: CGFloat) -> CGFloat {
        diameter + 40
    }

    static func ringCenterY(diameter: CGFloat) -> CGFloat {
        headerHeight + slotTop + slotSide(diameter: diameter) / 2
    }
}

enum DialFont {
    static func text(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        Font.system(size: size, weight: weight)
    }
}

struct DialPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

func dialDuration(_ interval: TimeInterval) -> String {
    let totalMinutes: Int = Int(interval / 60)
    let hours: Int = totalMinutes / 60
    let minutes: Int = totalMinutes % 60
    if hours == 0 { return "\(minutes) min" }
    return "\(hours) h \(minutes) min"
}
