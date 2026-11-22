//  StarsKit.swift
//  studyApp
//
//  DEV ONLY — shared palette, geometry, type and small pieces for the Stars design.

import SwiftUI

enum StarsPalette {
    static let midnight = Color(labHex: 0x0B1030)
    static let indigo = Color(labHex: 0x1B2A5E)
    static let dawn = Color(labHex: 0x4A5578)
    static let star = Color(labHex: 0xF2F5FF)
    static let starlight = Color(labHex: 0xFFE9A8)
    static let haze = Color(labHex: 0xA9B4D6)
}

enum StarsLayout {
    static let statusRowHeight: CGFloat = 40
    static let statusOffset: CGFloat = 44
    static let sidePadding: CGFloat = 24
}

enum StarsFont {

    // Fixed size because the caller already scales it with @ScaledMetric, alongside the digit cell width.
    static func timer(_ size: CGFloat) -> Font {
        Font.custom("GillSans-Light", fixedSize: size)
    }

    static func heading(_ size: CGFloat) -> Font {
        Font.custom("GillSans-SemiBold", size: size, relativeTo: .body)
    }

    static func text(_ size: CGFloat) -> Font {
        Font.custom("GillSans", size: size, relativeTo: .body)
    }
}

struct StarsPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct StarsPill: View {

    let title: String
    let textColor: Color
    let fill: Color
    let stroke: Color
    var strokeWidth: CGFloat = 1

    var body: some View {
        Text(title)
            .font(StarsFont.text(17))
            .foregroundStyle(textColor)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .frame(minHeight: 48)
            .background(fill, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(stroke, lineWidth: strokeWidth)
            }
            .contentShape(Capsule())
    }
}

enum StarsFormat {

    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes: Int = Int(max(interval, 0) / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        if hours == 0 { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }
}
