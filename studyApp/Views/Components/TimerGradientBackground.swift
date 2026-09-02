import SwiftUI

// Animated gradient background. Idle: subtly drifting purple/black washes.
// Timer active: white rises from the bottom as progress goes 0 → 1.
struct TimerGradientBackground: View {

    // Timer progress: 0.0 = start (all black), 1.0 = complete (all white)
    var progress: CGFloat

    // Whether the timer is running (affects animation style)
    @Binding var isTimerActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var idleBackgroundLinearRandomOffset1: CGFloat = -0.1
    @State private var idleBackgroundLinearRandomOffset2: CGFloat = -0.1

    // Sampled once per appearance: fixed random targets the linear gradient drifts toward.
    private let cgfloatrand1: CGFloat = .random(in: 0.2...0.4)
    private let cgfloatrand2: CGFloat = .random(in: 0.2...0.4)

    private let peachDriftDuration: TimeInterval = .random(in: 12...18)

    // Controls y movement of the peach radial element
    @State private var peachRadialOffsetValue: CGFloat = 0

    // Animating offset for the idle radiating effect
    @State private var idleAnimationOffset: CGFloat = 0

    // Show the timer gradient when active OR when there is any progress (paused/partial).
    private var showTimer: Bool {
        isTimerActive || progress > 0.0001
    }

    var body: some View {
        ZStack {
            idleBackground
                .opacity(showTimer ? 0 : 1)

            timerGradient
                .opacity(showTimer ? 1 : 0)
        }
        // The isTimerActive animation drives showTimer, so its duration controls
        // how long the idle/timer opacity cross-fade takes.
        .animation(.linear(duration: 1), value: progress)
        .animation(.easeInOut(duration: 2), value: isTimerActive)
        .ignoresSafeArea()
        .onAppear {
            startIdleAnimation()
        }
    }

    // MARK: - Idle Gradient (Default State)

    private var idleBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(1),
                    Color.purple.opacity(0.9), // the most prominent background color
                    Color.black.opacity(0.7)
                ],
                startPoint: UnitPoint(x: 1, y: 0 + idleBackgroundLinearRandomOffset1),
                endPoint: UnitPoint(x: 0, y: 1 + idleBackgroundLinearRandomOffset2)
            )
            .ignoresSafeArea()

            // Top-left soft blue highlight (animatable radii)
            Color.clear
                .modifier(RadialAnimatedGradient(
                    colors: [Color.blue.opacity(0.2), Color.clear],
                    center: UnitPoint(x: 0.1, y: 0.3),
                    startRadius: 40 + (idleAnimationOffset * 0.1),
                    endRadius: 180 + (idleAnimationOffset * 5)
                ))
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .linear(duration: 3).repeatForever(autoreverses: true), value: idleAnimationOffset)

            // Bottom-of-screen red movement
            Color.clear
                .modifier(RadialAnimatedGradient(
                    colors: [Color.red.opacity(0.2), Color.clear],
                    center: .bottom,
                    startRadius: 0 + (idleAnimationOffset * 0.2),
                    endRadius: 100 + (idleAnimationOffset * 10)
                ))
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .linear(duration: 3).repeatForever(autoreverses: true), value: idleAnimationOffset)

            // Peach radial element, drifting vertically on the right
            Color.clear
                .modifier(RadialAnimatedGradient(
                    colors: [Color.purple.opacity(0.3), Color.clear],
                    center: UnitPoint(x: 0.9, y: 0.5 + peachRadialOffsetValue),
                    startRadius: 120,
                    endRadius: 250
                ))
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .easeInOut(duration: peachDriftDuration).repeatForever(autoreverses: true), value: peachRadialOffsetValue)
        }
    }

    // Kicks off the perpetual idle drift by moving each driving value toward its
    // target; the `.animation(value:)` modifiers above supply the repeat curves.
    private func startIdleAnimation() {
        // Reduce Motion: rest at the midpoint of each drift instead of animating.
        guard !reduceMotion else {
            idleAnimationOffset = 20
            peachRadialOffsetValue = -0.2
            idleBackgroundLinearRandomOffset1 = (cgfloatrand1 - 0.1) / 2
            idleBackgroundLinearRandomOffset2 = (cgfloatrand2 - 0.1) / 2
            return
        }

        // Deferred one runloop turn so the repeatForever animations reliably start
        // when the view appears mid-transition.
        DispatchQueue.main.async {
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                idleAnimationOffset = 40
            }

            withAnimation(
                .easeInOut(duration: .random(in: 0.5...1))
                .repeatForever(autoreverses: true)
            ) {
                peachRadialOffsetValue = -0.4
            }

            withAnimation(
                .easeInOut(duration: .random(in: 20...60))
                .repeatForever(autoreverses: true)
            ) {
                idleBackgroundLinearRandomOffset1 = cgfloatrand1
            }

            withAnimation(
                .easeInOut(duration: .random(in: 20...60))
                .repeatForever(autoreverses: true)
            ) {
                idleBackgroundLinearRandomOffset2 = cgfloatrand2
            }
        }
    }

    // MARK: - Timer Gradient (Active State)

    private var timerGradient: some View {
        // 1.0 at start (bottom), 0.0 at end (top)
        let whitePosition = 1.0 - progress
        let gradientBlackPointClamped = max(0.0, min(1.0, whitePosition - 0.05))
        let gradientMidpointClamped = max(0.0, min(1.0, whitePosition))

        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .black, location: gradientBlackPointClamped),
                .init(color: .white, location: gradientMidpointClamped),
                .init(color: .white, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Animatable radial gradient helper

private struct RadialAnimatedGradient: ViewModifier, Animatable {
    var colors: [Color]
    var center: UnitPoint
    var startRadius: CGFloat
    var endRadius: CGFloat

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(Double(startRadius), Double(endRadius)) }
        set {
            startRadius = CGFloat(newValue.first)
            endRadius = CGFloat(newValue.second)
        }
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    RadialGradient(
                        gradient: Gradient(colors: colors),
                        center: center,
                        startRadius: startRadius,
                        endRadius: endRadius
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
    }
}

#Preview {
    TimerGradientBackground(progress: 0, isTimerActive: .constant(false))
}
