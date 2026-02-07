import SwiftUI

/// Animated gradient background that transitions from black to white based on timer progress.
/// Default state: Subtly animating black gradient with lighter black variations
/// Timer active: White gradient rises from bottom as progress increases (0.0 = all black, 1.0 = all white)
struct TimerGradientBackground: View {
    
    
    
    
    
    
    /// Timer progress: 0.0 = start (all black), 1.0 = complete (all white)
    var progress: CGFloat
    
    
    /// Whether the timer is running (affects animation style)
    @Binding var isTimerActive: Bool
    
    /// Animating offset for the idle radiating effect
    @State private var idleAnimationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Show timer gradient when active OR when there is any progress (paused/partial)
                let showTimer = isTimerActive || progress > 0.0001
                
                idleBackground
                    .opacity(showTimer ? 0 : 1)
                        
                // Timer active: White rises from bottom
                timerGradient(height: geometry.size.height)
                    .opacity(showTimer ? 1 : 0)
                
            }
            // Smoothly animate progress updates and active state toggles
            .animation(.linear(duration: 0.12), value: progress)
            .animation(.easeInOut(duration: 0.5), value: isTimerActive)
        }
        .ignoresSafeArea()
        .onAppear {
            startIdleAnimation()
        }
    }
    
    // MARK: - Idle Gradient (Default State)
    //here, this is the default state. however, we need to animate the opacity for both: have a function that fades in/out between the two, depending on isTimerActive
    
    private var idleBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.8),
                    Color.gray.opacity(0.7),
                    Color.black.opacity(1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // “radial” highlight on the right side (animatable radii)
            Color.clear //top left soft blue
                .modifier(RadialAnimatedGradient(
                    colors: [Color.blue.opacity(0.1), Color.clear],
                    center: UnitPoint(x: 0.1, y: 0.3),
                    startRadius: 40 + (idleAnimationOffset * 0.1),
                    endRadius: 180 + (idleAnimationOffset * 5)
                ))
                .ignoresSafeArea()
                .animation(.linear(duration: 6).repeatForever(autoreverses: true), value: idleAnimationOffset)
            
            
            
            
            Color.clear //bottom of the screen, red movement
                .modifier(RadialAnimatedGradient(
                    colors: [Color.red.opacity(0.2), Color.clear],
                    center: .bottom,
                    startRadius: 0 + (idleAnimationOffset * 0.2),
                    endRadius: 50 + (idleAnimationOffset * 10)
                ))
                .ignoresSafeArea()
                .animation(.linear(duration: 7).repeatForever(autoreverses: true), value: idleAnimationOffset)
            
            
            Color.clear
                .modifier(RadialAnimatedGradient(
                    colors: [Color.white.opacity(0.1), Color.clear],
                    center: UnitPoint(x: 0.9, y: 0.1),
                    startRadius: 40 + (idleAnimationOffset * 0),
                    endRadius: 100 + (idleAnimationOffset * 5)
                ))
                .ignoresSafeArea()
                .animation(.linear(duration: 5).repeatForever(autoreverses: true), value: idleAnimationOffset)
            
            
            
            
            
        }
        
    }
    
    private func startIdleAnimation() { //starts the changing of the idleAnimationOffset var, which is used as a multiplier to control how much objects animate (such as the expanding of the radianGradeint, etc
        DispatchQueue.main.async {
            withAnimation(
                .linear(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                idleAnimationOffset = 40
            }
        }
    }
    
    // MARK: - Timer Gradient (Active State)
    
    private func timerGradient(height: CGFloat) -> some View {
        // 1.0 at start (bottom), 0.0 at end (top)
        let whitePosition = 1.0 - progress
        // clamp helper
        let gradientBlackPointClamped = max(0.0, min(1.0, whitePosition - 0.05))
        let gradientMidpointClamped = max(0.0, min(1.0, whitePosition))
        
        return GeometryReader { _ in
            ZStack {
                // Base black layer
                Color.black
                
                // White layer that rises from bottom
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black, location: gradientBlackPointClamped), //black
                        .init(color: Color(white: 0.2), location: gradientMidpointClamped), //midpoint
                        .init(color: .white, location: 1.0) //white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Animatable radial gradient helper

fileprivate struct RadialAnimatedGradient: AnimatableModifier {
    var colors: [Color]
    var center: UnitPoint
    var startRadius: CGFloat
    var endRadius: CGFloat
    
    // Enable animation between start/end radii
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(Double(startRadius), Double(endRadius)) }
        set {
            startRadius = CGFloat(newValue.first)
            endRadius = CGFloat(newValue.second)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    RadialGradient(
                        gradient: Gradient(colors: colors),
                        center: center,
                        startRadius: startRadius,
                        endRadius: endRadius
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            )
    }
}
