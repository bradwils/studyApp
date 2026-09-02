//  SurfaceCard.swift
//  studyApp

import SwiftUI

// Content-layer card. Solid material, never glass — glass is reserved for the
// functional layer (tab bar, toolbars, floating controls) per the two-layer rule.
extension View {
    func surfaceCard() -> some View {
        self
            .padding(.horizontal, DS.Space.cardH)
            .padding(.vertical, DS.Space.cardV)
            .background(.thinMaterial, in: .rect(cornerRadius: DS.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
            }
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        VStack(spacing: DS.Space.m) {
            HStack {
                Text("Mathematics")
                    .font(.headline)
                Spacer()
                Text("01:22:47")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .surfaceCard()

            Text("A card grows to fit its content.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .surfaceCard()
        }
        .padding(DS.Space.xl)
    }
}
