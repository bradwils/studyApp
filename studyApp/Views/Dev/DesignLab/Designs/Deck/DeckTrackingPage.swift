//  DeckTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Deck's tracking page: three independently placed pieces (music strip, timer
//  panel contents, leaderboard sheet). The strip and the sheet leave vertically as the page
//  swipes away; the panel's own fill is drawn in the backdrop.

import SwiftUI

struct DeckTrackingPage: View {

    let session: FocusLabSession
    let layout: DeckLayout

    @State private var isSheetOpen = false

    private var sheetY: CGFloat {
        let lift: CGFloat = isSheetOpen ? DeckLayout.sheetOpenLift : 0
        return layout.sheetTop + layout.sheetOffset - lift
    }

    var body: some View {
        ZStack(alignment: .top) {
            DeckMusicStrip(layout: layout)
                .offset(y: layout.stripOffset)
            DeckTimerPanel(session: session, layout: layout)
                .padding(.top, layout.trackingPanel.minY)
                .allowsHitTesting(layout.blend < 0.45)
            DeckLeaderboardSheet(session: session, layout: layout, isOpen: $isSheetOpen)
                .offset(y: sheetY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
