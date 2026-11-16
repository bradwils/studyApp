//  FocusLabPager.swift
//  studyApp
//
//  DEV ONLY — the two-page pager every Focus Design Lab screen shares. Same mechanics
//  as FocusSessionScreen's pager: the pages scroll, and anything a design wants to stay
//  put (timer, background, a shared shape) is drawn outside it and driven by pageOffset.

import SwiftUI

struct FocusLabPager<Tracking: View, Focus: View>: View {

    /// 0 on the tracking page, 1 on the focus page, continuous while a drag is in flight.
    @Binding var pageOffset: CGFloat

    /// 0 = tracking, 1 = focus. Set it inside withAnimation to turn the page from a button.
    @Binding var page: Int?

    var showsFocusPage: Bool = true
    var isLocked: Bool = false

    @ViewBuilder var tracking: Tracking
    @ViewBuilder var focus: Focus

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) { pages }
                .scrollTargetLayout()
        }
        .scrollPosition(id: $page)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(isLocked)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            travelFraction(geometry)
        } action: { _, fraction in
            pageOffset = fraction
        }
        .onChange(of: showsFocusPage) { _, shows in
            if !shows { page = 0 }
        }
    }

    // Only the width is pinned to the container, exactly as FocusSessionScreen does it; the
    // height fills whatever the scroll view proposes, so a page is never taller than the
    // safe area the designs measure their fixed layers against.
    @ViewBuilder
    private var pages: some View {
        tracking
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerRelativeFrame(.horizontal)
            .id(0)

        if showsFocusPage {
            focus
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerRelativeFrame(.horizontal)
                .id(1)
        }
    }

    // Measured against the scrollable range rather than the page size, so the fraction
    // can't pass 1 whatever the insets.
    private func travelFraction(_ geometry: ScrollGeometry) -> CGFloat {
        let insets = geometry.contentInsets
        let travelled = geometry.contentOffset.x + insets.leading
        let range = geometry.contentSize.width + insets.leading + insets.trailing - geometry.containerSize.width
        guard range > 1 else { return 0 }
        return min(max(travelled / range, 0), 1)
    }
}
