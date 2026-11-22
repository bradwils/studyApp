//  StrataBands.swift
//  studyApp
//
//  DEV ONLY — the pure maths behind Strata's stack. Not a ViewBuilder, so plain loops are fine.

import SwiftUI

struct StrataBand: Identifiable {
    let id: Int
    let top: CGFloat
    let bottom: CGFloat
    let color: Color
    let labelColor: Color
    let isStudy: Bool
    let minutes: Int
}

struct StrataBandLayout {

    static let seamMinimumHeight: CGFloat = 3
    static let stackShare: Double = 0.58
    static let focusSliver: CGFloat = 6

    // Returns bands oldest first, which is also draw order.
    static func bands(
        segments: [FocusLabSession.Segment],
        startedAt: Date?,
        now: Date,
        fullHeight: CGFloat,
        blend: CGFloat,
        progress: CGFloat
    ) -> [StrataBand] {
        guard let startedAt, !segments.isEmpty else { return [] }

        let wall: Double = max(0, now.timeIntervalSince(startedAt))
        let window: Double = max(3600, wall * 1.15)
        let stackMax: Double = Double(fullHeight) * stackShare
        let pointsPerSecond: Double = stackMax / window
        let eased: CGFloat = FocusLabMath.smoothstep(blend)
        let steady: CGFloat = FocusLabMath.clamp(progress)
        let lastIndex: Int = segments.count - 1

        var result: [StrataBand] = []
        var studyCount: Int = 0

        for (index, segment) in segments.enumerated() {
            let isStudy: Bool = segment.kind == .study
            let startOffset: Double = max(0, segment.start.timeIntervalSince(startedAt))
            let endDate: Date = segment.end ?? now
            let endOffset: Double = max(startOffset, endDate.timeIntervalSince(startedAt))

            let topT: CGFloat = fullHeight - CGFloat(endOffset * pointsPerSecond)
            var bottomT: CGFloat = fullHeight - CGFloat(startOffset * pointsPerSecond)
            // Grown downward so the next band up, drawn later, can't cover the seam.
            if !isStudy && bottomT - topT < seamMinimumHeight {
                bottomT = topT + seamMinimumHeight
            }

            let isCurrent: Bool = index == lastIndex
            let risen: CGFloat = fullHeight * (1 - steady)
            let topF: CGFloat = isCurrent ? min(risen, fullHeight - focusSliver) : fullHeight + 4
            let bottomF: CGFloat = isCurrent ? fullHeight : fullHeight + 4

            let top: CGFloat = FocusLabMath.lerp(topT, topF, eased)
            let bottom: CGFloat = FocusLabMath.lerp(bottomT, bottomF, eased)

            var color: Color = StrataPalette.seam
            var labelColor: Color = StrataPalette.ink
            if isStudy {
                let slot: Int = studyCount % StrataPalette.studyColors.count
                color = StrataPalette.studyColors[slot]
                labelColor = StrataPalette.studyLabelColors[slot]
                studyCount += 1
            }

            let minutes: Int = Int(((endOffset - startOffset) / 60).rounded())
            result.append(
                StrataBand(
                    id: segment.id,
                    top: top,
                    bottom: bottom,
                    color: color,
                    labelColor: labelColor,
                    isStudy: isStudy,
                    minutes: minutes
                )
            )
        }
        return result
    }
}
