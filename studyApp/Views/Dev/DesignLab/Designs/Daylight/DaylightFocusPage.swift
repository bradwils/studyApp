//  DaylightFocusPage.swift
//  studyApp
//
//  DEV ONLY — the Daylight design's focus page body and header. Transparent; the controls sit on the ground.

import SwiftUI

struct DaylightFocusPage: View {
    let session: FocusLabSession
    let geometry: DaylightGeometry

    @ScaledMetric(relativeTo: .footnote) private var captionSize: CGFloat = 14
    @ScaledMetric(relativeTo: .title3) private var presetSize: CGFloat = 20
    @ScaledMetric(relativeTo: .subheadline) private var lockSize: CGFloat = 15

    var body: some View {
        ZStack(alignment: .top) {
            statusLine
                .padding(.top, 6)
            controls
                .padding(.top, geometry.controlsOffset)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Above the horizon

    private var statusLine: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(statusText(at: context.date))
                .font(DaylightFont.caption(captionSize))
                .foregroundStyle(DaylightPalette.plum.opacity(0.7))
        }
    }

    private var blockMinutes: Int {
        guard let start = session.focusStart, let goal = session.focusGoal else { return 0 }
        return Int((goal.timeIntervalSince(start) / 60).rounded())
    }

    private func statusText(at date: Date) -> String {
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "Choose a length below" }
        if session.isFocusComplete(at: date) { return "Block complete" }
        return "left of \(blockMinutes) minutes"
    }

    // MARK: - On the ground

    private var controls: some View {
        VStack(spacing: 12) {
            if !session.hasFocusBlock {
                presets
            }

            primaryButton

            lockButton
        }
        .frame(maxWidth: .infinity)
    }

    private var presets: some View {
        HStack(spacing: 4) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let textColor: Color = isSelected ? DaylightPalette.plum : DaylightPalette.chalk.opacity(0.6)
        let font: Font = isSelected ? DaylightFont.name(presetSize) : DaylightFont.body(presetSize)
        return Button {
            withAnimation(.smooth(duration: 0.25)) { session.focusDuration = preset }
        } label: {
            Text("\(Int(preset / 60))")
                .font(font)
                .foregroundStyle(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background { presetBackground(isSelected) }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(DaylightPressStyle())
    }

    @ViewBuilder
    private func presetBackground(_ isSelected: Bool) -> some View {
        if isSelected {
            Capsule().fill(DaylightPalette.marigold)
        }
    }

    private var primaryButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            DaylightPill(
                title: primaryTitle(at: context.date),
                textColor: DaylightPalette.ground,
                fill: DaylightPalette.chalk
            ) {
                withAnimation(.smooth(duration: 0.4)) { primaryAction() }
            }
        }
    }

    private func primaryTitle(at date: Date) -> String {
        guard session.hasFocusBlock else { return "Start focus block" }
        return session.isFocusComplete(at: date) ? "Finish" : "End block"
    }

    private func primaryAction() {
        if session.hasFocusBlock {
            session.clearFocusBlock()
        } else {
            session.startFocusBlock()
        }
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            Text(session.isLocked ? "Unlock" : "Lock screen")
                .font(DaylightFont.body(lockSize))
                .foregroundStyle(DaylightPalette.chalk.opacity(0.8))
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(DaylightPressStyle())
    }
}

struct DaylightFocusHeader: View {
    let session: FocusLabSession

    @ScaledMetric(relativeTo: .title3) private var nameSize: CGFloat = 20

    var body: some View {
        Text(session.selectedSubject.code)
            .font(DaylightFont.name(nameSize))
            .foregroundStyle(DaylightPalette.plum)
    }
}
