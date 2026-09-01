//  StatusChip.swift
//  studyApp

import SwiftUI

struct iconAndTextPill: View {

    enum Variant {
        case glass   // functional layer: floats above content
        case quiet   // content layer: sits inside cards/scrolling content
    }

    var text: String
    var systemImage: String
    var tint: Color = DS.Color.active
    var variant: Variant = .quiet

    var body: some View {
        switch variant {
        case .glass:
            label.glassEffect()
        case .quiet:
            label.background(.thinMaterial, in: .capsule)
        }
    }

    private var label: some View {
        Label {
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, DS.Space.m)
        .padding(.vertical, DS.Space.s)
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        VStack(spacing: DS.Space.l) {
            iconAndTextPill(text: "3 friends studying", systemImage: "person.2.fill", variant: .glass)
            iconAndTextPill(text: "On break", systemImage: "pause.circle.fill", tint: DS.Color.paused)
            iconAndTextPill(text: "Offline", systemImage: "moon.zzz.fill", tint: DS.Color.offline)
        }
    }
}
