//  FloatPinned.swift
//  studyApp
//
//  DEV ONLY — the fixed layer of the Float design: one glass sheet that draws itself in
//  from a slab to a circle, the timer inside it, a status line and the focus ring.

import SwiftUI

struct FloatPinned: View {

    let session: FocusLabSession
    let blend: CGFloat
    let width: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 86

    private var textColor: Color {
        let flip: CGFloat = FocusLabMath.window(blend, 0.4, 0.7)
        return FloatPalette.ink.labBlend(FloatPalette.white, flip)
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: FloatLayout.headerHeight + FloatLayout.slotGap)
            slot
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private var slot: some View {
        ZStack {
            glassSheet
            FloatRing(session: session)
                .opacity(Double(FocusLabMath.window(blend, 0.7, 1)))
            timer
            FloatStatus(session: session, blend: blend, color: textColor)
                .offset(y: 44)
        }
        .frame(maxWidth: .infinity)
        .frame(height: FloatLayout.slotHeight)
    }

    private var glassSheet: some View {
        let sheetWidth: CGFloat = FocusLabMath.lerp(width - 40, 244, blend)
        let sheetHeight: CGFloat = FocusLabMath.lerp(188, 244, blend)
        let sheetRadius: CGFloat = FocusLabMath.lerp(44, 122, blend)
        return Color.clear
            .frame(width: sheetWidth, height: sheetHeight)
            .glassEffect(.regular, in: .rect(cornerRadius: sheetRadius))
    }

    private var timer: some View {
        FocusLabClock(session: session, idleText: "0:00")
            .font(.system(size: timerSize, weight: .thin))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: 230)
    }
}

private struct FloatRing: View {

    let session: FocusLabSession

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 3)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                progressArc(at: context.date)
            }
        }
        .frame(width: 232, height: 232)
    }

    private func progressArc(at date: Date) -> some View {
        let progress: Double = session.focusProgress(at: date) ?? 0
        return Circle()
            .trim(from: 0, to: CGFloat(progress))
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .opacity(progress < 0.002 ? 0 : 1)
            .animation(.linear(duration: 1), value: progress)
    }
}

private struct FloatStatus: View {

    let session: FocusLabSession
    let blend: CGFloat
    let color: Color

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 15

    private var trackingText: String {
        switch session.phase {
        case .running:
            return "Studying"
        case .paused:
            return "On a break"
        case .idle:
            guard let length = session.lastCompletedLength else { return "Ready" }
            return "Saved \(Int(length / 60)) min"
        }
    }

    private func focusText(at date: Date) -> String {
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "No block yet" }
        if session.isFocusComplete(at: date) { return "Complete" }
        return "of \(Int(session.focusDuration / 60)) min"
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                Text(trackingText)
                    .opacity(Double(1 - blend))
                Text(focusText(at: context.date))
                    .opacity(Double(blend))
            }
            .font(.system(size: textSize, weight: .regular))
            .foregroundStyle(color.opacity(0.7))
            .lineLimit(1)
        }
    }
}
