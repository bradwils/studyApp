//  TicketPinned.swift
//  studyApp
//
//  DEV ONLY — Ticket's fixed layers. TicketPaper (ticket body, notches, perforation) sits
//  under the pager; TicketPinned (punches, timer, caption, break stamp) sits above it.

import SwiftUI

// MARK: - Paper

struct TicketPaper: View {

    let session: FocusLabSession
    let layout: TicketLayout
    let blend: CGFloat

    var body: some View {
        let notchY: CGFloat = layout.ticket.minY + layout.perforationY
        ZStack(alignment: .topLeading) {
            ticketBody
            perforation
            notch(x: layout.ticket.minX, y: notchY)
            notch(x: layout.ticket.maxX, y: notchY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(.smooth(duration: 0.45), value: session.isPaused)
    }

    private var ticketBody: some View {
        let rect: CGRect = layout.ticket
        let fill: Color = session.isPaused ? TicketPalette.dim : TicketPalette.paper
        return RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous)
            .fill(fill)
            .frame(width: rect.width, height: rect.height)
            .shadow(color: TicketPalette.navy.opacity(0.14), radius: 18, y: 8)
            .position(x: rect.midX, y: rect.midY)
    }

    private var perforation: some View {
        let rect: CGRect = layout.ticket
        let lineY: CGFloat = rect.minY + layout.perforationY
        let startX: CGFloat = rect.minX + TicketLayout.perforationInset
        let endX: CGFloat = rect.maxX - TicketLayout.perforationInset
        let style = StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 6])
        return Path { path in
            path.move(to: CGPoint(x: startX, y: lineY))
            path.addLine(to: CGPoint(x: endX, y: lineY))
        }
        .stroke(TicketPalette.navy.opacity(0.25), style: style)
    }

    private func notch(x: CGFloat, y: CGFloat) -> some View {
        let color: Color = TicketPalette.background(isPaused: session.isPaused, blend: blend)
        return Circle()
            .fill(color)
            .frame(width: TicketLayout.notchDiameter, height: TicketLayout.notchDiameter)
            .position(x: x, y: y)
    }
}

// MARK: - Pinned

struct TicketPinned: View {

    let session: FocusLabSession
    let layout: TicketLayout
    let blend: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 70

    var body: some View {
        ZStack(alignment: .topLeading) {
            TicketPunchRow(session: session, layout: layout)
                .opacity(Double(blend))
            timer
            caption
            TicketStamp(session: session, layout: layout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(.smooth(duration: 0.45), value: session.isPaused)
    }

    private var timer: some View {
        let digitWidth: CGFloat = timerSize * 0.62
        let color: Color = session.isPaused ? TicketPalette.cherry : TicketPalette.navy
        return FocusLabClock(session: session, idleText: "0:00", digitWidth: digitWidth)
            .font(Font.custom("Futura-Medium", fixedSize: timerSize))
            .foregroundStyle(color)
            .scaleEffect(layout.timerScale)
            .position(layout.timerCenter)
    }

    private var caption: some View {
        let captionY: CGFloat = layout.timerCenter.y + TicketLayout.captionDrop
        return TicketCaption(session: session, blend: blend)
            .position(x: layout.timerCenter.x, y: captionY)
    }
}

private struct TicketCaption: View {

    let session: FocusLabSession
    let blend: CGFloat

    private var trackingText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Tap start to begin" }
            return "Saved \(Int(length / 60)) min"
        case .running:
            return "Studying"
        case .paused:
            return "Break time"
        }
    }

    private func focusText(at date: Date) -> String {
        if session.isPaused { return "Break time" }
        guard session.hasFocusBlock else { return "No block set" }
        if session.isFocusComplete(at: date) { return "All ten punched" }
        return "left of \(Int(session.focusDuration / 60)) minutes"
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                Text(trackingText)
                    .opacity(Double(1 - blend))
                Text(focusText(at: context.date))
                    .opacity(Double(blend))
            }
            .font(TicketFont.medium(13))
            .foregroundStyle(TicketPalette.mauve)
            .lineLimit(1)
        }
    }
}

private struct TicketPunchRow: View {

    let session: FocusLabSession
    let layout: TicketLayout

    var body: some View {
        let rect: CGRect = layout.ticket
        let rowWidth: CGFloat = rect.width - 2 * TicketLayout.punchSideInset
        let rowY: CGFloat = rect.minY + layout.perforationY - TicketLayout.punchLift
        TimelineView(.periodic(from: .now, by: 1)) { context in
            row(punched: punchedCount(at: context.date), width: rowWidth)
        }
        .frame(width: rowWidth, height: TicketLayout.punchDiameter)
        .position(x: rect.midX, y: rowY)
    }

    private func punchedCount(at date: Date) -> Int {
        let progress: Double = session.focusProgress(at: date) ?? 0
        return Int(progress * Double(TicketLayout.punchCount))
    }

    private func row(punched: Int, width: CGFloat) -> some View {
        let count: Int = TicketLayout.punchCount
        let gaps: CGFloat = CGFloat(count - 1)
        let used: CGFloat = TicketLayout.punchDiameter * CGFloat(count)
        let gap: CGFloat = max((width - used) / gaps, 0)
        return HStack(spacing: gap) {
            ForEach(0..<count, id: \.self) { index in
                punch(isFilled: index < punched)
            }
        }
        .animation(.smooth(duration: 0.3), value: punched)
    }

    @ViewBuilder
    private func punch(isFilled: Bool) -> some View {
        if isFilled {
            Circle()
                .fill(TicketPalette.cherry)
                .frame(width: TicketLayout.punchDiameter, height: TicketLayout.punchDiameter)
        } else {
            Circle()
                .strokeBorder(TicketPalette.navy.opacity(0.25), lineWidth: 1.5)
                .frame(width: TicketLayout.punchDiameter, height: TicketLayout.punchDiameter)
        }
    }
}

private struct TicketStamp: View {

    let session: FocusLabSession
    let layout: TicketLayout

    var body: some View {
        let stampX: CGFloat = layout.ticket.midX + 70
        let stampY: CGFloat = layout.ticket.minY + 44
        // The stamp scales about its own centre because the always-present frame is what gets positioned.
        ZStack {
            if session.isPaused {
                stamp
                    .transition(.scale(scale: 1.4).combined(with: .opacity))
            }
        }
        .frame(width: 220, height: 90)
        .position(x: stampX, y: stampY)
    }

    private var stamp: some View {
        Text("On a break")
            .font(TicketFont.bold(22))
            .foregroundStyle(TicketPalette.cherry)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TicketPalette.cherry, lineWidth: 2.5)
            }
            .rotationEffect(.degrees(-9))
            .opacity(0.9)
    }
}
