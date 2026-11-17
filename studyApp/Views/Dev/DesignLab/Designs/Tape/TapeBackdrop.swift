//  TapeBackdrop.swift
//  studyApp
//
//  DEV ONLY — Tape's fixed band: background, tape, needle and status line.
//  Nothing here slides with the pages; it all reads blend.

import SwiftUI

struct TapeBackdrop: View {

    let session: FocusLabSession
    let context: FocusPagerContext
    let reduceMotion: Bool

    private var metrics: FocusPagerStageMetrics { context.metrics }
    private var blend: CGFloat { context.blend }

    private var centerX: CGFloat {
        metrics.fullSize.width / 2
    }

    private var tapeCenterY: CGFloat {
        context.timerBackdropRect.maxY + TapeLayout.tapeTopInset + TapeLayout.tapeHeight / 2
    }

    var body: some View {
        let full: CGSize = metrics.fullSize
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(TapePalette.fog.labBlend(TapePalette.slate, blend))
            ribbon
            TapeNeedle()
                .position(x: metrics.backdropX(metrics.safeSize.width / 2), y: tapeCenterY)
            TapeStatus(session: session, blend: blend)
                .position(x: centerX, y: context.timerBackdropRect.maxY + TapeLayout.statusCenterInset)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private var ribbon: some View {
        TapeRibbon(
            session: session,
            needleX: metrics.backdropX(metrics.safeSize.width / 2),
            width: metrics.fullSize.width,
            columnWidth: context.contentRect.width,
            blend: blend,
            reduceMotion: reduceMotion
        )
        .position(x: centerX, y: tapeCenterY)
    }
}

// MARK: - Status line

private struct TapeStatus: View {

    let session: FocusLabSession
    let blend: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            lines(complete: session.isFocusComplete(at: context.date))
        }
    }

    private func lines(complete: Bool) -> some View {
        let color: Color = TapePalette.haze.labBlend(TapePalette.pale, blend)
        return ZStack {
            Text(trackingText)
                .opacity(Double(1 - blend))
            Text(focusText(complete: complete))
                .opacity(Double(blend))
        }
        .font(TapeFont.text(13, .regular))
        .foregroundStyle(color)
        .lineLimit(1)
    }

    private var trackingText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Ready to measure" }
            return "Saved \(Int(length / 60)) min"
        case .running:
            return "Studying"
        case .paused:
            return "On a break"
        }
    }

    private func focusText(complete: Bool) -> String {
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "No block marked" }
        return complete ? "Reached the flag" : "to the flag"
    }
}
