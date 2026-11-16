//  PosterFocusPage.swift
//  studyApp
//
//  DEV ONLY — Poster's focus page. Transparent; the page leaves room for the giant numerals.

import SwiftUI

struct PosterFocusPage: View {

    let session: FocusLabSession
    let layout: PosterLayout
    let blend: CGFloat

    @ScaledMetric(relativeTo: .title) private var codeSize: CGFloat = 34
    @ScaledMetric(relativeTo: .title2) private var presetSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var captionSize: CGFloat = 15

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(session.selectedSubject.code)
                .font(PosterFont.heavy(codeSize))
                .foregroundStyle(PosterPalette.forest)
                .frame(height: PosterLayout.headerHeight, alignment: .leading)
            Color.clear
                .frame(height: layout.focusTop - PosterLayout.headerHeight + layout.bigSize)
            lowerContent
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PosterLayout.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var lowerContent: some View {
        let fade: Double = Double(FocusLabMath.window(blend, 0.5, 1))
        return TimelineView(.periodic(from: .now, by: 1)) { context in
            controls(complete: session.isFocusComplete(at: context.date))
        }
        .opacity(fade)
        .allowsHitTesting(blend > 0.5)
    }

    private func controls(complete: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(statusText(complete: complete))
                .font(PosterFont.label(captionSize))
                .foregroundStyle(PosterPalette.leaf)
                .padding(.top, 10)
            if !session.hasFocusBlock {
                presets
                    .padding(.top, 24)
            }
            buttons(complete: complete)
                .padding(.top, 24)
        }
    }

    private func statusText(complete: Bool) -> String {
        guard session.hasFocusBlock else { return "No block running" }
        if complete { return "Block complete" }
        if session.isPaused { return "On a break" }
        return "left of \(Int(session.focusDuration / 60)) minutes"
    }

    // MARK: - Presets

    private var presets: some View {
        HStack(spacing: 10) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        return Button {
            session.focusDuration = preset
        } label: {
            VStack(spacing: 4) {
                Text("\(Int(preset / 60))")
                    .font(PosterFont.heavy(presetSize))
                    .foregroundStyle(isSelected ? PosterPalette.forest : PosterPalette.leaf)
                Rectangle()
                    .fill(isSelected ? PosterPalette.tangerine : Color.clear)
                    .frame(width: 24, height: 4)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PosterPressStyle())
    }

    // MARK: - Buttons

    private func primaryTitle(complete: Bool) -> String {
        guard session.hasFocusBlock else { return "Start focus block" }
        return complete ? "Finish" : "End block"
    }

    private func buttons(complete: Bool) -> some View {
        HStack(spacing: 20) {
            PosterPrimaryButton(title: primaryTitle(complete: complete)) {
                withAnimation(.smooth(duration: 0.35)) { primaryAction() }
            }
            PosterLinkButton(title: session.isLocked ? "Unlock" : "Lock screen") {
                session.isLocked.toggle()
            }
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
