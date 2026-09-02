//  DS.swift
//  studyApp

import SwiftUI

enum DS {

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24

        static let cardH: CGFloat = 16
        static let cardV: CGFloat = 14
    }

    enum Radius {
        static let control: CGFloat = 12
        static let card: CGFloat = 16
        static let sheet: CGFloat = 20
    }

    enum Color {
        static let active: SwiftUI.Color = .green
        static let paused: SwiftUI.Color = .orange
        static let offline: SwiftUI.Color = .secondary
        static let streak: SwiftUI.Color = .orange
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Space.l) {
        HStack(spacing: DS.Space.m) {
            swatch(DS.Color.active, "active")
            swatch(DS.Color.paused, "paused")
            swatch(DS.Color.offline, "offline")
            swatch(DS.Color.streak, "streak")
        }
        RoundedRectangle(cornerRadius: DS.Radius.control)
            .fill(.indigo.opacity(0.2))
            .frame(height: 44)
            .overlay { Text("control radius").font(.caption) }
        RoundedRectangle(cornerRadius: DS.Radius.card)
            .fill(.indigo.opacity(0.2))
            .frame(height: 60)
            .overlay { Text("card radius").font(.caption) }
        RoundedRectangle(cornerRadius: DS.Radius.sheet)
            .fill(.indigo.opacity(0.2))
            .frame(height: 80)
            .overlay { Text("sheet radius").font(.caption) }
    }
    .padding(DS.Space.xl)
}

private func swatch(_ color: Color, _ name: String) -> some View {
    VStack(spacing: DS.Space.xs) {
        Circle().fill(color).frame(width: 28, height: 28)
        Text(name).font(.caption2)
    }
}
