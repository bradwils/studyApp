//  WordsDesign.swift
//  studyApp
//
//  DEV ONLY — "Words": no digits. The time is a sentence set in a book face on a chalkboard
//  field, re-worded once a minute; the focus page rewrites the same sentence in place.

import SwiftUI

struct WordsDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { _ in
            backdrop
        } content: { _ in
            ZStack {
                pager
                WordsPinned(session: session, blend: blend, animates: !reduceMotion)
            }
        }
    }

    private var backdrop: some View {
        let field: Color = session.isPaused
            ? WordsPalette.aubergine
            : WordsPalette.board.labBlend(WordsPalette.deepboard, blend)
        return Rectangle()
            .fill(field)
            .animation(.smooth(duration: 0.6), value: session.isPaused)
    }

    private var pager: some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            WordsTrackingPage(session: session, blend: blend)
        } focus: {
            WordsFocusPage(session: session, blend: blend)
        }
    }
}

#Preview {
    WordsDesign(session: FocusLabSession())
}
