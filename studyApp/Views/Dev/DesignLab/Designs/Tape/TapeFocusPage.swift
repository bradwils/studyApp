//  TapeFocusPage.swift
//  studyApp
//
//  DEV ONLY — Tape's focus page, as a header and a body. Transparent, light text; the body leaves room for the status line and tape.

import SwiftUI

struct TapeFocusHeader: View {

    let session: FocusLabSession

    var body: some View {
        Text(session.selectedSubject.code)
            .font(TapeFont.text(20, .semibold))
            .foregroundStyle(TapePalette.tape)
            .frame(maxWidth: .infinity)
    }
}

struct TapeFocusBody: View {

    let session: FocusLabSession

    var body: some View {
        let blockGap: CGFloat = session.hasFocusBlock ? 24 : 12
        return VStack(spacing: 0) {
            Color.clear
                .frame(height: TapeLayout.bodyTopInset)
            if !session.hasFocusBlock {
                presets
                    .padding(.top, 24)
            }
            primaryButton
                .padding(.top, blockGap)
            lockButton
                .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        let color: Color = isSelected ? TapePalette.tape : TapePalette.pale.opacity(0.6)
        let barColor: Color = isSelected ? TapePalette.poppy : Color.clear
        return Button {
            session.focusDuration = preset
        } label: {
            VStack(spacing: 3) {
                Text("\(Int(preset / 60))")
                    .font(TapeFont.text(19, weight))
                    .foregroundStyle(color)
                Capsule()
                    .fill(barColor)
                    .frame(width: 20, height: 3)
            }
            .frame(minWidth: 52, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(TapePressStyle())
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
            withAnimation(.smooth(duration: 0.35)) {
                if session.hasFocusBlock {
                    session.clearFocusBlock()
                } else {
                    session.startFocusBlock()
                }
            }
        } label: {
            Text(title)
                .font(TapeFont.text(17, .medium))
                .foregroundStyle(TapePalette.slate)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background(TapePalette.tape, in: Capsule())
        }
        .buttonStyle(TapePressStyle())
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            Text(session.isLocked ? "Unlock" : "Lock screen")
                .font(TapeFont.text(15, .regular))
                .foregroundStyle(TapePalette.pale)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(TapePressStyle())
    }
}
