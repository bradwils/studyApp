//  StillBackdrop.swift
//  studyApp
//
//  DEV ONLY — Still's backdrop: the system background with a line that traces the
//  screen's own edge as the focus block runs.

import SwiftUI

struct StillBackdrop: View {

    let session: FocusLabSession
    let blend: CGFloat
    let spruce: Color
    let animates: Bool

    var body: some View {
        ZStack {
            Rectangle().fill(.background)
            perimeter
                .opacity(Double(blend))
        }
    }

    private var perimeter: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let progress: Double = session.focusProgress(at: context.date) ?? 0
            StillPerimeter(progress: progress, spruce: spruce, animates: animates)
        }
    }
}

private struct StillPerimeter: View {

    let progress: Double
    let spruce: Color
    let animates: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 50, style: .continuous)
        let visible: Double = progress < 0.002 ? 0 : 1
        let animation: Animation? = animates ? Animation.linear(duration: 1) : nil
        return ZStack {
            shape
                .stroke(Color.primary.opacity(0.08), lineWidth: 4)
            shape
                .trim(from: 0, to: CGFloat(progress))
                .stroke(spruce, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .opacity(visible)
        }
        .padding(5)
        .animation(animation, value: progress)
    }
}
