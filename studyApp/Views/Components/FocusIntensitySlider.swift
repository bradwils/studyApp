//  FocusIntensitySlider.swift
//  studyApp
//
//  A custom slider component for focus intensity.

import SwiftUI

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

struct FocusIntensitySlider: View {
    
    @Namespace private var namespace

    @State private var navigateToPureFocus = false
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    
    @Binding var sliderDraggableElementWidth: CGFloat
    @Binding var sliderDraggableElementHeight: CGFloat
    
    var sliderDraggableElementRadius: CGFloat { sliderDraggableElementWidth / 2 }
    @State private var dragStartTouchOffset: CGFloat?
    let focusSliderFontSize: CGFloat = 20
    @State var trackWidth: CGFloat = 0 // Keep track width available for other logic that depends on the slider bounds

    // Track whether the knob is pressed so the capsule can animate a pop (scale/shadow) while dragging.
    @GestureState private var isSliderElementPressed = false
    // Capture the live translation for a subtle offset that makes the knob feel draggable.
    @GestureState private var knobDragTranslation = CGSize.zero

    private var normalizedProgress: Double {
        guard range.upperBound != range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            dottedLineFiller
            
            GeometryReader { geo in
                // Track width excludes the knob width so the thumb stays inside the slider bounds.
                let currentTrackWidth = max(geo.size.width - sliderDraggableElementWidth, 0)
                let clampedProgress = min(max(normalizedProgress, 0), 1)
                // Knob offset matches the normalized progress along the available track width.
                let knobOffset = clampedProgress * currentTrackWidth
                let knobTotalOffset = CGFloat(min(max(knobOffset, 0), currentTrackWidth))
                let dragGesture = DragGesture(minimumDistance: 0)
                    .updating($isSliderElementPressed) { _, state, _ in
                        state = true
                    }
                    .updating($knobDragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { gesture in
                        let knobCenter = knobOffset + sliderDraggableElementRadius
                        let startOffset: CGFloat = dragStartTouchOffset ?? (gesture.startLocation.x - knobCenter)
                        if dragStartTouchOffset == nil {
                            dragStartTouchOffset = startOffset
                        }
                        let desiredCenter = gesture.location.x - startOffset
                        let leftEdge = desiredCenter - sliderDraggableElementRadius
                        let xPosition = min(max(0, leftEdge), currentTrackWidth)
                        // Convert the thumb position into normalized progress along the track.
                        let progress = currentTrackWidth > 0 ? xPosition / currentTrackWidth : 0
                        let newValue = range.lowerBound + Double(progress) * (range.upperBound - range.lowerBound)
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        dragStartTouchOffset = nil
                        if value > 90 {
                            navigateToPureFocus = true
                            
                            
                        } else {
                            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0)) {
                                value = 0
                            }
                        }
                    }
                
                ZStack(alignment: .leading) {
                    Capsule() //ending capsule outline
                        .glassEffect()
                        .frame(width: sliderDraggableElementWidth, height: sliderDraggableElementHeight)
                        .overlay {
                            ZStack {
                                Capsule()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7, 10]))
                                Button(action: {}) {
                                    Text("")
                                        .font(.system(size: focusSliderFontSize, weight: .heavy))
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)
                                .allowsHitTesting(false)
                            }
                        }
                        .offset(x: currentTrackWidth)
                        .opacity(0.4)
                        .foregroundColor(.secondary)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0), Color.white.opacity(1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: knobTotalOffset + sliderDraggableElementWidth, height: sliderDraggableElementHeight)
                    
                    Capsule()
                        .glassEffect()
                        .frame(width: sliderDraggableElementWidth, height: sliderDraggableElementHeight)
                        .overlay {
                            Button(action: {}) {
                                Text("Focus")
                                    .font(.system(size: focusSliderFontSize, weight: .heavy))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(false)
                        }
                        .scaleEffect(isSliderElementPressed ? 1.05 : 1)
                        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0), value: isSliderElementPressed)
                        .shadow(color: Color.black.opacity(isSliderElementPressed ? 0.4 : 0.25), radius: isSliderElementPressed ? 10 : 8, x: 0, y: 4)
                        .offset(x: knobTotalOffset)
                        .gesture(dragGesture)
                }
                .frame(height: sliderDraggableElementHeight)
                .onAppear {
                    trackWidth = currentTrackWidth
                }
                .onChange(of: currentTrackWidth) { oldValue, newValue in
                    trackWidth = newValue
                }
            }
        }
        //MIGHT BE MISSING THIS HERE:
        .frame(height: sliderDraggableElementHeight)
        //think it's offset as of

        .navigationDestination(isPresented: $navigateToPureFocus) {
            PureFocusView()
        }
    }

        
}


#Preview {
    FocusIntensitySlider(
        value: .constant(50),
        range: 0...100,
        sliderDraggableElementWidth: .constant(90),
        sliderDraggableElementHeight: .constant(60)
    )
    .padding()
}
