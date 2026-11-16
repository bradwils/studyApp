//  LampDesign.swift
//  studyApp
//
//  DEV ONLY — "Lamp": a dark desk at night. A pool of lamplight is wide on the tracking
//  page and closes in on the timer on the focus page; a fuse line burns down the block.

import SwiftUI

struct LampDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 86
    @ScaledMetric(relativeTo: .largeTitle) private var timerSlotHeight: CGFloat = 116

    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        FocusLabStage { metrics in
            backdrop(metrics)
        } content: { _ in
            pager
        }
    }

    // MARK: - Pager

    private var pager: some View {
        FocusLabPager(
            pageOffset: $pageOffset,
            page: $page,
            showsFocusPage: session.hasSession,
            isLocked: session.isLocked
        ) {
            LampTrackingPage(session: session, slotHeight: timerSlotHeight)
        } focus: {
            LampFocusPage(session: session, slotHeight: timerSlotHeight)
        }
    }

    // MARK: - Backdrop

    private func backdrop(_ metrics: FocusLabStageMetrics) -> some View {
        let full: CGSize = metrics.fullSize
        let timerTop: CGFloat = LampLayout.headerHeight + LampLayout.slotGap
        let timerCenterY: CGFloat = metrics.backdropY(timerTop + timerSlotHeight / 2)
        let fuseCenterY: CGFloat = metrics.backdropY(timerTop + timerSlotHeight + LampLayout.fuseGap + 1)
        let centerX: CGFloat = full.width / 2
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(LampPalette.night)
            LampPool(blend: blend, size: full, centerY: timerCenterY - 30, animates: !reduceMotion)
            LampTopGlow(blend: blend, size: full)
            timer
                .position(x: centerX, y: timerCenterY)
            LampFuse(session: session, blend: blend)
                .position(x: centerX, y: fuseCenterY)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private var timer: some View {
        let digitWidth: CGFloat = timerSize * 0.56
        return FocusLabClock(session: session, idleText: "0:00", digitWidth: digitWidth)
            .font(LampFont.timer(timerSize))
            .foregroundStyle(LampPalette.parchment)
    }
}

// MARK: - Light

private struct LampPool: View {

    let blend: CGFloat
    let size: CGSize
    let centerY: CGFloat
    let animates: Bool

    @State private var isBright = false

    var body: some View {
        let width: CGFloat = size.width
        let height: CGFloat = max(size.height, 1)
        let unitY: CGFloat = centerY / height
        let center: UnitPoint = UnitPoint(x: 0.5, y: unitY)
        let radius: CGFloat = FocusLabMath.lerp(width * 1.25, width * 0.46, blend)
        let breathing: Double = (animates && !isBright) ? 0.92 : 1.0
        return RadialGradient(
            stops: stops,
            center: center,
            startRadius: 0,
            endRadius: radius
        )
        .frame(width: width, height: height)
        .opacity(breathing)
        .onAppear {
            guard animates else { return }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                isBright = true
            }
        }
    }

    private var stops: [Gradient.Stop] {
        let core: Color = LampPalette.lamplight.opacity(0.34)
        let mid: Color = LampPalette.lamplight.opacity(0.12)
        let edge: Color = LampPalette.lamplight.opacity(0)
        return [
            Gradient.Stop(color: core, location: 0),
            Gradient.Stop(color: mid, location: 0.45),
            Gradient.Stop(color: edge, location: 1)
        ]
    }
}

private struct LampTopGlow: View {

    let blend: CGFloat
    let size: CGSize

    var body: some View {
        let strength: Double = Double(1 - 0.6 * blend)
        let top: Color = LampPalette.lamplight.opacity(0.10)
        let clear: Color = LampPalette.lamplight.opacity(0)
        let stops: [Gradient.Stop] = [
            Gradient.Stop(color: top, location: 0),
            Gradient.Stop(color: clear, location: 0.3),
            Gradient.Stop(color: clear, location: 1)
        ]
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            .frame(width: size.width, height: size.height)
            .opacity(strength)
    }
}

private struct LampFuse: View {

    let session: FocusLabSession
    let blend: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            fuse(at: context.date)
        }
        .opacity(Double(blend))
        .accessibilityHidden(true)
    }

    private func fuse(at date: Date) -> some View {
        let progress: Double? = session.focusProgress(at: date)
        let remaining: CGFloat = CGFloat(1 - (progress ?? 0))
        let burn: CGFloat = LampLayout.fuseWidth * remaining
        let litOpacity: Double = progress == nil ? 0.35 : 1
        return ZStack {
            Capsule()
                .fill(LampPalette.parchment.opacity(0.12))
                .frame(width: LampLayout.fuseWidth, height: 2)
            Capsule()
                .fill(LampPalette.ember)
                .frame(width: burn, height: 2)
                .opacity(litOpacity)
                .animation(.linear(duration: 1), value: burn)
        }
        .frame(width: LampLayout.fuseWidth, height: 2)
    }
}

#Preview {
    LampDesign(session: FocusLabSession())
}
