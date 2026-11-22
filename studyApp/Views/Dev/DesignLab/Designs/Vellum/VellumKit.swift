//  VellumKit.swift
//  studyApp
//
//  DEV ONLY — palette, type, geometry and the per-sheet numbers for the Vellum design.

import SwiftUI

enum VellumPalette {
    static let milk = Color(labHex: 0xF7F6F3)
    static let ink = Color(labHex: 0x1D1B2E)
    static let dust = Color(labHex: 0x7C7990)
    static let white = Color(labHex: 0xFFFFFF)
    static let coral = Color(labHex: 0xFF6F59)
    static let amber = Color(labHex: 0xFFB627)
    static let teal = Color(labHex: 0x2EC4B6)
    static let blue = Color(labHex: 0x3A86FF)
    static let violet = Color(labHex: 0x9B5DE5)

    static let sheets: [Color] = [coral, amber, teal, blue, violet]
}

enum VellumFont {
    static func text(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }
}

struct VellumPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct VellumSheet: Identifiable {
    let id: Int
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat
    let center: CGPoint
    let degrees: Double
    let color: Color
}

struct VellumLayout {

    static let sidePadding: CGFloat = 24
    static let sheetOpacity: Double = 0.46
    static let sheetCount: Int = 5

    // The fan and the tile belong to the controls, so they follow the centred column rather than the screen.
    let columnWidth: CGFloat
    let columnCenterX: CGFloat
    let height: CGFloat
    let insetLeading: CGFloat
    let insetTop: CGFloat
    let fullWidth: CGFloat
    let fullHeight: CGFloat
    let tile: CGFloat
    let timerCenterY: CGFloat
    let timerBackdropCenter: CGPoint

    init(context: FocusPagerContext) {
        let metrics: FocusPagerStageMetrics = context.metrics
        let safe: CGSize = metrics.safeSize
        let full: CGSize = metrics.fullSize

        self.columnWidth = context.contentRect.width
        self.columnCenterX = context.contentRect.midX
        self.height = safe.height
        self.insetLeading = metrics.insets.leading
        self.insetTop = metrics.insets.top
        self.fullWidth = full.width
        self.fullHeight = full.height
        self.tile = min(context.timerRect.height, context.contentRect.width * 0.62, 250)
        self.timerCenterY = context.timerRect.midY
        self.timerBackdropCenter = CGPoint(x: context.timerBackdropRect.midX, y: context.timerBackdropRect.midY)
    }

    func sheets(blend: CGFloat, bloom: CGFloat) -> [VellumSheet] {
        (0..<VellumLayout.sheetCount).map { index in
            sheet(index: index, blend: blend, bloom: bloom)
        }
    }

    func sheet(index: Int, blend: CGFloat, bloom: CGFloat) -> VellumSheet {
        let slot: CGFloat = CGFloat(index)
        let spread: CGFloat = slot - 2

        let fanWidth: CGFloat = columnWidth * 0.74
        let fanHeight: CGFloat = height * 0.40
        let fanShift: CGFloat = spread * columnWidth * 0.15
        let fanX: CGFloat = columnCenterX + fanShift
        let fanY: CGFloat = height * 0.70 + spread * 16
        let fanDegrees: CGFloat = spread * 7

        let stackRadius: CGFloat = tile * 0.28
        let stackStart: CGFloat = spread * 1.5
        let stackEnd: CGFloat = slot * 18
        let stackDegrees: CGFloat = FocusLabMath.lerp(stackStart, stackEnd, bloom)

        let windowStart: CGFloat = slot * 0.09
        let windowEnd: CGFloat = 0.64 + windowStart
        let travel: CGFloat = FocusLabMath.smoothstep(FocusLabMath.window(blend, windowStart, windowEnd))

        let sheetWidth: CGFloat = FocusLabMath.lerp(fanWidth, tile, travel)
        let sheetHeight: CGFloat = FocusLabMath.lerp(fanHeight, tile, travel)
        let sheetRadius: CGFloat = FocusLabMath.lerp(34, stackRadius, travel)
        let pageX: CGFloat = FocusLabMath.lerp(fanX, columnCenterX, travel)
        let pageY: CGFloat = FocusLabMath.lerp(fanY, timerCenterY, travel)
        let sheetDegrees: CGFloat = FocusLabMath.lerp(fanDegrees, stackDegrees, travel)

        return VellumSheet(
            id: index,
            width: sheetWidth,
            height: sheetHeight,
            radius: sheetRadius,
            center: CGPoint(x: pageX + insetLeading, y: pageY + insetTop),
            degrees: Double(sheetDegrees),
            color: VellumPalette.sheets[index]
        )
    }
}
