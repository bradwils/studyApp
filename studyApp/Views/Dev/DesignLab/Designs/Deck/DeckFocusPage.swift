//  DeckFocusPage.swift
//  studyApp
//
//  DEV ONLY — Deck's focus page. Transparent, sitting on the wine-coloured panel; the
//  timer, status line and progress bar come from the pinned layer.

import SwiftUI

struct DeckFocusPage: View {

    let session: FocusLabSession
    let layout: DeckLayout

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 15
    @ScaledMetric(relativeTo: .body) private var numeralSize: CGFloat = 17
    @ScaledMetric(relativeTo: .body) private var buttonSize: CGFloat = 17

    var body: some View {
        let fade: Double = Double(FocusLabMath.window(layout.blend, 0.55, 1))
        return VStack(spacing: 0) {
            Text(session.selectedSubject.code)
                .font(.system(size: textSize, weight: .semibold, design: .rounded))
                .foregroundStyle(DeckPalette.petal.opacity(0.8))
                .padding(.top, 20)
            Spacer(minLength: 0)
            if !session.hasFocusBlock {
                presets
                    .padding(.bottom, 12)
            }
            primaryButton
            lockButton
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(fade)
        .allowsHitTesting(layout.blend > 0.5)
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
        let isSelected: Bool = session.focusDuration == preset
        let textColor: Color = isSelected ? DeckPalette.wine : DeckPalette.petal.opacity(0.6)
        let fill: Color = isSelected ? DeckPalette.lime : Color.clear
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(Int(preset / 60))")
                .font(.system(size: numeralSize, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(fill))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Primary and lock

    private var primaryButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            primary(isComplete: session.isFocusComplete(at: context.date))
        }
    }

    private func primary(isComplete: Bool) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.45)) { primaryAction() }
        } label: {
            Text(primaryTitle(isComplete: isComplete))
                .font(.system(size: buttonSize, weight: .semibold, design: .rounded))
                .foregroundStyle(DeckPalette.wine)
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .frame(minHeight: 50)
                .background(Capsule().fill(DeckPalette.petal))
        }
        .buttonStyle(DeckPressStyle())
    }

    private func primaryTitle(isComplete: Bool) -> String {
        guard session.hasFocusBlock else { return "Start focus block" }
        return isComplete ? "Finish" : "End block"
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
                .font(.system(size: textSize))
                .foregroundStyle(DeckPalette.petal.opacity(0.7))
                .frame(minWidth: 88, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
