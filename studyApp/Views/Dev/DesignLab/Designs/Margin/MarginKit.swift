//  MarginKit.swift
//  studyApp
//
//  DEV ONLY — palette, geometry and small shared pieces for the Margin design.

import SwiftUI

enum MarginPalette {
    static let paper = Color(labHex: 0xE9ECE6)
    static let ink = Color(labHex: 0x1E2A2F)
    static let graphite = Color(labHex: 0x6B767A)
    static let slate = Color(labHex: 0x9AA6A8)
    static let rule = Color(labHex: 0xC3CAC4)
    static let ruleDark = Color(labHex: 0x3A474C)
    static let highlighter = Color(labHex: 0xDDE86A)
}

enum MarginLayout {
    static let marginX: CGFloat = 28
    static let contentX: CGFloat = 46
    static let topInset: CGFloat = 20
    static let headerHeight: CGFloat = 64
    static let timerTop: CGFloat = 108
    static let trailing: CGFloat = 24
    static let labelWidth: CGFloat = 92
}

enum MarginFont {
    static func serif(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        Font.system(size: size, weight: weight, design: .serif)
    }

    static func sans(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        Font.system(size: size, weight: weight, design: .default)
    }
}

struct MarginPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// A full-height bar pinned to one side of a full-size frame; used for the ink panel and both timer masks.
struct MarginBar: View {
    let color: Color
    let width: CGFloat
    let alignment: Alignment
    let full: CGSize

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: max(0, width), height: full.height)
            .frame(width: full.width, height: full.height, alignment: alignment)
    }
}

struct MarginRule: View {
    let color: Color
    let x: CGFloat
    let full: CGSize

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 1)
            .padding(.leading, x)
            .frame(width: full.width, height: full.height, alignment: .leading)
    }
}
