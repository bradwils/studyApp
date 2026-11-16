//  TicketFocusPage.swift
//  studyApp
//
//  DEV ONLY — Ticket's focus page. Transparent: the big ticket is in the fixed layers; this
//  page puts the subject code, the tap-back area and the stub controls on top of it.

import SwiftUI

struct TicketFocusPage: View {

    let session: FocusLabSession
    let layout: TicketLayout
    let blend: CGFloat
    @Binding var page: Int?

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: TicketLayout.focusTop)
            faceArea
                .frame(height: layout.focusPerforationY)
            stubArea
                .frame(height: TicketLayout.focusStubHeight)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, TicketLayout.focusSideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Face

    private var faceArea: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { leaveZenMode() }
            Text(session.selectedSubject.code)
                .font(TicketFont.bold(17))
                .foregroundStyle(TicketPalette.navy)
                .padding(.top, 20)
                .allowsHitTesting(false)
        }
    }

    private func leaveZenMode() {
        guard !session.isLocked else { return }
        withAnimation(.smooth(duration: 0.6)) { page = 0 }
    }

    // MARK: - Stub

    private var stubArea: some View {
        let reveal: Double = Double(FocusLabMath.window(blend, 0.55, 1))
        return VStack(spacing: 12) {
            if !session.hasFocusBlock {
                presetRow
            }
            primaryButton
            lockButton
        }
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .opacity(reveal)
    }

    private var presetRow: some View {
        HStack(spacing: 8) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let minutes: Int = Int(preset / 60)
        let numberColor: Color = isSelected ? TicketPalette.navy : TicketPalette.mauve
        let dotColor: Color = isSelected ? TicketPalette.cherry : Color.clear
        return Button {
            session.focusDuration = preset
        } label: {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(TicketFont.medium(17))
                    .foregroundStyle(numberColor)
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(TicketPressStyle())
        .accessibilityLabel("\(minutes) minutes")
    }

    @ViewBuilder
    private var primaryButton: some View {
        if session.hasFocusBlock {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                blockButton(isComplete: session.isFocusComplete(at: context.date))
            }
        } else {
            TicketPrimaryButton(title: "Start focus block") {
                withAnimation(.smooth(duration: 0.35)) { session.startFocusBlock() }
            }
        }
    }

    private func blockButton(isComplete: Bool) -> some View {
        let title: String = isComplete ? "Finish" : "End block"
        return TicketPrimaryButton(title: title) {
            withAnimation(.smooth(duration: 0.35)) { session.clearFocusBlock() }
        }
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            Text(session.isLocked ? "Unlock" : "Lock screen")
                .font(TicketFont.medium(14))
                .foregroundStyle(TicketPalette.mauve)
                .frame(minWidth: 120, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(TicketPressStyle())
    }
}
