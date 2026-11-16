//  MarginFocusPage.swift
//  studyApp
//
//  DEV ONLY — Margin's focus page. Transparent; it sits on the ink panel, so text is Paper and Slate.

import SwiftUI

struct MarginFocusPage: View {

    let session: FocusLabSession
    let slotHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .frame(height: MarginLayout.headerHeight, alignment: .topLeading)
            Color.clear
                .frame(height: slotHeight)
                .padding(.top, 24)
            lower
            Spacer(minLength: 0)
        }
        .padding(.top, MarginLayout.topInset)
        .padding(.leading, MarginLayout.contentX)
        .padding(.trailing, MarginLayout.trailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(session.selectedSubject.code)
                .font(MarginFont.serif(24, .medium))
                .foregroundStyle(MarginPalette.paper)
                .frame(minHeight: 44, alignment: .leading)
            Text(session.selectedSubject.name)
                .font(MarginFont.sans(13, .regular))
                .foregroundStyle(MarginPalette.slate)
        }
    }

    // MARK: - Below the timer

    private var lower: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let complete: Bool = session.isFocusComplete(at: context.date)
            VStack(alignment: .leading, spacing: 0) {
                caption(complete: complete)
                    .padding(.top, 10)
                if !session.hasFocusBlock {
                    lengthRow
                        .padding(.top, 32)
                }
                buttons(complete: complete)
                    .padding(.top, 36)
            }
        }
    }

    private func caption(complete: Bool) -> some View {
        Text(captionText(complete: complete))
            .font(MarginFont.sans(13, .regular))
            .foregroundStyle(MarginPalette.slate)
    }

    private func captionText(complete: Bool) -> String {
        if session.isPaused { return "On a break" }
        guard session.hasFocusBlock else { return "No focus block running" }
        if complete { return "Block complete" }
        let minutes: Int = Int(session.focusDuration / 60)
        return "left of \(minutes) minutes"
    }

    // MARK: - Length

    private var lengthRow: some View {
        HStack(spacing: 0) {
            Text("Length")
                .font(MarginFont.sans(15, .regular))
                .foregroundStyle(MarginPalette.slate)
                .frame(width: MarginLayout.labelWidth, alignment: .leading)
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let minutes: Int = Int(preset / 60)
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(minutes)")
                .font(MarginFont.sans(17, isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? MarginPalette.paper : MarginPalette.slate)
                .frame(minWidth: 44, minHeight: 44)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(MarginPalette.highlighter)
                            .frame(width: 22, height: 3)
                            .padding(.bottom, 8)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(MarginPressStyle())
    }

    // MARK: - Buttons

    private func primaryTitle(complete: Bool) -> String {
        if complete { return "Finish" }
        return session.hasFocusBlock ? "End block" : "Start focus block"
    }

    private func buttons(complete: Bool) -> some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.smooth(duration: 0.35)) { primaryAction() }
            } label: {
                Text(primaryTitle(complete: complete))
                    .font(MarginFont.sans(16, .medium))
                    .foregroundStyle(MarginPalette.ink)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .frame(minHeight: 46)
                    .background(MarginPalette.paper, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(MarginPressStyle())

            Button {
                session.isLocked.toggle()
            } label: {
                Text(session.isLocked ? "Unlock" : "Lock screen")
                    .font(MarginFont.sans(16, .regular))
                    .underline()
                    .foregroundStyle(MarginPalette.paper)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MarginPressStyle())
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
