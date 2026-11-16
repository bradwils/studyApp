//  TapeKit.swift
//  studyApp
//
//  DEV ONLY — shared palette, geometry and small helpers for the Tape design.

import SwiftUI

enum TapePalette {
    static let fog = Color(labHex: 0xDFE7EC)
    static let slate = Color(labHex: 0x2A3642)
    static let tape = Color(labHex: 0xFBFCFD)
    static let ink = Color(labHex: 0x1C2733)
    static let mint = Color(labHex: 0x58C4A0)
    static let poppy = Color(labHex: 0xF2545B)
    static let haze = Color(labHex: 0x7D8B97)
    static let pale = Color(labHex: 0xC9D3DB)
}

enum TapeLayout {
    static let bandHeight: CGFloat = 216
    static let timerCenterY: CGFloat = 62
    static let statusCenterY: CGFloat = 116
    static let tapeTopY: CGFloat = 140
    static let tapeHeight: CGFloat = 64
    static let ribbonPad: CGFloat = 12

    static func bandTop(height: CGFloat) -> CGFloat {
        max(0, (height - bandHeight) * 0.42)
    }
}

enum TapeFont {
    static func text(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        Font.system(size: size, weight: weight)
    }
}

struct TapePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

enum TapeFormat {

    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes: Int = Int(max(interval, 0) / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        if hours == 0 { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }

    static func friendsLine(_ friends: [FocusLabSession.LabFriend]) -> String {
        let names: [String] = friends.map { $0.name }
        guard !names.isEmpty else { return "" }
        let verb: String = names.count == 1 ? "is" : "are"
        let list: String
        if names.count == 1 {
            list = names[0]
        } else {
            let head: String = names.dropLast().joined(separator: ", ")
            list = "\(head) and \(names[names.count - 1])"
        }
        return "\(list) \(verb) studying"
    }
}
