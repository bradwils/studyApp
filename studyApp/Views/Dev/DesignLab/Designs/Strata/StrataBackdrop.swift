//  StrataBackdrop.swift
//  studyApp
//
//  DEV ONLY — Strata's fixed layer: the stack of bands and their labels.

import SwiftUI

struct StrataBackdrop: View {

    let session: FocusLabSession
    let blend: CGFloat
    let metrics: FocusLabStageMetrics

    var body: some View {
        let full: CGSize = metrics.fullSize
        ZStack(alignment: .topLeading) {
            stack(full: full)
        }
        .frame(width: full.width, height: full.height, alignment: .topLeading)
    }

    private func stack(full: CGSize) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now: Date = context.date
            let rawProgress: Double = session.focusProgress(at: now) ?? 0
            let bands: [StrataBand] = StrataBandLayout.bands(
                segments: session.segments,
                startedAt: session.startedAt,
                now: now,
                fullHeight: full.height,
                blend: blend,
                progress: CGFloat(rawProgress)
            )
            let tintOpacity: Double = Double(blend) * 0.16
            let labelOpacity: Double = Double(1 - FocusLabMath.window(blend, 0, 0.4))
            ZStack(alignment: .topLeading) {
                StrataStackCanvas(bands: bands, tintOpacity: tintOpacity)
                StrataBandLabels(bands: bands, width: full.width, opacity: labelOpacity)
            }
        }
    }
}

private struct StrataStackCanvas: View {

    let bands: [StrataBand]
    let tintOpacity: Double

    private var tint: Color {
        let base: Color = bands.last?.color ?? StrataPalette.moss
        return base.opacity(tintOpacity)
    }

    // Everything the renderer needs is copied into locals first, so the closure touches no
    // main-actor state even if Canvas runs it off the main thread.
    var body: some View {
        let haze: Color = StrataPalette.haze
        let ground: Color = StrataPalette.moss
        let tint: Color = self.tint
        let bands: [StrataBand] = self.bands
        return Canvas { context, size in
            let whole = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            context.fill(Path(whole), with: .color(haze))
            context.fill(Path(whole), with: .color(tint))
            for band in bands {
                let top: CGFloat = band.top.rounded()
                let bottom: CGFloat = band.bottom.rounded()
                guard bottom > top else { continue }
                let rect = CGRect(x: 0, y: top, width: size.width, height: bottom - top)
                context.fill(Path(rect), with: .color(band.color))
            }
            if bands.isEmpty {
                let sliver = CGRect(x: 0, y: size.height - 6, width: size.width, height: 6)
                context.fill(Path(sliver), with: .color(ground))
            }
        }
    }
}

private struct StrataBandLabels: View {

    let bands: [StrataBand]
    let width: CGFloat
    let opacity: Double

    private var labelled: [StrataBand] {
        bands.filter { $0.isStudy && $0.bottom - $0.top >= 26 }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if opacity > 0.001 {
                ForEach(labelled) { band in
                    label(for: band)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func label(for band: StrataBand) -> some View {
        let centerX: CGFloat = width - StrataLayout.contentX - 40
        let centerY: CGFloat = (band.top + band.bottom) / 2
        return Text("\(band.minutes) min")
            .font(StrataFont.sans(13, .medium))
            .foregroundStyle(band.labelColor)
            .lineLimit(1)
            .frame(width: 80, alignment: .trailing)
            .opacity(opacity)
            .position(x: centerX, y: centerY)
    }
}
