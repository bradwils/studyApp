//  DaylightGeometry.swift
//  studyApp
//
//  DEV ONLY — every position the Daylight design shares between its backdrop and its pages.
//  Page coordinates unless a function says it returns backdrop coordinates.

import SwiftUI

struct DaylightGeometry {

    static let arcSagitta: CGFloat = 84
    static let trackingSunDiameter: CGFloat = 22
    static let focusSunDiameter: CGFloat = 168

    let insetLeading: CGFloat
    let insetTop: CGFloat
    let fullWidth: CGFloat
    let fullHeight: CGFloat
    let arcCenterX: CGFloat
    let arcCenterY: CGFloat
    let arcRadius: CGFloat
    let arcTheta: Double
    let timerCenterY: CGFloat
    let timerBottom: CGFloat
    let horizonY: CGFloat

    init(context: FocusPagerContext) {
        let metrics: FocusPagerStageMetrics = context.metrics
        let safe: CGSize = metrics.safeSize
        let full: CGSize = metrics.fullSize
        let apex: CGFloat = context.timerRect.minY - 20
        let sagitta: CGFloat = DaylightGeometry.arcSagitta
        let half: CGFloat = max((context.contentRect.width - 64) / 2, 1)
        let radius: CGFloat = (half * half + sagitta * sagitta) / (2 * sagitta)
        let ratio: Double = min(Double(half / radius), 1)

        self.insetLeading = metrics.insets.leading
        self.insetTop = metrics.insets.top
        self.fullWidth = full.width
        self.fullHeight = full.height
        self.arcCenterX = context.contentRect.midX
        self.arcCenterY = apex + radius
        self.arcRadius = radius
        self.arcTheta = asin(ratio)
        self.timerCenterY = context.timerRect.midY
        self.timerBottom = context.timerRect.maxY
        self.horizonY = safe.height * 0.60
    }

    var controlsOffset: CGFloat {
        max(horizonY + 40 - timerBottom, 0)
    }

    func toBackdrop(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x + insetLeading, y: point.y + insetTop)
    }

    func arcPoint(_ fraction: CGFloat) -> CGPoint {
        let frac: Double = Double(FocusLabMath.clamp(fraction))
        let angle: Double = -arcTheta + 2 * arcTheta * frac
        let dx: CGFloat = arcRadius * CGFloat(sin(angle))
        let dy: CGFloat = arcRadius * CGFloat(cos(angle))
        return CGPoint(x: arcCenterX + dx, y: arcCenterY - dy)
    }

    func arcSamples(upTo fraction: CGFloat) -> [CGPoint] {
        let count: Int = 48
        var points: [CGPoint] = []
        for i in 0...count {
            let step: CGFloat = fraction * CGFloat(i) / CGFloat(count)
            points.append(toBackdrop(arcPoint(step)))
        }
        return points
    }

    func sunCenter(blend: CGFloat, progress: CGFloat, day: CGFloat) -> CGPoint {
        let tracking: CGPoint = arcPoint(day)
        let focusY: CGFloat = FocusLabMath.lerp(horizonY, timerCenterY, progress)
        let travel: CGFloat = FocusLabMath.smoothstep(blend)
        let sunX: CGFloat = FocusLabMath.lerp(tracking.x, arcCenterX, travel)
        let sunY: CGFloat = FocusLabMath.lerp(tracking.y, focusY, travel)
        return toBackdrop(CGPoint(x: sunX, y: sunY))
    }

    func sunDiameter(blend: CGFloat) -> CGFloat {
        let travel: CGFloat = FocusLabMath.smoothstep(blend)
        return FocusLabMath.lerp(DaylightGeometry.trackingSunDiameter, DaylightGeometry.focusSunDiameter, travel)
    }

    func groundOffset(blend: CGFloat) -> CGFloat {
        let backdropHorizon: CGFloat = horizonY + insetTop
        let distance: CGFloat = fullHeight - backdropHorizon + 20
        return (1 - blend) * distance
    }

    func groundPath() -> Path {
        let edgeY: CGFloat = horizonY + insetTop + 14
        let peakY: CGFloat = horizonY + insetTop - 14
        let bottomY: CGFloat = fullHeight + 400
        let wide: CGFloat = fullWidth
        return Path { path in
            path.move(to: CGPoint(x: 0, y: edgeY))
            path.addQuadCurve(to: CGPoint(x: wide, y: edgeY), control: CGPoint(x: wide / 2, y: peakY))
            path.addLine(to: CGPoint(x: wide, y: bottomY))
            path.addLine(to: CGPoint(x: 0, y: bottomY))
            path.closeSubpath()
        }
    }
}
