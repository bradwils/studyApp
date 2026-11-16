//  DialFocusPage.swift
//  studyApp
//
//  DEV ONLY — Dial's focus page. Transparent, white text; the ring slot is left empty.

import SwiftUI

struct DialFocusPage: View {

    let session: FocusLabSession
    let ringDiameter: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text(session.selectedSubject.code)
                .font(DialFont.text(17, .semibold))
                .foregroundStyle(DialPalette.white)
                .frame(maxWidth: .infinity)
                .frame(height: DialLayout.headerHeight)
            slot
            if !session.hasFocusBlock {
                presets
                    .padding(.top, 20)
            }
            primaryButton
                .padding(.top, 20)
            lockButton
                .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var slot: some View {
        let side: CGFloat = DialLayout.slotSide(diameter: ringDiameter)
        return Color.clear
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity)
            .padding(.top, DialLayout.slotTop)
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
        let weight: Font.Weight = isSelected ? .semibold : .regular
        let opacity: Double = isSelected ? 1 : 0.55
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(Int(preset / 60))")
                .font(DialFont.text(19, weight))
                .foregroundStyle(DialPalette.white.opacity(opacity))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay {
                    if isSelected {
                        Capsule().stroke(DialPalette.white, lineWidth: 1.5)
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(DialPressStyle())
    }

    // MARK: - Buttons

    private func primaryTitle(at date: Date) -> String {
        guard session.hasFocusBlock else { return "Start focus block" }
        return session.isFocusComplete(at: date) ? "Finish" : "End block"
    }

    // Ticks so "End block" turns into "Finish" the moment the block completes.
    private var primaryButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            primaryButton(title: primaryTitle(at: context.date))
        }
    }

    private func primaryButton(title: String) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.35)) {
                if session.hasFocusBlock {
                    session.clearFocusBlock()
                } else {
                    session.startFocusBlock()
                }
            }
        } label: {
            Text(title)
                .font(DialFont.text(17, .medium))
                .foregroundStyle(DialPalette.cobalt)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background(DialPalette.white, in: Capsule())
        }
        .buttonStyle(DialPressStyle())
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            Text(session.isLocked ? "Unlock" : "Lock screen")
                .font(DialFont.text(15, .regular))
                .foregroundStyle(DialPalette.white.opacity(0.8))
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(DialPressStyle())
    }
}
