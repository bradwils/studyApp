//  DeckBackdrop.swift
//  studyApp
//
//  DEV ONLY — Deck's full-bleed backdrop: flat rosewater with the timer panel's fill,
//  which grows past the safe area until it covers the screen on the focus page.

import SwiftUI

struct DeckBackdrop: View {

    let session: FocusLabSession
    let layout: DeckLayout

    var body: some View {
        ZStack {
            Rectangle()
                .fill(DeckPalette.rosewater)
            panel
        }
    }

    private var panelFill: Color {
        let base: Color = session.isPaused ? DeckPalette.butter : DeckPalette.petal
        return base.labBlend(DeckPalette.wine, layout.blend)
    }

    private var panel: some View {
        let rect: CGRect = layout.backdropPanel
        let fill: Color = panelFill
        return RoundedRectangle(cornerRadius: layout.shownRadius, style: .continuous)
            .fill(fill)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .animation(.smooth(duration: 0.5), value: session.isPaused)
    }
}
