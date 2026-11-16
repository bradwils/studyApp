//  WordsFocusPage.swift
//  studyApp
//
//  DEV ONLY — Words' focus page. Transparent; the sentence and hairline slots stay empty.

import SwiftUI

struct WordsFocusPage: View {

    let session: FocusLabSession
    let blend: CGFloat

    var body: some View {
        let fade: Double = Double(FocusLabMath.window(blend, 0.5, 1))
        VStack(alignment: .leading, spacing: 0) {
            Text(session.selectedSubject.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WordsPalette.dustgreen)
                .frame(height: WordsLayout.headerHeight, alignment: .leading)
            Color.clear.frame(height: WordsLayout.sentenceSlot)
            VStack(alignment: .leading, spacing: 0) {
                if !session.hasFocusBlock {
                    lengthRow
                }
                buttons
                    .padding(.top, 20)
            }
            .opacity(fade)
            .allowsHitTesting(blend > 0.5)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, WordsLayout.side)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Length

    private var lengthRow: some View {
        HStack(spacing: 0) {
            Text("Length")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(WordsPalette.dustgreen)
                .frame(width: WordsLayout.labelWidth, alignment: .leading)
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
        .padding(.top, 20)
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let tint: Color = isSelected ? WordsPalette.lemon : WordsPalette.dustgreen
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(Int(preset / 60))")
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(tint)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(WordsPressStyle())
    }

    // MARK: - Buttons

    private var buttons: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let complete: Bool = session.isFocusComplete(at: context.date)
            HStack(spacing: 20) {
                primaryButton(complete: complete)
                lockButton
            }
        }
    }

    private func primaryButton(complete: Bool) -> some View {
        let title: String = primaryTitle(complete: complete)
        return Button {
            withAnimation(.smooth(duration: 0.5)) {
                if session.hasFocusBlock {
                    session.clearFocusBlock()
                } else {
                    session.startFocusBlock()
                }
            }
        } label: {
            WordsPrimaryLabel(title: title)
        }
        .buttonStyle(WordsPressStyle())
    }

    private func primaryTitle(complete: Bool) -> String {
        if !session.hasFocusBlock { return "Start focus block" }
        return complete ? "Finish" : "End block"
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            WordsSecondaryLabel(title: session.isLocked ? "Unlock" : "Lock screen")
        }
        .buttonStyle(WordsPressStyle())
    }
}
