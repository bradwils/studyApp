//  StarsField.swift
//  studyApp
//
//  DEV ONLY — Stars' sky maths as plain values: the field stars, the turn of the sky and
//  the eight-star figure, so the Canvases only draw.

import SwiftUI

nonisolated struct StarsDot {
    let center: CGPoint
    let radius: CGFloat
    let opacity: Double
}

nonisolated struct StarsSegment {
    let from: CGPoint
    let to: CGPoint
}

nonisolated struct StarsField {

    static let count: Int = 90

    // Backdrop size and the point the sky turns around.
    let size: CGSize
    let pole: CGPoint
    // Eased 0...1 progress of the swipe.
    let turn: CGFloat

    // Deterministic hash so the sky is the same on every launch.
    static func unit(_ index: Int, _ salt: Int) -> CGFloat {
        let angle: Double = Double(index) * 12.9898 + Double(salt) * 78.233
        let raw: Double = sin(angle) * 43758.5453
        return CGFloat(raw - raw.rounded(.down))
    }

    static func litCount(hasSession: Bool, studyElapsed: TimeInterval) -> Int {
        guard hasSession else { return 14 }
        let blocks: Int = Int(max(studyElapsed, 0) / 300)
        return min(count, 14 + blocks * 4)
    }

    func turned(_ point: CGPoint) -> CGPoint {
        let dx: Double = Double(point.x - pole.x)
        let dy: Double = Double(point.y - pole.y)
        let angle: Double = Double(turn) * 0.21
        let spread: Double = 1 + Double(turn) * 0.16
        let cosine: Double = cos(angle)
        let sine: Double = sin(angle)
        let rotatedX: Double = (dx * cosine - dy * sine) * spread
        let rotatedY: Double = (dx * sine + dy * cosine) * spread
        return CGPoint(x: pole.x + CGFloat(rotatedX), y: pole.y + CGFloat(rotatedY))
    }

    func dots(lit: Int) -> [StarsDot] {
        var result: [StarsDot] = []
        let shown: Int = min(max(lit, 0), StarsField.count)
        for i in 0..<shown {
            let baseX: CGFloat = StarsField.unit(i, 1) * size.width
            let baseY: CGFloat = StarsField.unit(i, 2) * size.height
            let center: CGPoint = turned(CGPoint(x: baseX, y: baseY))
            let radius: CGFloat = 0.6 + StarsField.unit(i, 3) * 1.1
            let opacity: Double = 0.35 + Double(StarsField.unit(i, 4)) * 0.5
            result.append(StarsDot(center: center, radius: radius, opacity: opacity))
        }
        return result
    }
}

nonisolated struct StarsFigure {

    static let radii: [Double] = [150, 128, 164, 136, 158, 124, 168, 140]
    static let degrees: [Double] = [10, 58, 102, 150, 196, 238, 286, 332]

    let pole: CGPoint

    func anchors() -> [CGPoint] {
        var result: [CGPoint] = []
        for i in 0..<StarsFigure.radii.count {
            let radians: Double = StarsFigure.degrees[i] * Double.pi / 180
            let reach: Double = StarsFigure.radii[i]
            let pointX: CGFloat = pole.x + CGFloat(reach * sin(radians))
            let pointY: CGFloat = pole.y - CGFloat(reach * cos(radians))
            result.append(CGPoint(x: pointX, y: pointY))
        }
        return result
    }

    // The loop 0→1→…→7→0, drawn as far as `progress` of the whole figure.
    func segments(progress: Double) -> [StarsSegment] {
        var result: [StarsSegment] = []
        let points: [CGPoint] = anchors()
        let count: Int = points.count
        guard count > 1 else { return result }
        let total: Double = min(max(progress, 0), 1) * Double(count)
        for i in 0..<count {
            let done: Double = total - Double(i)
            guard done > 0 else { break }
            let start: CGPoint = points[i]
            let end: CGPoint = points[(i + 1) % count]
            let fraction: CGFloat = CGFloat(min(done, 1))
            let tipX: CGFloat = start.x + (end.x - start.x) * fraction
            let tipY: CGFloat = start.y + (end.y - start.y) * fraction
            result.append(StarsSegment(from: start, to: CGPoint(x: tipX, y: tipY)))
        }
        return result
    }
}
