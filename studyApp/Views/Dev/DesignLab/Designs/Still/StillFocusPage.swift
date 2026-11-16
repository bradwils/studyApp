//  StillFocusPage.swift
//  studyApp
//
//  DEV ONLY — Still's focus page. Transparent; the timer row is left empty.

import SwiftUI

struct StillFocusPage: View {

    let session: FocusLabSession
    let height: CGFloat
    let blend: CGFloat
    let spruce: Color

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 15
    @ScaledMetric(relativeTo: .body) private var numeralSize: CGFloat = 17

    var body: some View {
        VStack(spacing: 0) {
            Text(session.selectedSubject.code)
                .font(.system(size: textSize, weight: .semibold))
                .foregroundStyle(spruce)
                .frame(height: StillLayout.headerHeight)
            lowerContent
        }
        .padding(.horizontal, StillLayout.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var lowerContent: some View {
        let fade: Double = Double(FocusLabMath.window(blend, 0.5, 1))
        let gap: CGFloat = max(StillLayout.focusTimerY(height) - 75 - StillLayout.headerHeight, 0)
        return VStack(spacing: 0) {
            Color.clear.frame(height: gap)
            Color.clear.frame(height: StillLayout.focusRow)
            statusLine
            Spacer(minLength: 16)
            if !session.hasFocusBlock {
                presets
                    .padding(.bottom, 12)
            }
            primaryButton
            lockButton
        }
        .frame(maxWidth: .infinity)
        .opacity(fade)
        .allowsHitTesting(blend > 0.5)
    }

    // MARK: - Status and primary action

    private var blockMinutes: Int {
        guard let start = session.focusStart, let goal = session.focusGoal else {
            return Int(session.focusDuration / 60)
        }
        return Int((goal.timeIntervalSince(start) / 60).rounded())
    }

    private var statusLine: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(statusText(at: context.date))
                .font(.system(size: textSize))
                .foregroundStyle(.secondary)
        }
    }

    private func statusText(at date: Date) -> String {
        guard session.hasFocusBlock else { return "Set a length to start" }
        if session.isFocusComplete(at: date) { return "Block complete" }
        return "left of \(blockMinutes) minutes"
    }

    private var primaryButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let isComplete: Bool = session.isFocusComplete(at: context.date)
            StillCapsuleButton(title: primaryTitle(isComplete: isComplete), spruce: spruce) {
                withAnimation(.smooth(duration: 0.45)) { primaryAction() }
            }
        }
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

    // MARK: - Presets and lock

    private var presets: some View {
        HStack(spacing: 4) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: TimeInterval) -> some View {
        let isSelected: Bool = session.focusDuration == preset
        let textColor: Color = isSelected ? Color.primary : Color.secondary
        let fill: Color = isSelected ? spruce.opacity(0.14) : Color.clear
        let weight: Font.Weight = isSelected ? .semibold : .regular
        return Button {
            session.focusDuration = preset
        } label: {
            Text("\(Int(preset / 60))")
                .font(.system(size: numeralSize, weight: weight))
                .foregroundStyle(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(fill))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var lockButton: some View {
        Button {
            session.isLocked.toggle()
        } label: {
            Text(session.isLocked ? "Unlock" : "Lock screen")
                .font(.system(size: textSize))
                .foregroundStyle(.secondary)
                .frame(minWidth: 88, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 28)
    }
}
