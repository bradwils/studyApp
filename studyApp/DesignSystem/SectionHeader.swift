//  SectionHeader.swift
//  studyApp

import SwiftUI

// Margin-free: callers own outer padding so the header composes anywhere.
struct SectionHeader: View {

    var title: String
    var count: Int? = nil
    var tint: Color = DS.Color.active

    var body: some View {
        HStack(spacing: DS.Space.s) {
            Text(title)
                .font(.title3.weight(.semibold))
            if let count {
                // Tinted wash instead of white-on-color so the pill stays
                // readable for every status color in both color schemes.
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .padding(.horizontal, DS.Space.s)
                    .padding(.vertical, DS.Space.xs)
                    .background(tint.opacity(0.15), in: .capsule)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        VStack(spacing: DS.Space.xl) {
            SectionHeader(title: "Active now", count: 3)
            SectionHeader(title: "On break", count: 1, tint: DS.Color.paused)
            SectionHeader(title: "Offline", count: 5, tint: DS.Color.offline)
            SectionHeader(title: "No pill")
        }
        .padding(DS.Space.xl)
    }
}
