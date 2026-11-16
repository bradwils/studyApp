//  TidePages.swift
//  studyApp
//
//  DEV ONLY — the two transparent pager pages of the Tide design. The timer and status
//  line live in the backdrop; each page leaves an empty slot for them.

import SwiftUI

// MARK: - Tracking page

struct TideTrackingPage: View {

    let session: FocusLabSession
    let timerSlotHeight: CGFloat

    @ScaledMetric(relativeTo: .title3) private var titleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17
    @ScaledMetric(relativeTo: .footnote) private var captionSize: CGFloat = 14

    private var titleFont: Font { .system(size: titleSize, weight: .medium, design: .rounded) }
    private var captionFont: Font { .system(size: captionSize, weight: .regular, design: .rounded) }

    private var slotGap: CGFloat {
        TideLayout.timerGap + timerSlotHeight + TideLayout.statusRowHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: TideLayout.headerHeight)

            Color.clear.frame(height: slotGap)

            buttons
                .padding(.top, 14)

            Spacer(minLength: 0)

            friendsLine
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            subjectBlock
            Spacer(minLength: 12)
            totalBlock
        }
    }

    private var subjectBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            subjectPicker
            Text(session.selectedSubject.code)
                .font(captionFont)
                .foregroundStyle(TidePalette.deep.opacity(0.6))
        }
    }

    @ViewBuilder
    private var subjectPicker: some View {
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
                .font(titleFont)
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundStyle(TidePalette.deep)
        .frame(minHeight: 44)
    }

    private var totalBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(TideFormat.hoursMinutes(session.todayTotal(at: context.date)))
                    .font(titleFont)
                    .foregroundStyle(TidePalette.deep)
            }
            Text("of 4 h today")
                .font(captionFont)
                .foregroundStyle(TidePalette.deep.opacity(0.6))
        }
    }

    // MARK: Buttons

    private var primaryTitle: String {
        switch session.phase {
        case .idle: return "Start session"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.smooth(duration: 0.4)) { session.toggle() }
            } label: {
                TideButtonLabel(title: primaryTitle, color: TidePalette.foam, size: bodySize)
            }
            .buttonStyle(.glassProminent)
            .tint(TidePalette.lagoon)

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                } label: {
                    TideButtonLabel(title: "End session", color: TidePalette.deep, size: bodySize)
                }
                .buttonStyle(.glass)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: session.phase)
    }

    // MARK: Friends

    private var friendsSentence: String? {
        let names: [String] = session.friends.map { $0.name }
        guard let last = names.last else { return nil }
        guard names.count > 1 else { return "\(last) is studying" }
        let lead: String = names.dropLast().joined(separator: ", ")
        return "\(lead) and \(last) are studying"
    }

    @ViewBuilder
    private var friendsLine: some View {
        if let sentence = friendsSentence {
            Text(sentence)
                .font(captionFont)
                .foregroundStyle(TidePalette.foam)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Focus page

struct TideFocusPage: View {

    let session: FocusLabSession
    let timerSlotHeight: CGFloat

    @ScaledMetric(relativeTo: .title3) private var titleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17

    private var slotGap: CGFloat {
        TideLayout.timerGap + timerSlotHeight + TideLayout.statusRowHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(session.selectedSubject.code)
                .font(.system(size: titleSize, weight: .medium, design: .rounded))
                .foregroundStyle(TidePalette.deep)
                .frame(height: TideLayout.headerHeight)

            Color.clear.frame(height: slotGap)

            controls
                .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if session.hasFocusBlock {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    blockEndButton(isComplete: session.isFocusComplete(at: context.date))
                }
            } else {
                presetRow
                startButton
            }
            lockButton
        }
    }

    // MARK: Presets

    private var presetRow: some View {
        HStack(spacing: 0) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
        .padding(.horizontal, 12)
        .background { Capsule().fill(TidePalette.foam.opacity(0.55)) }
        .glassEffect()
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let weight: Font.Weight = isSelected ? .semibold : .regular
        let textColor: Color = isSelected ? TidePalette.deep : TidePalette.deep.opacity(0.5)
        let underline: Color = isSelected ? TidePalette.lagoon : Color.clear
        return Button {
            session.focusDuration = preset
        } label: {
            VStack(spacing: 2) {
                Text("\(Int(preset / 60))")
                    .font(.system(size: titleSize, weight: weight, design: .rounded))
                    .foregroundStyle(textColor)
                Capsule()
                    .fill(underline)
                    .frame(width: 18, height: 2)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Buttons

    private var startButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.35)) { session.startFocusBlock() }
        } label: {
            TideButtonLabel(title: "Start focus block", color: TidePalette.foam, size: bodySize)
        }
        .buttonStyle(.glassProminent)
        .tint(TidePalette.lagoon)
    }

    @ViewBuilder
    private func blockEndButton(isComplete: Bool) -> some View {
        if isComplete {
            Button {
                withAnimation(.smooth(duration: 0.35)) { session.clearFocusBlock() }
            } label: {
                TideButtonLabel(title: "Finish", color: TidePalette.foam, size: bodySize)
            }
            .buttonStyle(.glassProminent)
            .tint(TidePalette.lagoon)
        } else {
            Button {
                withAnimation(.smooth(duration: 0.35)) { session.clearFocusBlock() }
            } label: {
                TideButtonLabel(title: "End block", color: TidePalette.deep, size: bodySize)
            }
            .buttonStyle(.glass)
        }
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            TideButtonLabel(
                title: session.isLocked ? "Unlock" : "Lock screen",
                color: TidePalette.deep,
                size: bodySize
            )
        }
        .buttonStyle(.glass)
    }
}
