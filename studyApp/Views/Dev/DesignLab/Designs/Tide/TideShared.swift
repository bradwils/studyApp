//  TideShared.swift
//  studyApp
//
//  DEV ONLY — palette, layout constants and small helpers shared by the Tide design.

import SwiftUI

enum TidePalette {
    static let foam = Color(labHex: 0xF3F7F4)
    static let mist = Color(labHex: 0xDDEDEA)
    static let shallows = Color(labHex: 0x9FD8CB)
    static let lagoon = Color(labHex: 0x2E9CA6)
    static let deep = Color(labHex: 0x0F4C5C)
    static let abyss = Color(labHex: 0x082F3A)
    static let buoy = Color(labHex: 0xFFB03A)
}

enum TideLayout {
    static let headerHeight: CGFloat = 72
    static let timerGap: CGFloat = 36
    static let statusRowHeight: CGFloat = 28
    static let statusInset: CGFloat = 14
}

enum TideFormat {
    static func hoursMinutes(_ interval: TimeInterval) -> String {
        let totalMinutes: Int = Int(interval / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        guard hours > 0 else { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }
}

struct TideButtonLabel: View {

    let title: String
    let color: Color
    let size: CGFloat

    var body: some View {
        Text(title)
            .font(.system(size: size, weight: .medium, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
    }
}
