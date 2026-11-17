//  FocusPagerStage.swift
//  studyApp
//
//  Splits a focus screen into a full-bleed backdrop and safe-area content, and hands both
//  the numbers needed to line one up with the other.

import SwiftUI

struct FocusPagerStageMetrics: Equatable {

    /// Size of the safe area — the space the pager's pages are laid out in.
    let safeSize: CGSize
    let insets: EdgeInsets

    /// Size of the backdrop, which runs under the status bar and the bottom bar.
    var fullSize: CGSize {
        CGSize(
            width: safeSize.width + insets.leading + insets.trailing,
            height: safeSize.height + insets.top + insets.bottom
        )
    }

    // Capped and centred so a wide screen gets a column; the backdrop and the pager still span the full width.
    var contentRect: CGRect {
        let width = min(safeSize.width, FocusPagerLayout.maxContentWidth)
        return CGRect(x: (safeSize.width - width) / 2, y: 0, width: width, height: safeSize.height)
    }

    /// An x measured from the leading edge of a page, expressed in backdrop coordinates.
    func backdropX(_ pageX: CGFloat) -> CGFloat {
        pageX + insets.leading
    }

    func backdropRect(_ pageRect: CGRect) -> CGRect {
        pageRect.offsetBy(dx: insets.leading, dy: insets.top)
    }
}

struct FocusPagerStage<Backdrop: View, Content: View>: View {

    /// Drawn edge to edge behind everything. Never receives touches, so drags always reach the pager.
    @ViewBuilder var backdrop: (FocusPagerStageMetrics) -> Backdrop

    /// Laid out inside the safe area, on top of the backdrop.
    @ViewBuilder var content: (FocusPagerStageMetrics) -> Content

    var body: some View {
        GeometryReader { proxy in
            let metrics = FocusPagerStageMetrics(safeSize: proxy.size, insets: proxy.safeAreaInsets)
            ZStack {
                backdrop(metrics)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                content(metrics)
            }
        }
    }
}
