//  StillDesign.swift
//  studyApp
//
//  DEV ONLY — "Still": system background, system text, one accent. The screen's edge is
//  the focus progress bar, the timer drifts to the middle on the focus page, and a break
//  replaces the whole screen with amber.

import SwiftUI

struct StillDesign: View {

    let session: FocusLabSession

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    private var spruce: Color {
        StillPalette.spruce(colorScheme)
    }

    private var chromeScheme: ColorScheme? {
        session.isPaused ? ColorScheme.light : nil
    }

    var body: some View {
        FocusLabStage { _ in
            StillBackdrop(session: session, blend: blend, spruce: spruce, animates: !reduceMotion)
        } content: { metrics in
            stageContent(metrics.safeSize)
        }
        .focusLabChrome(chromeScheme)
    }

    private func stageContent(_ size: CGSize) -> some View {
        ZStack {
            pager(size)
            StillPinnedTimer(session: session, size: size, blend: blend)
                .allowsHitTesting(false)
            if session.isPaused {
                StillBreakScreen(session: session)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }

    private func pager(_ size: CGSize) -> some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked || session.isPaused
        ) {
            StillTrackingPage(session: session, height: size.height, blend: blend, spruce: spruce)
        } focus: {
            StillFocusPage(session: session, height: size.height, blend: blend, spruce: spruce)
        }
    }
}

private struct StillPinnedTimer: View {

    let session: FocusLabSession
    let size: CGSize
    let blend: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 76

    var body: some View {
        let ease: CGFloat = FocusLabMath.smoothstep(blend)
        let centerY: CGFloat = FocusLabMath.lerp(
            StillLayout.trackingTimerY(size.height),
            StillLayout.focusTimerY(size.height),
            ease
        )
        let scale: CGFloat = FocusLabMath.lerp(1, 1.22, ease)
        let width: CGFloat = max(size.width - 64, 0)
        let visible: Double = session.isPaused ? 0 : 1
        return FocusLabClock(session: session, idleText: "0:00")
            .font(.system(size: timerSize, weight: .bold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: width)
            .scaleEffect(scale)
            .position(x: size.width / 2, y: centerY)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(visible)
    }
}

#Preview {
    StillDesign(session: FocusLabSession())
}
