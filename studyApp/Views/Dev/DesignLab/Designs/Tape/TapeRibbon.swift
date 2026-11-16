//  TapeRibbon.swift
//  studyApp
//
//  DEV ONLY — the white tape itself: a per-frame Canvas that draws ticks, ink and the goal
//  flag from the plain values TapeScale computes.

import SwiftUI

struct TapeRibbon: View {

    let session: FocusLabSession
    let needleX: CGFloat
    let width: CGFloat
    let safeWidth: CGFloat
    let blend: CGFloat
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                layers(at: context.date)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
                layers(at: context.date)
            }
        }
    }

    private func layers(at date: Date) -> some View {
        let scale: TapeScale = makeScale(at: date)
        let flagX: CGFloat? = session.hasFocusBlock ? scale.flagX(goal: session.focusGoal) : nil
        let flagOpacity: Double = Double(FocusLabMath.window(blend, 0.3, 0.8))
        let height: CGFloat = TapeLayout.tapeHeight + 2 * TapeLayout.ribbonPad
        return ZStack {
            TapeTapeCanvas(
                ticks: scale.ticks(),
                inks: scale.inkRects(segments: session.segments)
            )
            TapeFlagCanvas(flagX: flagX)
                .opacity(flagOpacity)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    private func makeScale(at date: Date) -> TapeScale {
        let tracking: CGFloat = TapeScale.trackingPointsPerSecond
        let focus: CGFloat = TapeScale.focusPointsPerSecond(safeWidth: safeWidth, focusLength: focusLength)
        let perSecond: CGFloat = FocusLabMath.lerp(tracking, focus, blend)
        return TapeScale(
            needleX: needleX,
            width: width,
            pointsPerSecond: perSecond,
            now: date,
            elapsed: elapsedSeconds(at: date)
        )
    }

    private var focusLength: TimeInterval {
        guard let start = session.focusStart, let goal = session.focusGoal else {
            return session.focusDuration
        }
        return goal.timeIntervalSince(start)
    }

    private func elapsedSeconds(at date: Date) -> TimeInterval {
        guard let startedAt = session.startedAt else { return 0 }
        return max(0, date.timeIntervalSince(startedAt))
    }
}

// MARK: - Canvases

private struct TapeTapeCanvas: View {

    let ticks: [TapeTick]
    let inks: [TapeInkRect]

    var body: some View {
        let pad: CGFloat = TapeLayout.ribbonPad
        let tapeHeight: CGFloat = TapeLayout.tapeHeight
        let tapeColor: Color = TapePalette.tape
        let inkColor: Color = TapePalette.ink
        let minorColor: Color = TapePalette.ink.opacity(0.35)
        let mintColor: Color = TapePalette.mint.opacity(0.85)
        let labelFont: Font = Font.system(size: 11, weight: .medium).monospacedDigit()
        let ticks: [TapeTick] = self.ticks
        let inks: [TapeInkRect] = self.inks
        return Canvas { context, size in
            let tapeRect = CGRect(x: 0, y: pad, width: size.width, height: tapeHeight)
            context.fill(Path(tapeRect), with: .color(tapeColor))

            for ink in inks {
                let rect = CGRect(x: ink.minX, y: pad + tapeHeight - 22, width: ink.maxX - ink.minX, height: 22)
                context.fill(Path(rect), with: .color(mintColor))
            }

            for tick in ticks {
                let length: CGFloat = tick.isLabelled ? 18 : 10
                let lineWidth: CGFloat = tick.isLabelled ? 1.5 : 1
                let color: Color = tick.isLabelled ? inkColor : minorColor
                var path = Path()
                path.move(to: CGPoint(x: tick.x, y: pad))
                path.addLine(to: CGPoint(x: tick.x, y: pad + length))
                context.stroke(path, with: .color(color), lineWidth: lineWidth)

                if tick.isLabelled {
                    let label = Text(verbatim: tick.label).font(labelFont).foregroundColor(inkColor)
                    context.draw(label, at: CGPoint(x: tick.x, y: pad + 26))
                }
            }
        }
    }
}

private struct TapeFlagCanvas: View {

    let flagX: CGFloat?

    var body: some View {
        let pad: CGFloat = TapeLayout.ribbonPad
        let tapeHeight: CGFloat = TapeLayout.tapeHeight
        let poppy: Color = TapePalette.poppy
        let flagX: CGFloat? = self.flagX
        return Canvas { context, _ in
            guard let flagX else { return }
            let pole = CGRect(x: flagX - 1, y: pad - 8, width: 2, height: tapeHeight + 8)
            context.fill(Path(pole), with: .color(poppy))

            var pennant = Path()
            pennant.move(to: CGPoint(x: flagX + 1, y: pad - 8))
            pennant.addLine(to: CGPoint(x: flagX + 11, y: pad - 4))
            pennant.addLine(to: CGPoint(x: flagX + 1, y: pad))
            pennant.closeSubpath()
            context.fill(pennant, with: .color(poppy))
        }
    }
}

// MARK: - Needle

struct TapeNeedle: View {

    var body: some View {
        let length: CGFloat = TapeLayout.tapeHeight + 16
        return ZStack(alignment: .top) {
            Rectangle()
                .fill(TapePalette.ink)
                .frame(width: 2, height: length)
            Circle()
                .fill(TapePalette.ink)
                .frame(width: 8, height: 8)
                .offset(y: -4)
        }
        .frame(width: 8, height: length)
        .accessibilityHidden(true)
    }
}
