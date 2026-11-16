//  StrataFocusPage.swift
//  studyApp
//
//  DEV ONLY — Strata's focus page. Transparent; the current band rises behind these
//  controls, so there are no backing cards.

import SwiftUI

struct StrataFocusPage: View {

    let session: FocusLabSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            lower
                .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, StrataLayout.contentX)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Below the timer

    private var lower: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let complete: Bool = session.isFocusComplete(at: context.date)
            let buttonGap: CGFloat = session.hasFocusBlock ? 20 : 12
            VStack(alignment: .leading, spacing: 0) {
                Text(statusText(complete: complete))
                    .font(StrataFont.sans(13, .regular))
                    .foregroundStyle(StrataPalette.ink.opacity(0.7))
                if !session.hasFocusBlock {
                    presets
                        .padding(.top, 20)
                }
                buttons(complete: complete)
                    .padding(.top, buttonGap)
            }
        }
    }

    private func statusText(complete: Bool) -> String {
        let minutes: Int = Int(session.focusDuration / 60)
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "This layer is \(minutes) minutes tall" }
        if complete { return "Layer complete" }
        return "left of \(minutes) minutes"
    }

    // MARK: - Presets

    private var presets: some View {
        HStack(spacing: 6) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let minutes: Int = Int(preset / 60)
        let fillColor: Color = isSelected ? StrataPalette.ink : Color.clear
        let textColor: Color = isSelected ? StrataPalette.haze : StrataPalette.ink.opacity(0.55)
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(minutes)")
                .font(StrataFont.sans(19, .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(fillColor, in: RoundedRectangle(cornerRadius: 8))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(StrataPressStyle())
    }

    // MARK: - Buttons

    private func primaryTitle(complete: Bool) -> String {
        if complete { return "Finish" }
        return session.hasFocusBlock ? "End block" : "Start focus block"
    }

    private func buttons(complete: Bool) -> some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.smooth(duration: 0.35)) { primaryAction() }
            } label: {
                StrataPrimaryLabel(title: primaryTitle(complete: complete))
            }
            .buttonStyle(StrataPressStyle())

            Button {
                session.isLocked.toggle()
            } label: {
                Text(session.isLocked ? "Unlock" : "Lock screen")
                    .font(StrataFont.sans(17, .regular))
                    .underline()
                    .foregroundStyle(StrataPalette.ink)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StrataPressStyle())
        }
    }

    private func primaryAction() {
        if session.hasFocusBlock {
            session.clearFocusBlock()
        } else {
            session.startFocusBlock()
        }
    }
}
