//  PrimaryTimerText.swift
//  studyApp

import SwiftUI

// Hero timer digits. Caller feeds a formatted string (e.g. from a TimelineView
// tick) plus a spoken label like "Elapsed time 1 hour 22 minutes" — the raw
// digit string reads poorly in VoiceOver.
struct PrimaryTimerText: View {

    var text: String
    var accessibilityLabel: String

    @ScaledMetric private var size: CGFloat

    init(_ text: String, accessibilityLabel: String, baseSize: CGFloat = 64) {
        self.text = text
        self.accessibilityLabel = accessibilityLabel
        _size = ScaledMetric(wrappedValue: baseSize, relativeTo: .largeTitle)
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.linear, value: text)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        VStack(spacing: DS.Space.xl) {
            PrimaryTimerText("01:22:47", accessibilityLabel: "Elapsed time 1 hour, 22 minutes")
            PrimaryTimerText("25:00", accessibilityLabel: "25 minutes remaining", baseSize: 40)
        }
    }
}
