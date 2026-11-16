//  TideWater.swift
//  studyApp
//
//  DEV ONLY — the Tide backdrop: sky, two waves, friend floats, and the timer and status
//  text drawn twice so the digits change colour exactly along the waterline.

import SwiftUI

enum TideWave {

    static func surfaceY(
        x: CGFloat,
        waterlineY: CGFloat,
        amplitude: CGFloat,
        wavelength: CGFloat,
        phase: Double
    ) -> CGFloat {
        let primaryAngle: Double = 2 * Double.pi * Double(x / wavelength) + phase
        let rippleAngle: Double = 2 * Double.pi * Double(x / (wavelength * 0.57)) - phase * 1.3
        let primary: CGFloat = amplitude * CGFloat(sin(primaryAngle))
        let ripple: CGFloat = amplitude * 0.45 * CGFloat(sin(rippleAngle))
        return waterlineY + primary + ripple
    }

    static func tidePath(
        size: CGSize,
        waterlineY: CGFloat,
        amplitude: CGFloat,
        wavelength: CGFloat,
        phase: Double
    ) -> Path {
        var path = Path()
        let startY: CGFloat = surfaceY(x: 0, waterlineY: waterlineY, amplitude: amplitude, wavelength: wavelength, phase: phase)
        path.move(to: CGPoint(x: 0, y: startY))
        var x: CGFloat = 0
        while x < size.width {
            x += 6
            let edgeX: CGFloat = min(x, size.width)
            let edgeY: CGFloat = surfaceY(x: edgeX, waterlineY: waterlineY, amplitude: amplitude, wavelength: wavelength, phase: phase)
            path.addLine(to: CGPoint(x: edgeX, y: edgeY))
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }
}

struct TideWaterGeometry {

    let size: CGSize
    let lineY: CGFloat
    let amplitude: CGFloat
    let phase: Double

    private var frontWavelength: CGFloat { max(size.width * 0.9, 1) }
    private var backWavelength: CGFloat { max(size.width * 0.65, 1) }

    func surfaceY(x: CGFloat) -> CGFloat {
        TideWave.surfaceY(x: x, waterlineY: lineY, amplitude: amplitude, wavelength: frontWavelength, phase: phase)
    }

    var frontPath: Path {
        TideWave.tidePath(size: size, waterlineY: lineY, amplitude: amplitude, wavelength: frontWavelength, phase: phase)
    }

    var backPath: Path {
        TideWave.tidePath(size: size, waterlineY: lineY - 7, amplitude: amplitude, wavelength: backWavelength, phase: phase + 2.1)
    }
}

// MARK: - Backdrop

struct TideBackdrop: View {

    let session: FocusLabSession
    let metrics: FocusLabStageMetrics
    let blend: CGFloat
    let reduceMotion: Bool
    let timerSize: CGFloat
    let timerSlotHeight: CGFloat
    let captionSize: CGFloat

    var body: some View {
        let interval: Double = reduceMotion ? 1 : 1.0 / 30.0
        TimelineView(.animation(minimumInterval: interval)) { context in
            TideScene(
                session: session,
                water: water(at: context.date),
                blend: blend,
                date: context.date,
                timerCenter: timerCenter,
                statusCenter: statusCenter,
                timerSize: timerSize,
                captionSize: captionSize
            )
        }
    }

    private var timerCenter: CGPoint {
        let pageY: CGFloat = TideLayout.headerHeight + TideLayout.timerGap + timerSlotHeight / 2
        return CGPoint(x: metrics.fullSize.width / 2, y: metrics.backdropY(pageY))
    }

    private var statusCenter: CGPoint {
        let pageY: CGFloat = TideLayout.headerHeight + TideLayout.timerGap + timerSlotHeight + TideLayout.statusInset
        return CGPoint(x: metrics.fullSize.width / 2, y: metrics.backdropY(pageY))
    }

    private func water(at date: Date) -> TideWaterGeometry {
        let dayGoal: Double = 4 * 3600
        let dayFraction: Double = min(session.todayTotal(at: date) / dayGoal, 1)
        let focusFraction: Double = session.focusProgress(at: date) ?? 0
        let trackingLevel: CGFloat = 0.34 + 0.52 * CGFloat(dayFraction)
        let focusLevel: CGFloat = 0.34 + 0.52 * CGFloat(focusFraction)
        let level: CGFloat = FocusLabMath.lerp(trackingLevel, focusLevel, blend)

        let size: CGSize = metrics.fullSize
        let lineY: CGFloat = size.height * (1 - level)
        let amplitude: CGFloat = reduceMotion ? 0 : 5

        // Period chosen so both sine terms complete whole turns, hiding the wrap-around.
        let period: Double = 100 * Double.pi / 3
        let time: Double = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
        return TideWaterGeometry(size: size, lineY: lineY, amplitude: amplitude, phase: time * 0.6)
    }
}

// MARK: - Scene

private struct TideScene: View {

