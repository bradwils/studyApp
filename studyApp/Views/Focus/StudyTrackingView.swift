import SwiftUI

/// Represents the display state of the lightweight study timer.
///
struct StudyTrackingView: View {
    
    @State private var focusSliderValue: Double = 0
    
    
    var body: some View {
        ZStack {
            // base gradient
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.35),
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // “radial” highlight on the right side
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.35),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 0,
                endRadius: 260
            )
            .blendMode(.softLight)
            .ignoresSafeArea()

            VStack(spacing: 24) {
                headerRow
                timeSummaryRow
                bigTimersRow
                connectionRow
                pauseStopRow
                focusSliderSection

                Spacer()

                nowPlayingRow
                leaderboardHandle
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
    }

    // MARK: sections

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Subject")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text("Subject name")
                        .font(.title3.weight(.semibold))

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("00:00:00")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.medium)
            }
        }
    }

    private var timeSummaryRow: some View {
        HStack {
            Text("Today")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("00:00:00")
                .font(.subheadline.monospacedDigit())
                .foregroundColor(.primary)
        }
    }

    private var bigTimersRow: some View {
        HStack(spacing: 40) {
            timerBubble(label: "Session", time: "00:00")
            timerBubble(label: "Break", time: "00:00")
        }
        .padding(.top, 8)
    }

    private func timerBubble(label: String, time: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 86, height: 86)

                Text(time)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.semibold)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var connectionRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi")
                .font(.subheadline)

            Text("Online ")
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }

    private var pauseStopRow: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pause at")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("00:12:34")
                    .font(.headline.monospacedDigit())
            }

            Spacer()

            Button(action: {}) {
                Text("Stop")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    )
            }
        }
        .padding(.top, 4)
    }

    private var focusSliderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Focus intensity")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(Int(focusSliderValue))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            FocusIntensitySlider(value: $focusSliderValue, range: 0...100)
                .frame(height: 40)
                .accessibilityLabel("Focus intensity")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
    }

    private var nowPlayingRow: some View {
        VStack(spacing: 12) {
            Divider().background(Color.white.opacity(0.4))

            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Now playing")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Lo-fi focus mix")
                        .font(.subheadline.weight(.semibold))

                    Text("Artist name")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // circular song progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: 0.35)
                        .stroke(
                            Color.white.opacity(0.9),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(width: 34, height: 34)
            }
        }
    }

    private var leaderboardHandle: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 44, height: 4)

            Text("Leaderboard")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.15))
                .ignoresSafeArea(edges: .bottom)
        )
        .padding(.top, 12)
    }
}


#Preview {
    NavigationStack {
        StudyTrackingView()
    }
}


// MARK: - Formatting helpers

extension TimeInterval {
    var formattedClock: String {
        let totalSeconds = Int(self)
        let minutes = (totalSeconds / 60) % 60
        let seconds = totalSeconds % 60
        let hours = totalSeconds / 3600
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}



// MARK: - PREXISTING ASSETS

struct DotStyleDivider: View {
    //call as DotStyleDivider(orientation: .horizontal, length: 123)
    enum Orientation {
        case horizontal
        case vertical
    }

    var orientation: Orientation = .vertical
    var length: CGFloat = 0; //default of 0 if there is nothing defined
    var dotCount: Int { Int(length / 8) }
    var dotSpacing: CGFloat = 6

    private var isHorizontal: Bool { orientation == .horizontal }


    

    var body: some View {

        Rectangle()
            .fill(Color.white.opacity(0.25))
            .frame(
                width: isHorizontal ? length : 1,
                height: isHorizontal ? 1 : length
            )
            .overlay {
                Group {
                    if isHorizontal {
                        HStack(spacing: dotSpacing) {
                            dots
                        }
                    } else {
                        VStack(spacing: dotSpacing) {
                            dots
                        }
                    }
                }
            }
    }

