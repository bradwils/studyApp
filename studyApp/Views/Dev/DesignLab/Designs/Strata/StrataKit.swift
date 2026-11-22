//  StrataKit.swift
//  studyApp
//
//  DEV ONLY — palette, geometry, fonts and small shared pieces for the Strata design.

import SwiftUI

enum StrataPalette {
    static let haze = Color(labHex: 0xE8E6F0)
    static let ink = Color(labHex: 0x23212B)
    static let smoke = Color(labHex: 0x77748A)
    static let seam = Color(labHex: 0xF7F3E8)
    static let moss = Color(labHex: 0x7C9A6D)
    static let ochre = Color(labHex: 0xD9A441)
    static let rosewood = Color(labHex: 0xB5606E)
    static let harbour = Color(labHex: 0x5F7FA3)
    static let plum = Color(labHex: 0x7A5C8E)

    static let studyColors: [Color] = [moss, ochre, rosewood, harbour, plum]

    // Seam text on Moss and Ochre is under 3:1, so those two take Ink instead.
    static let studyLabelColors: [Color] = [ink, ink, seam, seam, seam]
}

enum StrataLayout {
    static let contentX: CGFloat = 24
}

enum StrataFont {
    static func sans(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        Font.system(size: size, weight: weight, design: .default)
    }
}

enum StrataFormat {
    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes: Int = Int(interval / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        if hours == 0 { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }
}

struct StrataPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct StrataPrimaryLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(StrataFont.sans(17, .medium))
            .foregroundStyle(StrataPalette.haze)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(minHeight: 48)
            .background(StrataPalette.ink, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
    }
}

struct StrataOutlineLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(StrataFont.sans(17, .medium))
            .foregroundStyle(StrataPalette.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(minHeight: 48)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(StrataPalette.ink, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
    }
}
