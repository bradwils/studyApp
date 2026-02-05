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
                
                idleGradient
                    
                        
                    
                // Timer active: White rises from bottom
                timerGradient(height: geometry.size.height)
                    .opacity(isTimerActive ? 0 : 1)
                
            }
            .animation(.easeInOut(duration: 0.8), value: progress)
            .animation(.easeInOut(duration: 0.5), value: isTimerActive)
        }
        .ignoresSafeArea()
        .onAppear {
            startIdleAnimation()
        }
    }
    
    // MARK: - Idle Gradient (Default State)
    //here, this is the default state. however, we need to animate the opacity for both: have a function that fades in/out between the two, depending on isTimerActive
    
    private var idleGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(white: 0.05),
                    Color(white: 0.08),
                    Color(white: 0.05),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .offset(y: 500)
        }
    }
    
    private func startIdleAnimation() {
        withAnimation(
            .linear(duration: 4)
            .repeatForever(autoreverses: true)
        ) {
            idleAnimationOffset = 20
        }
    }
    
    // MARK: - Timer Gradient (Active State)
    
    private func timerGradient(height: CGFloat) -> some View {
        let whitePosition = 1.0 - progress  // 1.0 at start (bottom), 0.0 at end (top)
        
        return GeometryReader { _ in
            ZStack {
                // Base black layer
                Color.black
                
                // White layer that rises from bottom
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black, location: max(0, whitePosition - 0.15)),
                        .init(color: Color(white: 0.3), location: whitePosition - 0.05),
                        .init(color: Color(white: 0.7), location: whitePosition),
                        .init(color: .white, location: min(1.0, whitePosition + 0.05)),
                        .init(color: .white, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}
