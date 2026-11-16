//  LampFocusPage.swift
//  studyApp
//
//  DEV ONLY — Lamp's focus page. Transparent; the timer slot and fuse row are left empty.

import SwiftUI

struct LampFocusPage: View {

    let session: FocusLabSession
    let slotHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text(session.selectedSubject.code)
                .font(LampFont.bold(20))
                .foregroundStyle(LampPalette.parchment.opacity(0.8))
                .frame(height: 44)
                .frame(height: LampLayout.headerHeight, alignment: .top)
            Color.clear
                .frame(height: slotHeight)
                .padding(.top, LampLayout.slotGap)
            Color.clear
                .frame(height: LampLayout.fuseRowHeight)
            status
            controls
                .padding(.top, 28)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LampLayout.sidePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Status

    private var status: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(statusText(at: context.date))
                .font(LampFont.regular(15))
                .foregroundStyle(LampPalette.ash)
                .multilineTextAlignment(.center)
        }
    }

    private var blockMinutes: Int {
        guard let start = session.focusStart, let goal = session.focusGoal else { return 0 }
        return Int((goal.timeIntervalSince(start) / 60).rounded())
    }

    private func statusText(at date: Date) -> String {
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "Set a length and begin" }
        if session.isFocusComplete(at: date) { return "Block complete" }
        return "left of \(blockMinutes) minutes"
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 20) {
            if !session.hasFocusBlock {
                presets
            }
            primaryButton
            lockButton
        }
        .opacity(0.72)
    }

    private var presets: some View {
        HStack(spacing: 8) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let minutes: Int = Int(preset / 60)
        let isSelected: Bool = session.focusDuration == preset
        let tint: Color = isSelected ? LampPalette.ember : LampPalette.ash
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(minutes)")
                .font(LampFont.regular(20))
                .foregroundStyle(tint)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(LampPressStyle())
        .accessibilityLabel("\(minutes) minutes")
    }

    private var primaryButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let title: String = primaryTitle(at: context.date)
            Button {
                withAnimation(.smooth(duration: 0.35)) { toggleBlock() }
            } label: {
                LampPill(
                    title: title,
                    fill: LampPalette.umber,
                    textColor: LampPalette.parchment,
                    isOutlined: true
                )
            }
            .buttonStyle(LampPressStyle())
        }
    }

    private func primaryTitle(at date: Date) -> String {
        guard session.hasFocusBlock else { return "Start focus block" }
        return session.isFocusComplete(at: date) ? "Finish" : "End block"
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
                .font(LampFont.regular(16))
                .foregroundStyle(LampPalette.ash)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(LampPressStyle())
    }
}
