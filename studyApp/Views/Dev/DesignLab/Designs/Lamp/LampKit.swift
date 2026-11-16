//  LampKit.swift
//  studyApp
//
//  DEV ONLY — palette, type, geometry and small shared pieces for the Lamp design.

import SwiftUI

enum LampPalette {
    static let night = Color(labHex: 0x15110F)
    static let umber = Color(labHex: 0x2A211C)
    static let lamplight = Color(labHex: 0xFFD9A0)
    static let ember = Color(labHex: 0xFF9D4D)
    static let parchment = Color(labHex: 0xF4E6D0)
    static let ash = Color(labHex: 0x9C8E7E)
}

enum LampLayout {
    static let headerHeight: CGFloat = 76
    static let slotGap: CGFloat = 44
    static let fuseRowHeight: CGFloat = 38
    static let fuseWidth: CGFloat = 200
    static let fuseGap: CGFloat = 18
    static let sidePadding: CGFloat = 24
}

enum LampFont {
    static func regular(_ size: CGFloat) -> Font {
        Font.custom("Optima-Regular", size: size, relativeTo: .body)
    }

    static func bold(_ size: CGFloat) -> Font {
        Font.custom("Optima-Bold", size: size, relativeTo: .body)
    }

    // Fixed size because the caller already scales it with @ScaledMetric, alongside the digit cell width.
    static func timer(_ size: CGFloat) -> Font {
        Font.custom("Optima-Regular", fixedSize: size)
    }
}

struct LampPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct LampPill: View {
    let title: String
    let fill: Color
    let textColor: Color
    var isOutlined: Bool = false

    var body: some View {
        Text(title)
            .font(LampFont.bold(18))
            .foregroundStyle(textColor)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .frame(minHeight: 48)
            .background(fill, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(LampPalette.ember, lineWidth: 1)
                    .opacity(isOutlined ? 1 : 0)
            }
            .contentShape(Capsule())
    }
}
