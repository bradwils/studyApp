//  StarsBackdrop.swift
//  studyApp
//
//  DEV ONLY — Stars' fixed layers: sky, dawn, stars, constellation and status.
//  Nothing here slides with the pages; it all reads blend.

import SwiftUI

struct StarsBackdrop: View {

    let session: FocusLabSession
    let context: FocusPagerContext

    var body: some View {
        let blend: CGFloat = context.blend
        let full: CGSize = context.metrics.fullSize
        let center = CGPoint(x: context.timerBackdropRect.midX, y: context.timerBackdropRect.midY)
        return ZStack(alignment: .topLeading) {
            sky
            dawn
            StarsSky(
                session: session,
                size: full,
                pole: center,
                blend: blend
            )
            StarsStatus(session: session, blend: blend)
                .position(x: center.x, y: center.y + StarsLayout.statusOffset)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private var sky: some View {
        LinearGradient(
            colors: [StarsPalette.midnight, StarsPalette.indigo],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var dawn: some View {
        Rectangle()
            .fill(StarsPalette.dawn)
            .opacity(session.isPaused ? 1 : 0)
            .animation(.smooth(duration: 0.6), value: session.isPaused)
    }
}

// MARK: - Sky

private struct StarsSky: View {

    let session: FocusLabSession
    let size: CGSize
    let pole: CGPoint
    let blend: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            layers(at: context.date)
        }
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    private func layers(at date: Date) -> some View {
        let elapsed: TimeInterval = session.studyElapsed(at: date)
        let lit: Int = StarsField.litCount(hasSession: session.hasSession, studyElapsed: elapsed)
        let eased: CGFloat = FocusLabMath.smoothstep(blend)
        let field: StarsField = StarsField(size: size, pole: pole, turn: eased)
        let figure: StarsFigure = StarsFigure(pole: pole)
        let progress: Double = session.focusProgress(at: date) ?? 0
        let fade: Double = session.isPaused ? 0.3 : 1
        return ZStack {
            StarsFieldCanvas(dots: field.dots(lit: lit))
                .opacity(fade)
                .animation(.smooth(duration: 0.6), value: session.isPaused)
            StarsFigureCanvas(
                anchors: figure.anchors(),
                lines: figure.segments(progress: progress),
                blend: blend
            )
        }
    }
}

private struct StarsFieldCanvas: View {

    let dots: [StarsDot]

    var body: some View {
        let color: Color = StarsPalette.star
        let dots: [StarsDot] = self.dots
        return Canvas { context, _ in
            for dot in dots {
                let rect = CGRect(
                    x: dot.center.x - dot.radius,
                    y: dot.center.y - dot.radius,
                    width: 2 * dot.radius,
                    height: 2 * dot.radius
                )
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(dot.opacity)))
            }
        }
    }
}

private struct StarsFigureCanvas: View {

    let anchors: [CGPoint]
    let lines: [StarsSegment]
    let blend: CGFloat

    var body: some View {
        let lineColor: Color = StarsPalette.starlight.opacity(0.8 * Double(blend))
        let anchorColor: Color = StarsPalette.starlight.opacity(0.25 + 0.75 * Double(blend))
        let anchorRadius: CGFloat = 2.6
        let anchors: [CGPoint] = self.anchors
        let lines: [StarsSegment] = self.lines
        return Canvas { context, _ in
            for line in lines {
                var path = Path()
                path.move(to: line.from)
                path.addLine(to: line.to)
                context.stroke(
                    path,
                    with: .color(lineColor),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                )
            }
            for point in anchors {
                let rect = CGRect(
                    x: point.x - anchorRadius,
                    y: point.y - anchorRadius,
                    width: 2 * anchorRadius,
                    height: 2 * anchorRadius
                )
                context.fill(Path(ellipseIn: rect), with: .color(anchorColor))
            }
        }
    }
}

// MARK: - Status line

private struct StarsStatus: View {

    let session: FocusLabSession
    let blend: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            lines(at: context.date)
        }
        .accessibilityHidden(true)
    }

    private func lines(at date: Date) -> some View {
        let elapsed: TimeInterval = session.studyElapsed(at: date)
        let lit: Int = StarsField.litCount(hasSession: session.hasSession, studyElapsed: elapsed)
        let complete: Bool = session.isFocusComplete(at: date)
        return ZStack {
            Text(trackingText(lit: lit))
                .opacity(Double(1 - blend))
            Text(focusText(complete: complete))
                .opacity(Double(blend))
        }
        .font(StarsFont.text(14))
        .foregroundStyle(StarsPalette.haze)
        .lineLimit(1)
    }

    private func trackingText(lit: Int) -> String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "A clear night" }
            let minutes: Int = max(1, Int((length / 60).rounded()))
            return "Saved \(minutes) min"
        case .running:
            return "\(lit) stars lit"
        case .paused:
            return "Dawn break"
        }
    }

    private var blockMinutes: Int {
        guard let start = session.focusStart, let goal = session.focusGoal else { return 0 }
        return Int((goal.timeIntervalSince(start) / 60).rounded())
    }

    private func focusText(complete: Bool) -> String {
        if session.isPaused { return "Dawn break" }
        guard session.hasFocusBlock else { return "No figure started" }
        if complete { return "Figure complete" }
        return "left of \(blockMinutes) minutes"
    }
}
