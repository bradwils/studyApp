//  DialRing.swift
//  studyApp
//
//  DEV ONLY — the one ring Dial never moves: hairline dial on the tracking page,
//  bold progress band on the focus page. Takes plain numbers so it redraws cheaply.

import SwiftUI

struct DialRing: View {

    let diameter: CGFloat
    let blend: CGFloat
    let fraction: CGFloat
    let hasSession: Bool

    var body: some View {
        let scale: CGFloat = FocusLabMath.lerp(1, 1.08, blend)
        ZStack {
            ticks
            track
            arc
            marker
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(scale)
        .accessibilityHidden(true)
    }

    private var ticks: some View {
        let radius: CGFloat = diameter / 2
        let opacity: Double = Double(1 - FocusLabMath.window(blend, 0, 0.45))
        let majorColor: Color = DialPalette.ink.opacity(0.55)
        let minorColor: Color = DialPalette.tick
        return Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer: CGFloat = radius - 10
            for i in 0..<60 {
                let isMajor: Bool = i % 5 == 0
                let length: CGFloat = isMajor ? 12 : 6
                let lineWidth: CGFloat = isMajor ? 1.5 : 1
                let color: Color = isMajor ? majorColor : minorColor
                let angle: Double = Double(i) * Double.pi / 30
                let dx: CGFloat = CGFloat(sin(angle))
                let dy: CGFloat = CGFloat(-cos(angle))
                let inner: CGFloat = outer - length
                var path = Path()
                path.move(to: CGPoint(x: center.x + dx * outer, y: center.y + dy * outer))
                path.addLine(to: CGPoint(x: center.x + dx * inner, y: center.y + dy * inner))
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
        .frame(width: diameter, height: diameter)
        .opacity(opacity)
    }

    private var track: some View {
        let from: Color = DialPalette.tick.opacity(0.35)
        let to: Color = DialPalette.white.opacity(0.2)
        let color: Color = from.labBlend(to, blend)
        let width: CGFloat = FocusLabMath.lerp(1, 16, blend)
        return Circle()
            .stroke(color, lineWidth: width)
            .frame(width: diameter, height: diameter)
    }

    private var arc: some View {
        let width: CGFloat = FocusLabMath.lerp(3, 16, blend)
        let color: Color = DialPalette.cobalt.labBlend(DialPalette.white, blend)
        let visible: Double = fraction < 0.002 ? 0 : 1
        return Circle()
            .trim(from: 0, to: fraction)
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(-90))
            .opacity(visible)
    }

    private var marker: some View {
        let radius: CGFloat = diameter / 2
        let size: CGFloat = FocusLabMath.lerp(10, 0, FocusLabMath.window(blend, 0, 0.5))
        let angle: Double = Double(fraction) * 2 * Double.pi
        let dx: CGFloat = CGFloat(sin(angle)) * radius
        let dy: CGFloat = CGFloat(-cos(angle)) * radius
        let visible: Double = hasSession ? 1 : 0
        return Circle()
            .fill(DialPalette.signal)
            .frame(width: max(size, 0), height: max(size, 0))
            .offset(x: dx, y: dy)
            .opacity(visible)
    }
}
