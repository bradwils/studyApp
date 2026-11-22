//  TapeScale.swift
//  studyApp
//
//  DEV ONLY — all of Tape's measuring-tape maths as plain values, so the Canvas only draws.

import SwiftUI

struct TapeTick {
    let x: CGFloat
    let isLabelled: Bool
    let label: String
}

struct TapeInkRect {
    let minX: CGFloat
    let maxX: CGFloat
}

struct TapeScale {

    static let trackingPointsPerSecond: CGFloat = 24.0 / 60.0
    static let maxTicks: Int = 400

    // Backdrop x of "now" and the full backdrop width.
    let needleX: CGFloat
    let width: CGFloat
    let pointsPerSecond: CGFloat
    let now: Date
    // Seconds of tape behind the needle: time since the session began, 0 while idle.
    let elapsed: TimeInterval

    // Fits to the page column, not the screen, so on an iPad the flag lands over the controls instead of near the screen edge.
    static func focusPointsPerSecond(columnWidth: CGFloat, focusLength: TimeInterval) -> CGFloat {
        guard focusLength > 0 else { return trackingPointsPerSecond }
        let span: CGFloat = max(columnWidth / 2 - 28, 40)
        return span / CGFloat(focusLength)
    }

    func x(of date: Date) -> CGFloat {
        let seconds: Double = date.timeIntervalSince(now)
        return needleX + CGFloat(seconds) * pointsPerSecond
    }

    func flagX(goal: Date?) -> CGFloat? {
        guard let goal else { return nil }
        return x(of: goal)
    }

    func ticks() -> [TapeTick] {
        var result: [TapeTick] = []
        guard pointsPerSecond > 0, pointsPerSecond.isFinite else { return result }

        let minuteWidth: CGFloat = 60 * pointsPerSecond
        let step: Int = minuteWidth >= 4 ? 1 : 5
        let labelStep: Int = 5 * minuteWidth >= 30 ? 5 : 15

        let leftSpan: CGFloat = (-20 - needleX) / pointsPerSecond
        let rightSpan: CGFloat = (width + 20 - needleX) / pointsPerSecond
        let lowSeconds: Double = Double(leftSpan) + elapsed
        let highSeconds: Double = Double(rightSpan) + elapsed
        let lowMinutes: Double = (lowSeconds / 60).rounded(.up)
        let highMinutes: Double = (highSeconds / 60).rounded(.down)

        var minute: Int = Int(min(max(lowMinutes, 0), 100_000))
        let lastMinute: Int = Int(min(max(highMinutes, 0), 100_000))
        let offset: Int = minute % step
        if offset != 0 { minute += step - offset }

        while minute <= lastMinute && result.count < TapeScale.maxTicks {
            let seconds: Double = Double(minute) * 60 - elapsed
            let tickX: CGFloat = needleX + CGFloat(seconds) * pointsPerSecond
            let isLabelled: Bool = minute > 0 && minute % labelStep == 0
            let label: String = isLabelled ? String(minute) : ""
            result.append(TapeTick(x: tickX, isLabelled: isLabelled, label: label))
            minute += step
        }
        return result
    }

    func inkRects(segments: [FocusLabSession.Segment]) -> [TapeInkRect] {
        var result: [TapeInkRect] = []
        for segment in segments {
            guard segment.kind == .study else { continue }
            let startX: CGFloat = x(of: segment.start)
            let endX: CGFloat = min(x(of: segment.end ?? now), needleX)
            let low: CGFloat = max(startX, 0)
            let high: CGFloat = min(endX, width)
            if high > low {
                result.append(TapeInkRect(minX: low, maxX: high))
            }
        }
        return result
    }
}
