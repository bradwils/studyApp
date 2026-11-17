//  StarsFocusPage.swift
//  studyApp
//
//  DEV ONLY — Stars' focus page header and body. Transparent; the status row under the timer is left empty,
//  and the controls sit low so the figure around the timer stays clear.

import SwiftUI

struct StarsFocusHeader: View {

    let session: FocusLabSession

    var body: some View {
        Text(session.selectedSubject.code)
            .font(StarsFont.heading(18))
            .foregroundStyle(StarsPalette.star.opacity(0.85))
    }
}

struct StarsFocusPage: View {

    let session: FocusLabSession

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: StarsLayout.statusRowHeight)
            Spacer(minLength: 0)
            controls
                .padding(.bottom, 24)
        }
        .padding(.horizontal, StarsLayout.sidePadding)
        .frame(maxHeight: .infinity)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if !session.hasFocusBlock {
                presets
            }
            primaryButton
            lockButton
        }
    }

    // MARK: - Presets

    private var presets: some View {
        HStack(spacing: 4) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let minutes: Int = Int(preset / 60)
        let isSelected: Bool = session.focusDuration == preset
        let tint: Color = isSelected ? StarsPalette.starlight : StarsPalette.haze
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(minutes)")
                .font(StarsFont.text(18))
                .foregroundStyle(tint)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(StarsPressStyle())
        .accessibilityLabel("\(minutes) minutes")
    }

    // MARK: - Buttons

    private func primaryTitle(at date: Date) -> String {
        guard session.hasFocusBlock else { return "Start focus block" }
        return session.isFocusComplete(at: date) ? "Finish" : "End block"
    }

    // Ticks so "End block" turns into "Finish" the moment the block completes.
    private var primaryButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            primaryPill(title: primaryTitle(at: context.date))
        }
    }

    private func primaryPill(title: String) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.5)) { toggleBlock() }
        } label: {
            StarsPill(
                title: title,
                textColor: StarsPalette.starlight,
                fill: Color.clear,
                stroke: StarsPalette.starlight,
                strokeWidth: 1.5
            )
        }
        .buttonStyle(StarsPressStyle())
    }

    private func toggleBlock() {
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
                .font(StarsFont.text(15))
                .foregroundStyle(StarsPalette.haze)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(StarsPressStyle())
    }
}
