//  TapeDesign.swift
//  studyApp
//
//  DEV ONLY — "Tape": time as a measuring tape. A white tape slides under a fixed needle,
//  study time inked on it; swiping up zooms it out until the whole focus block fits.
//  The only design that pages vertically.

import SwiftUI

struct TapeDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 76

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { metrics in
            TapeBackdrop(
                session: session,
                metrics: metrics,
                blend: blend,
                reduceMotion: reduceMotion,
                timerSize: timerSize
            )
        } content: { metrics in
            pager(metrics)
        }
        .focusLabChrome(blend < 0.5 ? .light : .dark)
    }

    private func pager(_ metrics: FocusLabStageMetrics) -> some View {
        let bandTop: CGFloat = TapeLayout.bandTop(height: metrics.safeSize.height)
        return FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            axis: .vertical,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            TapeTrackingPage(session: session, bandTop: bandTop)
        } focus: {
            TapeFocusPage(session: session, bandTop: bandTop)
        }
    }
}

#Preview {
    TapeDesign(session: FocusLabSession())
}
