//  AvatarBadge.swift
//  studyApp

import SwiftUI

// Hidden from accessibility: the adjacent name text carries the information.
struct AvatarBadge: View {

    var name: String
    var tint: Color

    @ScaledMetric private var diameter: CGFloat

    init(name: String, tint: Color = DS.Color.offline, size: CGFloat = 44) {
        self.name = name
        self.tint = tint
        _diameter = ScaledMetric(wrappedValue: size, relativeTo: .headline)
    }

    private var initial: String { String(name.prefix(1)).uppercased() }

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.14))
            Text(initial)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        HStack(spacing: DS.Space.l) {
            AvatarBadge(name: "Alice", tint: DS.Color.active)
            AvatarBadge(name: "Ben", tint: DS.Color.paused)
            AvatarBadge(name: "Cody")
            AvatarBadge(name: "Dana", tint: DS.Color.active, size: 32)
        }
    }
}
