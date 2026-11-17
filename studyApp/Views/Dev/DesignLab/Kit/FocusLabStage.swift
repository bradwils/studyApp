//  FocusLabStage.swift
//  studyApp
//
//  DEV ONLY — splits a Focus Design Lab screen into a full-bleed backdrop and
//  safe-area content, and hands both the numbers needed to line one up with the other.

import SwiftUI

struct FocusLabStageMetrics: Equatable {

    /// Size of the safe area — the space the pager's pages are laid out in.
    let safeSize: CGSize
    let insets: EdgeInsets

    /// Size of the backdrop, which runs under the status bar and the lab bar.
    var fullSize: CGSize {
        CGSize(
            width: safeSize.width + insets.leading + insets.trailing,
            height: safeSize.height + insets.top + insets.bottom
        )
    }

    /// An x measured from the leading edge of a page, expressed in backdrop coordinates.
    func backdropX(_ pageX: CGFloat) -> CGFloat {
        pageX + insets.leading
    }
}

struct FocusLabStage<Backdrop: View, Content: View>: View {

    /// Drawn edge to edge behind everything. Never receives touches, so drags always reach the pager.
    @ViewBuilder var backdrop: (FocusLabStageMetrics) -> Backdrop

    /// Laid out inside the safe area, on top of the backdrop.
    @ViewBuilder var content: (FocusLabStageMetrics) -> Content

    var body: some View {
        GeometryReader { proxy in
            let metrics = FocusLabStageMetrics(safeSize: proxy.size, insets: proxy.safeAreaInsets)
            ZStack {
                backdrop(metrics)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                content(metrics)
            }
        }
    }
}
