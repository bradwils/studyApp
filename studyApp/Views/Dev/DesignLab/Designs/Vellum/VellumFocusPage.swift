//  VellumFocusPage.swift
//  studyApp
//
//  DEV ONLY — Vellum's focus page header and body. Transparent; the controls
//  fade in late so the arriving sheets don't cross them at full strength.

import SwiftUI

struct VellumFocusHeader: View {

    let session: FocusLabSession

    var body: some View {
        Text(session.selectedSubject.code)
            .font(VellumFont.text(20, .semibold))
            .foregroundStyle(VellumPalette.ink)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, VellumLayout.sidePadding)
    }
}

struct VellumFocusPage: View {

    let session: FocusLabSession
    let blend: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            controls
                .padding(.top, 48)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, VellumLayout.sidePadding)
    }

    private var controls: some View {
        let fade: Double = Double(FocusLabMath.window(blend, 0.6, 1))
        return VStack(spacing: 8) {
            if !session.hasFocusBlock {
                presets
            }
            primaryButton
            lockButton
        }
        .opacity(fade)
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
        let color: Color = isSelected ? VellumPalette.ink : VellumPalette.dust
        let dot: Color = isSelected ? VellumPalette.ink : Color.clear
        return Button {
            session.focusDuration = preset
        } label: {
            VStack(spacing: 3) {
                Text("\(Int(preset / 60))")
                    .font(VellumFont.text(19, weight))
                    .foregroundStyle(color)
                Circle()
                    .fill(dot)
                    .frame(width: 6, height: 6)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(VellumPressStyle())
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
                .font(VellumFont.text(17, .semibold))
                .foregroundStyle(VellumPalette.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background(VellumPalette.ink, in: Capsule())
        }
        .buttonStyle(VellumPressStyle())
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            Text(session.isLocked ? "Unlock" : "Lock screen")
                .font(VellumFont.text(15, .regular))
                .foregroundStyle(VellumPalette.dust)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(VellumPressStyle())
    }
}
