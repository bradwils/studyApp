//  DaylightBackdrop.swift
//  studyApp
//
//  DEV ONLY — the full-bleed layer of the Daylight design: sky, arc, sun, ground and the pinned timer.

import SwiftUI

struct DaylightBackdrop: View {
    let session: FocusLabSession
    let geometry: DaylightGeometry
    let blend: CGFloat
    let timerSize: CGFloat

    var body: some View {
        ZStack {
            scene
            clock
        }
    }

    private var scene: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            DaylightScene(
                geometry: geometry,
                blend: blend,
                progress: progressValue(at: context.date),
                day: dayValue(at: context.date)
            )
        }
    }

    private func progressValue(at date: Date) -> CGFloat {
        CGFloat(session.focusProgress(at: date) ?? 0)
    }

    private func dayValue(at date: Date) -> CGFloat {
        let total: TimeInterval = session.todayTotal(at: date)
        return CGFloat(min(total / (4 * 3600), 1))
    }

    private var digitWidth: CGFloat {
        timerSize * 0.6
    }

    private var timerPoint: CGPoint {
        geometry.toBackdrop(CGPoint(x: geometry.width / 2, y: geometry.timerCenterY))
    }

    private var clock: some View {
        FocusLabClock(session: session, idleText: "0:00", digitWidth: digitWidth)
            .font(Font.custom("AvenirNext-Medium", size: 84, relativeTo: .largeTitle))
            .foregroundStyle(DaylightPalette.plum)
            .position(timerPoint)
    }
}

private struct DaylightScene: View {
    let geometry: DaylightGeometry
    let blend: CGFloat
    let progress: CGFloat
    let day: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var glide: Animation? {
        reduceMotion ? nil : Animation.smooth(duration: 1.0)
    }

    var body: some View {
        ZStack {
            sky
            arcLayer
            sunLayer
            ground
        }
        .frame(width: geometry.fullWidth, height: geometry.fullHeight)
        .animation(glide, value: progress)
        .animation(glide, value: day)
    }

    // MARK: - Sky

    private var sky: some View {
        let focusTop: Color = DaylightPalette.dawn.labBlend(DaylightPalette.noon, progress)
        let focusBottom: Color = DaylightPalette.blush.labBlend(DaylightPalette.noon, progress)
        let top: Color = DaylightPalette.noon.labBlend(focusTop, blend)
        let bottom: Color = DaylightPalette.dawn.labBlend(focusBottom, blend)
        return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Arc

    private func arcPath(upTo fraction: CGFloat) -> Path {
        let points: [CGPoint] = geometry.arcSamples(upTo: fraction)
        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    @ViewBuilder
    private var arcLayer: some View {
        let fade: Double = Double(1 - FocusLabMath.window(blend, 0, 0.5))
        let faint: StrokeStyle = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
        let bold: StrokeStyle = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        ZStack {
            arcPath(upTo: 1)
                .stroke(Color(labHex: 0x2B2440, opacity: 0.14), style: faint)
            if day > 0.001 {
                arcPath(upTo: day)
                    .stroke(DaylightPalette.marigold, style: bold)
            }
        }
        .opacity(fade)
    }

    // MARK: - Sun

    @ViewBuilder
    private var sunLayer: some View {
        let center: CGPoint = geometry.sunCenter(blend: blend, progress: progress, day: day)
        let diameter: CGFloat = geometry.sunDiameter(blend: blend)
        ZStack {
            halo(at: center, diameter: diameter)
            disc(at: center, diameter: diameter)
        }
    }

    private func halo(at center: CGPoint, diameter: CGFloat) -> some View {
        let haloDiameter: CGFloat = diameter * 1.9
        let haloBlur: CGFloat = diameter * 0.28
        let haloOpacity: Double = Double(0.55 * blend)
        return Circle()
            .fill(DaylightPalette.glow)
            .frame(width: haloDiameter, height: haloDiameter)
            .blur(radius: haloBlur)
            .opacity(haloOpacity)
            .position(center)
    }

    private func disc(at center: CGPoint, diameter: CGFloat) -> some View {
        let lower: Color = DaylightPalette.marigold.labBlend(DaylightPalette.apricot, blend)
        let fill = LinearGradient(colors: [DaylightPalette.marigold, lower], startPoint: .top, endPoint: .bottom)
        return Circle()
            .fill(fill)
            .frame(width: diameter, height: diameter)
            .position(center)
    }

    // MARK: - Ground

    private var ground: some View {
        geometry.groundPath()
            .fill(DaylightPalette.ground)
            .offset(y: geometry.groundOffset(blend: blend))
    }
}