    let session: FocusLabSession
    let water: TideWaterGeometry
    let blend: CGFloat
    let date: Date
    let timerCenter: CGPoint
    let statusCenter: CGPoint
    let timerSize: CGFloat
    let captionSize: CGFloat

    var body: some View {
        ZStack {
            TidePalette.foam.labBlend(TidePalette.mist, blend)
            backWave
            frontWave
            floats
            timer
            statusLines
        }
        .frame(width: water.size.width, height: water.size.height)
    }

    private var backWave: some View {
        water.backPath.fill(TidePalette.shallows.opacity(0.55))
    }

    private var frontWave: some View {
        let unitY: CGFloat = water.lineY / max(water.size.height, 1)
        let bottomColor: Color = TidePalette.deep.labBlend(TidePalette.abyss, blend)
        let gradient = LinearGradient(
            colors: [TidePalette.lagoon, bottomColor],
            startPoint: UnitPoint(x: 0.5, y: unitY),
            endPoint: UnitPoint(x: 0.5, y: 1)
        )
        return water.frontPath.fill(gradient)
    }

    // MARK: Floats

    private var floats: some View {
        let count: Int = min(3, session.friends.count)
        return ZStack {
            ForEach(0..<count, id: \.self) { index in
                floatView(index: index)
            }
        }
    }

    private func floatView(index: Int) -> some View {
        let fractions: [CGFloat] = [0.18, 0.5, 0.82]
        let floatX: CGFloat = water.size.width * fractions[index]
        let floatY: CGFloat = water.surfaceY(x: floatX) - 9
        let initial: String = String(session.friends[index].name.prefix(1))
        return Circle()
            .fill(TidePalette.buoy)
            .frame(width: 26, height: 26)
            .overlay {
                Text(initial)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(TidePalette.deep)
            }
            .position(x: floatX, y: floatY)
            .opacity(Double(1 - blend))
    }

    // MARK: Timer and status

    private var timer: some View {
        TideSubmerged(size: water.size, center: timerCenter, waterPath: water.frontPath) {
            FocusLabClock(session: session, idleText: "0:00")
                .font(.system(size: timerSize, weight: .light, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var statusLines: some View {
        ZStack {
            statusLayer(text: trackingStatus, visibility: Double(1 - blend))
            statusLayer(text: focusStatus, visibility: Double(blend))
        }
    }

    private func statusLayer(text: String, visibility: Double) -> some View {
        TideSubmerged(size: water.size, center: statusCenter, waterPath: water.frontPath, aboveOpacity: 0.7) {
            Text(text)
                .font(.system(size: captionSize, weight: .regular, design: .rounded))
        }
        .opacity(visibility)
    }

    private var trackingStatus: String {
        switch session.phase {
        case .idle:
            guard let saved = session.lastCompletedLength else { return "Start when you're ready" }
            return "Saved \(TideFormat.hoursMinutes(saved))"
        case .running:
            return "Studying"
        case .paused:
            return "On a break"
        }
    }

    private var focusStatus: String {
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "Pick a length, then start" }
        if session.isFocusComplete(at: date) { return "Block complete" }
        let minutes: Int = Int(session.focusDuration / 60)
        return "left of \(minutes) minutes"
    }
}

// MARK: - Two-layer text

private struct TideSubmerged<Content: View>: View {

    let size: CGSize
    let center: CGPoint
    let waterPath: Path
    let aboveOpacity: Double
    let content: Content

    init(
        size: CGSize,
        center: CGPoint,
        waterPath: Path,
        aboveOpacity: Double = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.center = center
        self.waterPath = waterPath
        self.aboveOpacity = aboveOpacity
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .foregroundStyle(TidePalette.deep)
                .opacity(aboveOpacity)
                .position(x: center.x, y: center.y)

            content
                .foregroundStyle(TidePalette.foam)
                .position(x: center.x, y: center.y)
                .mask { waterPath.fill(Color.black) }
                .accessibilityHidden(true)
        }
        .frame(width: size.width, height: size.height)
    }
}
