//  ScreenBackground.swift
//  studyApp

import SwiftUI

// The single ambient background for every screen — calm enough that glass
// chrome has something to refract without competing with content.
struct ScreenBackground: View {

    @Environment(\.colorScheme) private var colorScheme

    // Dark mode needs a stronger wash to register against the darker base.
    private var washOpacity: Double { colorScheme == .dark ? 0.18 : 0.12 }

    var body: some View {
        ZStack {
            Color(.systemBackground)
            LinearGradient(
                colors: [.indigo.opacity(washOpacity), .pink.opacity(washOpacity)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

#Preview("Light") {
    ScreenBackground()
}

#Preview("Dark") {
    ScreenBackground()
        .preferredColorScheme(.dark)
}