    private var dots: some View { //dots view which overlays the line for the divider
        ForEach(0..<dotCount, id: \.self) { _ in
            Circle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 2, height: 2)
        }
    }
}


// MARK: - Custom Controls

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
    @Binding var value: Double
    var range: ClosedRange<Double>
    
    var sliderDraggableElementWidth: CGFloat = 80
    let sliderDraggableElementHeight: CGFloat = 45
    
    var sliderDraggableElementRadius: CGFloat { sliderDraggableElementWidth / 2 }
    @State private var dragStartTouchOffset: CGFloat?
    
    
    

    // Track whether the knob is pressed so the capsule can animate a pop (scale/shadow) while dragging.
    @GestureState private var isSliderElementPressed = false
    // Capture the live translation for a subtle offset that makes the knob feel draggable.
    @GestureState private var knobDragTranslation = CGSize.zero

    private var normalizedProgress: Double {
        guard range.upperBound != range.lowerBound else { return 0 } //make sure it's a valid range
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        GeometryReader { geo in
            // Clamp the normalized progress to 0–1 so the knob stays on the track.
            let clampedProgress = min(max(normalizedProgress, 0), 1)
            // Track width excludes the knob width so the thumb never overhangs.
            let trackWidth = geo.size.width - sliderDraggableElementWidth
            
            let knobOffset = clampedProgress * trackWidth
            // Single drag gesture drives knob animation states and slider updates at once.
            let dragGesture = DragGesture(minimumDistance: 0)
                .updating($isSliderElementPressed) { _, state, _ in
                    state = true
                }
                .updating($knobDragTranslation) { value, state, _ in
                    state = value.translation
                }
                .onChanged { gesture in
                    let knobCenter = knobOffset + sliderDraggableElementRadius
                    let startOffset = dragStartTouchOffset ?? (gesture.startLocation.x - knobCenter)
                    if dragStartTouchOffset == nil {
                        dragStartTouchOffset = startOffset
                    }
                    // Respect the knob’s inset while clamping within the available track width.
                    let desiredCenter = gesture.location.x - startOffset
                    let leftEdge = desiredCenter - sliderDraggableElementRadius
                    let maxTrackWidth = max(trackWidth, 0)
                    let xPosition = min(max(0, leftEdge), maxTrackWidth)
                    
                    let progress = maxTrackWidth > 0 ? xPosition / maxTrackWidth : 0
                    // Map normalized progress back to the slider’s value range.
                    let newValue = range.lowerBound + Double(progress) * (range.upperBound - range.lowerBound)
                    // Finally clamp to the allowed value range before assigning.
                    value = min(max(newValue, range.lowerBound), range.upperBound)
                }
                .onEnded { _ in
                    dragStartTouchOffset = nil
                    if value > 90 {
                        //go to new screen
                        //make a popup alert for debug
                        value = 50
                    }
                }
                    

            ZStack(alignment: .leading) {
                
                dottedLineFiller

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0), Color.white.opacity(1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: knobOffset + sliderDraggableElementWidth, height: sliderDraggableElementHeight)

                
                Capsule()
                    .glassEffect()
                    .frame(width: sliderDraggableElementWidth, height: sliderDraggableElementHeight)
                    .overlay {
                        Button(action: {}) {
                            Text("Focus")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                        .allowsHitTesting(false)
                    }
                    // Slight scale, shadow, and translation changes give the knob a touch-reactive feel.
                    .scaleEffect(isSliderElementPressed ? 1.05 : 1)
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0), value: isSliderElementPressed)
                    .shadow(color: Color.black.opacity(isSliderElementPressed ? 0.4 : 0.25), radius: isSliderElementPressed ? 10 : 8, x: 0, y: 4)

                
                    .offset(x: knobOffset)
                    .offset(x: knobDragTranslation.width * 0.05, y: knobDragTranslation.height * 0.05)
                    .gesture(dragGesture)
                    
            }
                .frame(height: sliderDraggableElementHeight)
//            .contentShape(Rectangle())
        }
    }

}
