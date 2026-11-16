//  FloatPages.swift
//  studyApp
//
//  DEV ONLY — the two transparent pager pages of the Float design. The glass sheet and
//  timer live in the fixed layer; each page leaves an empty slot for them.

import SwiftUI

// MARK: - Tracking page

struct FloatTrackingPage: View {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .body) private var subjectSize: CGFloat = 17
    @ScaledMetric(relativeTo: .footnote) private var chipSize: CGFloat = 14

    private var primaryTitle: String {
        switch session.phase {
        case .idle: return "Start session"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            subjectHeader
                .frame(height: FloatLayout.headerHeight)

            Color.clear.frame(height: FloatLayout.slotGap + FloatLayout.slotHeight)

            buttons
                .padding(.top, 8)

            chips
                .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, FloatLayout.sideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Header

    @ViewBuilder
    private var subjectHeader: some View {
        if session.hasSession {
            Text(session.selectedSubject.name)
                .font(.system(size: subjectSize, weight: .semibold))
                .foregroundStyle(FloatPalette.ink)
                .lineLimit(1)
        } else {
            subjectMenu
        }
    }

    private var subjectMenu: some View {
        Menu {
            ForEach(session.subjects) { subject in
                Button(subject.name) { session.selectedSubject = subject }
            }
        } label: {
            HStack(spacing: 6) {
                Text(session.selectedSubject.name)
                    .font(.system(size: subjectSize, weight: .semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(FloatPalette.ink)
            .frame(minHeight: 44)
        }
    }

    // MARK: Buttons

    private var buttons: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                Button {
                    withAnimation(.smooth(duration: 0.4)) { session.toggle() }
                } label: {
                    Text(primaryTitle)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.glassProminent)

                if session.isPaused {
                    Button {
                        withAnimation(.smooth(duration: 0.4)) { session.end() }
                    } label: {
                        Text("End session")
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: session.phase)
    }

    // MARK: Chips

    private var chips: some View {
        HStack(spacing: 8) {
            FloatTodayChip(session: session, size: chipSize)
            Text("\(session.friends.count) friends studying")
                .font(.system(size: chipSize, weight: .medium))
                .foregroundStyle(FloatPalette.ink)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .glassEffect()
        }
    }
}

private struct FloatTodayChip: View {

    let session: FocusLabSession
    let size: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text("Today \(FloatFormat.hoursMinutes(session.todayTotal(at: context.date)))")
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(FloatPalette.ink)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .glassEffect()
        }
    }
}

// MARK: - Focus page

struct FloatFocusPage: View {

    let session: FocusLabSession

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17

    var body: some View {
        VStack(spacing: 0) {
            Text(session.selectedSubject.code)
                .font(.system(size: bodySize, weight: .semibold))
                .foregroundStyle(FloatPalette.white)
                .frame(height: FloatLayout.headerHeight)

            Color.clear.frame(height: FloatLayout.slotGap + FloatLayout.slotHeight)

            controls
                .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, FloatLayout.sideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if session.hasFocusBlock {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    blockButton(isComplete: session.isFocusComplete(at: context.date))
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
        .padding(.horizontal, 8)
        .glassEffect()
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let weight: Font.Weight = isSelected ? .semibold : .regular
        let textColor: Color = FloatPalette.white.opacity(isSelected ? 1 : 0.55)
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(Int(preset / 60))")
                .font(.system(size: bodySize, weight: weight))
                .foregroundStyle(textColor)
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
            Text("Start focus block")
                .padding(.horizontal, 8)
        }
        .buttonStyle(.glassProminent)
    }

    @ViewBuilder
    private func blockButton(isComplete: Bool) -> some View {
        if isComplete {
            Button {
                withAnimation(.smooth(duration: 0.35)) { session.clearFocusBlock() }
            } label: {
                Text("Finish")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button {
                withAnimation(.smooth(duration: 0.35)) { session.clearFocusBlock() }
            } label: {
                Text("End block")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glass)
        }
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            Text(session.isLocked ? "Unlock" : "Lock screen")
                .padding(.horizontal, 8)
        }
        .buttonStyle(.glass)
    }
}
