//  PosterKit.swift
//  studyApp
//
//  DEV ONLY — Poster's palette, type, shared geometry and flat buttons.

import SwiftUI

enum PosterPalette {
    static let pistachio = Color(labHex: 0xCFE3B4)
    static let forest = Color(labHex: 0x12372A)
    static let tangerine = Color(labHex: 0xFF7A1A)
    static let leaf = Color(labHex: 0x5E7D5A)
}

enum PosterFont {
    static func heavy(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .heavy).width(.compressed)
    }

    static func label(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .medium)
    }

    static func button(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .semibold)
    }
}

// One instance feeds the numerals layer and both pages so all three agree.
struct PosterLayout {
    static let margin: CGFloat = 24
    static let headerHeight: CGFloat = 52
    static let smallScale: CGFloat = 0.46
    static let trackingTop: CGFloat = 60

    let width: CGFloat
    let height: CGFloat

    init(size: CGSize) {
        width = size.width
        height = size.height
    }

    var bigSize: CGFloat { max(40, (width - 48) / 1.95) }
    var focusTop: CGFloat { height * 0.30 }
    var slotHeight: CGFloat { bigSize * PosterLayout.smallScale }
}

struct PosterPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct PosterPrimaryButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PosterFont.button(17))
                .foregroundStyle(PosterPalette.pistachio)
                .padding(.horizontal, 26)
                .padding(.vertical, 15)
                .frame(minHeight: 50)
                .background(PosterPalette.forest)
        }
        .buttonStyle(PosterPressStyle())
    }
}

struct PosterLinkButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PosterFont.button(17))
                .underline()
                .foregroundStyle(PosterPalette.forest)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PosterPressStyle())
    }
}
