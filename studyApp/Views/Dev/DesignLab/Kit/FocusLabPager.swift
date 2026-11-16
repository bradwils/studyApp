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

    var axis: Axis = .horizontal
    var showsFocusPage: Bool = true
    var isLocked: Bool = false

    @ViewBuilder var tracking: Tracking
    @ViewBuilder var focus: Focus

    var body: some View {
        ScrollView(axis == .horizontal ? .horizontal : .vertical) {
            if axis == .horizontal {
                HStack(spacing: 0) { pages }
                    .scrollTargetLayout()
            } else {
                VStack(spacing: 0) { pages }
                    .scrollTargetLayout()
            }
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

    @ViewBuilder
    private var pages: some View {
        tracking
            .containerRelativeFrame([.horizontal, .vertical])
            .id(0)

        if showsFocusPage {
            focus
                .containerRelativeFrame([.horizontal, .vertical])
                .id(1)
        }
    }

    // Measured against the scrollable range rather than the page size, so safe-area
    // insets on a vertical pager can't push the fraction past 1.
    private func travelFraction(_ geometry: ScrollGeometry) -> CGFloat {
        let insets = geometry.contentInsets
        let travelled: CGFloat
        let range: CGFloat
        if axis == .horizontal {
            travelled = geometry.contentOffset.x + insets.leading
            range = geometry.contentSize.width + insets.leading + insets.trailing - geometry.containerSize.width
        } else {
            travelled = geometry.contentOffset.y + insets.top
            range = geometry.contentSize.height + insets.top + insets.bottom - geometry.containerSize.height
        }
        guard range > 1 else { return 0 }
        return min(max(travelled / range, 0), 1)
    }
}
