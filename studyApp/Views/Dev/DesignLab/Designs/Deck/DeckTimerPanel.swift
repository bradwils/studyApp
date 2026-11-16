//  DeckTimerPanel.swift
//  studyApp
//
//  DEV ONLY — the contents of Deck's timer panel on the tracking page: subject and
//  today's total on top, session buttons at the bottom. The fill lives in the backdrop
//  and the timer itself in the pinned layer, so this view leaves the middle empty.

import SwiftUI

struct DeckTimerPanel: View {

    let session: FocusLabSession
    let layout: DeckLayout

    @ScaledMetric(relativeTo: .subheadline) private var headingSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) private var captionSize: CGFloat = 13
    @ScaledMetric(relativeTo: .body) private var buttonSize: CGFloat = 17

    private var headingFont: Font {
        .system(size: headingSize, weight: .semibold, design: .rounded)
    }

    private var buttonFont: Font {
        .system(size: buttonSize, weight: .semibold, design: .rounded)
    }

    var body: some View {
        let fade: Double = Double(1 - FocusLabMath.window(layout.blend, 0, 0.45))
        let panel: CGRect = layout.trackingPanel
        return VStack(spacing: 0) {
            topRow
            Spacer(minLength: 0)
            bottomRow
        }
        .padding(18)
        .frame(width: panel.width, height: panel.height)
        .opacity(fade)
    }

    // MARK: - Top row

    private var topRow: some View {
        HStack(alignment: .top, spacing: 8) {
            subjectView
            Spacer(minLength: 8)
            todayView
        }
    }

    @ViewBuilder
    private var subjectView: some View {
        if session.hasSession {
            subjectLabel(showsChevron: false)
        } else {
            Menu {
                ForEach(session.subjects) { subject in
                    Button(subject.name) { session.selectedSubject = subject }
                }
            } label: {
                subjectLabel(showsChevron: true)
            }
        }
    }

    private func subjectLabel(showsChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Text(session.selectedSubject.name)
                .font(headingFont)
                .foregroundStyle(DeckPalette.wine)
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DeckPalette.wine)
            }
        }
        .frame(minHeight: 44, alignment: .topLeading)
    }

    private var todayView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Today")
                .font(.system(size: captionSize))
                .foregroundStyle(DeckPalette.mulberry)
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(DeckFormat.hoursMinutes(session.todayTotal(at: context.date)))
                    .font(headingFont)
                    .foregroundStyle(DeckPalette.wine)
            }
        }
    }

    // MARK: - Bottom row

    private var bottomRow: some View {
        HStack(spacing: 10) {
            primaryButton
            if session.isPaused {
                endButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var primaryTitle: String {
        switch session.phase {
        case .idle: return "Start session"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var primaryButton: some View {
        let isPaused: Bool = session.isPaused
        let sidePad: CGFloat = isPaused ? 40 : 26
        let topPad: CGFloat = isPaused ? 16 : 13
        let minHeight: CGFloat = isPaused ? 56 : 48
        return Button {
            withAnimation(.smooth(duration: 0.45)) { session.toggle() }
        } label: {
            Text(primaryTitle)
                .font(buttonFont)
                .foregroundStyle(DeckPalette.petal)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, sidePad)
                .padding(.vertical, topPad)
                .frame(minHeight: minHeight)
                .background(Capsule().fill(DeckPalette.wine))
        }
        .buttonStyle(DeckPressStyle())
    }

    private var endButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.45)) { session.end() }
        } label: {
            Text("End session")
                .font(buttonFont)
                .foregroundStyle(DeckPalette.wine)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 26)
                .padding(.vertical, 13)
                .frame(minHeight: 48)
                .overlay(Capsule().stroke(DeckPalette.wine, lineWidth: 1.5))
        }
        .buttonStyle(DeckPressStyle())
    }
}
