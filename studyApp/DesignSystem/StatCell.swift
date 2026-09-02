//  StatCell.swift
//  studyApp

import SwiftUI

struct StatCell: View {

    var systemImage: String
    var tint: Color
    var label: String
    var value: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .monospacedDigit()
        }
        .padding(.horizontal, DS.Space.m)
        .padding(.vertical, DS.Space.m)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        HStack(spacing: 0) {
            StatCell(systemImage: "timer", tint: .blue, label: "Session", value: "01:22", alignment: .leading)
            Divider().padding(.vertical, DS.Space.s)
            StatCell(systemImage: "book.fill", tint: .purple, label: "Subject", value: "Mathematics", alignment: .center)
            Divider().padding(.vertical, DS.Space.s)
            StatCell(systemImage: "clock.fill", tint: DS.Color.active, label: "Today", value: "03:41", alignment: .trailing)
        }
        .surfaceCard()
        .padding(DS.Space.xl)
    }
}
