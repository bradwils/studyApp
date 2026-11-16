//  DaylightStyle.swift
//  studyApp
//
//  DEV ONLY — palette, type, formatting and the shared pill button for the Daylight design.

import SwiftUI

enum DaylightPalette {
    static let noon = Color(labHex: 0xCBE8F6)
    static let dawn = Color(labHex: 0xFFD9C2)
    static let blush = Color(labHex: 0xF9B4AB)
    static let marigold = Color(labHex: 0xFFAE1F)
    static let apricot = Color(labHex: 0xFFC65A)
    static let glow = Color(labHex: 0xFFE3A3)
    static let plum = Color(labHex: 0x2B2440)
    static let ground = Color(labHex: 0x3A2E5C)
    static let chalk = Color(labHex: 0xF6EFE9)
}

enum DaylightFont {
    static func name(_ size: CGFloat) -> Font {
        Font.custom("AvenirNext-DemiBold", size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        Font.custom("AvenirNext-Medium", size: size)
    }

    static func caption(_ size: CGFloat) -> Font {
        Font.custom("AvenirNext-Regular", size: size)
    }
}

enum DaylightFormat {
    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes: Int = Int(max(interval, 0) / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        if hours == 0 { return "\(minutes) min" }
        if minutes == 0 { return "\(hours) h" }
        return "\(hours) h \(minutes) min"
    }
}

struct DaylightPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct DaylightPill: View {
    let title: String
    let textColor: Color
    var fill: Color?
    var outline: Color?
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var textSize: CGFloat = 17

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DaylightFont.body(textSize))
                .foregroundStyle(textColor)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background { pillBackground }
                .contentShape(Capsule())
        }
        .buttonStyle(DaylightPressStyle())
    }

    @ViewBuilder
    private var pillBackground: some View {
        if let fill {
            Capsule().fill(fill)
        } else if let outline {
            Capsule().strokeBorder(outline, lineWidth: 1.5)
        }
    }
}
