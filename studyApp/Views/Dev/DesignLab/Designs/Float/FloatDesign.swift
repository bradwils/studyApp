//  FloatDesign.swift
//  studyApp
//
//  DEV ONLY — "Float": native Liquid Glass over a subject-coloured field. One glass sheet
//  holds the timer and draws itself in from a slab to a circle as you swipe to focus.

import SwiftUI

struct FloatDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    private var subjectIndex: Int {
        let index: Int = session.subjects.firstIndex(of: session.selectedSubject) ?? 0
        return index % 4
    }

    var body: some View {
        FocusLabStage { _ in
            FloatBackdrop(subjectIndex: subjectIndex, blend: blend, reduceMotion: reduceMotion)
        } content: { metrics in
            ZStack {
                pager
                FloatPinned(session: session, blend: blend, width: metrics.safeSize.width)
            }
        }
        .focusLabChrome(blend < 0.5 ? .light : .dark)
    }

    private var pager: some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            FloatTrackingPage(session: session)
        } focus: {
            FloatFocusPage(session: session)
        }
    }
}

#Preview {
    FloatDesign(session: FocusLabSession())
}
