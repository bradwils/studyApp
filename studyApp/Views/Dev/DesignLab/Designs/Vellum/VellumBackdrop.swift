//  VellumBackdrop.swift
//  studyApp
//
//  DEV ONLY — Vellum's fixed layer: Milk, the five sheets, and the status line pinned under the timer.

import SwiftUI

struct VellumBackdrop: View {

    let session: FocusLabSession
    let layout: VellumLayout
    let blend: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            VellumPalette.milk
            sheetsLayer
            pinnedStatus
        }
        .frame(width: layout.fullWidth, height: layout.fullHeight, alignment: .topLeading)
    }

    private var textColor: Color {
        let flip: CGFloat = FocusLabMath.window(blend, 0.55, 0.85)
        return VellumPalette.ink.labBlend(VellumPalette.white, flip)
    }

    private var sheetsLayer: some View {
        let bloomAnimation: Animation? = reduceMotion ? nil : .smooth(duration: 1)
        return TimelineView(.periodic(from: .now, by: 1)) { context in
            let progress: Double = session.focusProgress(at: context.date) ?? 0
            let bloom: CGFloat = FocusLabMath.smoothstep(CGFloat(progress))
            VellumSheetStack(sheets: layout.sheets(blend: blend, bloom: bloom))
                .animation(bloomAnimation, value: bloom)
        }
        .frame(width: layout.fullWidth, height: layout.fullHeight)
    }

    private var pinnedStatus: some View {
        VellumStatus(session: session, blend: blend)
            .foregroundStyle(textColor.opacity(0.75))
            .position(x: layout.timerBackdropCenter.x, y: layout.timerBackdropCenter.y + 40)
    }
}

private struct VellumSheetStack: View {

    let sheets: [VellumSheet]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(sheets) { sheet in
                RoundedRectangle(cornerRadius: sheet.radius, style: .continuous)
                    .fill(sheet.color.opacity(VellumLayout.sheetOpacity))
                    .frame(width: sheet.width, height: sheet.height)
                    .rotationEffect(.degrees(sheet.degrees))
                    .position(x: sheet.center.x, y: sheet.center.y)
                    .blendMode(.multiply)
            }
        }
    }
}

private struct VellumStatus: View {

    let session: FocusLabSession
    let blend: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let trackingOpacity: Double = Double(1 - blend)
            let focusOpacity: Double = Double(blend)
            ZStack {
                Text(trackingText)
                    .opacity(trackingOpacity)
                Text(focusText(at: context.date))
                    .opacity(focusOpacity)
            }
            .font(VellumFont.text(14, .regular))
        }
    }

    private var trackingText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Ready" }
            let minutes: Int = max(1, Int((length / 60).rounded()))
            return "Saved \(minutes) min"
        case .running:
            return "Studying"
        case .paused:
            return "On a break"
        }
    }

    private func focusText(at date: Date) -> String {
        guard session.hasFocusBlock else { return "No block yet" }
        if session.isFocusComplete(at: date) { return "Complete" }
        if session.isPaused { return "On a break" }
        return "of \(blockMinutes) min"
    }

    private var blockMinutes: Int {
        guard let start = session.focusStart, let goal = session.focusGoal else {
            return Int(session.focusDuration / 60)
        }
        return Int((goal.timeIntervalSince(start) / 60).rounded())
    }
}
