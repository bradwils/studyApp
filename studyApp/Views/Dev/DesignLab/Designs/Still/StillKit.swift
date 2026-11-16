//  StillKit.swift
//  studyApp
//
//  DEV ONLY — shared palette, geometry, formatting and the capsule button for Still.

import SwiftUI

enum StillPalette {

    static let amber = Color(labHex: 0xF2B544)
    static let umber = Color(labHex: 0x2A1E05)

    static func spruce(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(labHex: 0x3CC9A7) : Color(labHex: 0x1F8A70)
    }
}

enum StillLayout {

    static let headerHeight: CGFloat = 60
    static let trackingRow: CGFloat = 110
    static let focusRow: CGFloat = 150
    static let margin: CGFloat = 24

    static func trackingTimerY(_ height: CGFloat) -> CGFloat {
        height * 0.30
    }

    static func focusTimerY(_ height: CGFloat) -> CGFloat {
        height * 0.46
    }
}

enum StillFormat {

    static func minutes(_ interval: TimeInterval) -> String {
        let total: Int = Int(interval / 60)
        let hours: Int = total / 60
        let mins: Int = total % 60
        if hours == 0 { return "\(mins) min" }
        return "\(hours) h \(mins) min"
    }
}

struct StillPressStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct StillCapsuleButton: View {

    let title: String
    let spruce: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.background)
                .padding(.horizontal, 34)
                .padding(.vertical, 14)
                .frame(minHeight: 50)
                .background(Capsule().fill(spruce))
        }
        .buttonStyle(StillPressStyle())
    }
}
