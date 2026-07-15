//  FocusIntensitySlider.swift
//  studyApp
//
//  A custom slider component for focus intensity.

import SwiftUI

private let commitThreshold: Double = 0.9 // fraction of `range` the knob must pass to commit

struct FocusIntensitySlider: View {

    @Binding var sliderProgress: Double // current knob value, in `range`
    var range: ClosedRange<Double> // allowed span of sliderProgress
    @Binding var complete: Bool // set true on release once past commitThreshold

    @Binding var sliderDraggableElementWidth: CGFloat // knob (and end-cap) width
    @Binding var sliderDraggableElementHeight: CGFloat // knob (and end-cap) height

    // Latches the knob's leading edge at the start of a drag so motion is
    // relative to where the knob already was, not where the finger landed.
    @GestureState private var knobLeftEdgeAtDragStart: CGFloat?

    private var knobRadius: CGFloat { sliderDraggableElementWidth / 2 }

    // sliderProgress mapped from `range` to 0...1
    private var normalizedProgress: Double {
        guard range.upperBound != range.lowerBound else { return 0 }
        return (sliderProgress - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            dottedLineFiller

            GeometryReader { geo in
                let trackWidth = trackWidth(forTotalWidth: geo.size.width)
                let knobLeftEdge = knobLeftEdge(trackWidth: trackWidth)

                ZStack(alignment: .leading) {
                    endCapsule(trackWidth: trackWidth)
                    fillTrailCapsule(knobLeftEdge: knobLeftEdge)
                    knobCapsule(trackWidth: trackWidth, knobLeftEdge: knobLeftEdge)
                }
                .frame(height: sliderDraggableElementHeight)
            }
        }
        .frame(height: sliderDraggableElementHeight)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.2))
        )
    }


    // MARK: - Layers

    private func endCapsule(trackWidth: CGFloat) -> some View {
        // Dashed-outline end-cap marking the commit point.
        Capsule()
            .glassEffect()
            .frame(width: sliderDraggableElementWidth, height: sliderDraggableElementHeight)
            .overlay {
                Capsule()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7, 10]))
            }
            .offset(x: trackWidth)
            .opacity(0.4)
            .foregroundColor(.secondary)
    }

    private func fillTrailCapsule(knobLeftEdge: CGFloat) -> some View {
        // Gradient trail that fills in behind the knob as it moves.
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white.opacity(1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: knobLeftEdge + sliderDraggableElementWidth, height: sliderDraggableElementHeight)
    }

    private func knobCapsule(trackWidth: CGFloat, knobLeftEdge: CGFloat) -> some View {
        Capsule()
            .frame(width: sliderDraggableElementWidth, height: sliderDraggableElementHeight)
            .glassEffect(.regular.interactive())
            .offset(x: knobLeftEdge)
            .gesture(dragGesture(trackWidth: trackWidth, knobLeftEdge: knobLeftEdge))
    }

    // MARK: - Geometry & drag math

    private func trackWidth(forTotalWidth totalWidth: CGFloat) -> CGFloat {
        // Track excludes the knob's own width so the thumb stays fully inside the slider bounds.
        max(totalWidth - sliderDraggableElementWidth, 0)
    }

    private func knobLeftEdge(trackWidth: CGFloat) -> CGFloat {
        let clampedProgress = min(max(normalizedProgress, 0), 1)
        return clampedProgress * trackWidth
    }

    private func progress(forKnobLeftEdge leftEdge: CGFloat, trackWidth: CGFloat) -> Double {
        let clampedEdge = min(max(leftEdge, 0), trackWidth)
        let fraction = trackWidth > 0 ? clampedEdge / trackWidth : 0
        return range.lowerBound + Double(fraction) * (range.upperBound - range.lowerBound)
    }

    private func dragGesture(trackWidth: CGFloat, knobLeftEdge: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($knobLeftEdgeAtDragStart) { _, state, _ in
                state = state ?? knobLeftEdge
            }
            .onChanged { value in
                let startEdge = knobLeftEdgeAtDragStart ?? knobLeftEdge
                let desiredLeftEdge = startEdge + value.translation.width
                let newProgress = progress(forKnobLeftEdge: desiredLeftEdge, trackWidth: trackWidth)
                sliderProgress = min(max(newProgress, range.lowerBound), range.upperBound)
            }
            .onEnded { _ in
                if normalizedProgress > commitThreshold {
                    complete = true
                } else {
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0)) {
                        sliderProgress = 0
                    }
                }
            }
    }
}

private var dottedLineFiller: some View {
    GeometryReader { geometry in
        Path { path in
            let width = geometry.size.width
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        .stroke(
            Color.black.opacity(0.35),
            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 10])
        )
    }
    .frame(height: 1)
}

#Preview {
    FocusIntensitySlider(
        sliderProgress: .constant(50),
        range: 0...100,
        complete: .constant(false),
        sliderDraggableElementWidth: .constant(90),
        sliderDraggableElementHeight: .constant(60)
    )
    .padding()
}
