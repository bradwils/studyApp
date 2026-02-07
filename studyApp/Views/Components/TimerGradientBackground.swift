import SwiftUI

/// Animated gradient background that transitions from black to white based on timer progress.
/// Default state: Subtly animating black gradient with lighter black variations
/// Timer active: White gradient rises from bottom as progress increases (0.0 = all black, 1.0 = all white)
struct TimerGradientBackground: View {
    
    
    
    
    
    
    /// Timer progress: 0.0 = start (all black), 1.0 = complete (all white)
    var progress: CGFloat
    
    @State private var idleBackgroundLinearRandomOffset1: CGFloat = -0.1;
    
    @State private var idleBackgroundLinearRandomOffset2: CGFloat = -0.1;
    
    let cgfloatrand1: CGFloat = CGFloat.random(in: 0.2...0.4) //fixed, random offsets for the liuneargradient to move between
    let cgfloatrand2: CGFloat = CGFloat.random(in: 0.2...0.4)
    
    @State var peachRadialOffsetValue: CGFloat = 0 //controls y movement of peach radial element

    
    
    /// Whether the timer is running (affects animation style)
    @Binding var isTimerActive: Bool
    
    /// Animating offset for the idle radiating effect
    @State private var idleAnimationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Show timer gradient when active OR when there is any progress (paused/partial)
                var showTimer = isTimerActive || progress > 0.0001
                
                idleBackground
                    .opacity(showTimer ? 0 : 1)
//                    .animation(.easeInOut(duration: 2.0), value: showTimer)

                        
                // Timer active: White rises from bottom
                timerGradient(height: geometry.size.height)

                    
                    .opacity(showTimer ? 1 : 0)
//                    .animation(.easeInOut(duration: 2.0), value: showTimer)

                
            }
            // Smoothly animate progress updates and active state toggles
            .animation(.linear(duration: 1), value: progress)
            .animation(.easeInOut(duration: 2), value: isTimerActive) //changing the animation time on this directly affects showTimer, changing how long it goes from true to false. this, as per the animation modifier, will then directly affect the opacity transition time taken where .opacity(showerTimer ? 0 : 1)
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
                    Color.black.opacity(0.3),
                    Color.gray.opacity(0.5),
                    Color.black.opacity(0.7)
                ],
//                startPoint: .topLeading,
                startPoint: UnitPoint(x: 1, y: 0 + idleBackgroundLinearRandomOffset1),
                //we're going to change this so it varies by 0.2
                

//                endPoint: .bottomTrailing
                endPoint: UnitPoint(x: 0, y: 1 + idleBackgroundLinearRandomOffset2),

                
            )
            .ignoresSafeArea()

            // “radial” highlight on the right side (animatable radii)
            Color.clear //top left soft blue
                .modifier(RadialAnimatedGradient(
                    colors: [Color.blue.opacity(0.2), Color.clear],
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
                .modifier(RadialAnimatedGradient( //peach radial background element
                    colors: [Color(hex: "#FFC5AB").opacity(0.2), Color.clear],
                    center: UnitPoint(x: 0.9, y: 0.5 + peachRadialOffsetValue),
                    startRadius: 40 + (idleAnimationOffset * 0),
                    endRadius: 100 + (idleAnimationOffset * 5)
                ))
                .ignoresSafeArea()
            //animate the idleanimation for this section
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: idleAnimationOffset)
                //animate the peach y offset
                .animation(.easeInOut(duration: getRandomTimeInterval(min: 20, max: 40)).repeatForever(autoreverses: true), value: peachRadialOffsetValue)
            
            
//            peachRadialOffsetValue = 0
            
            
        }
        
    }
    
    private func startIdleAnimation() { //starts the changing of the idleAnimationOffset var, which is used as a multiplier to control how much objects animate (such as the expanding of the radianGradeint, etc
        DispatchQueue.main.async { //WHY DISPATCHQUEUE?
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                idleAnimationOffset = 40
            }
        }
        
        DispatchQueue.main.async { //used for the movement of the peachRadial's y
            withAnimation(
                .easeInOut(duration: getRandomTimeInterval(min: 0.5, max: 1))
                .repeatForever(autoreverses: true)
            ) {
                peachRadialOffsetValue = -0.4
            }
            
            
            //really need to understand how dispatching the animation to the main queue does anything, or especially how it works here. it seems like it gets overriden when applying a .animation in the actual view part of the radialgradient, and the animation speed is controlled there (as well as other properties?)
        }
        
        
        DispatchQueue.main.async { //idlebackgroundgradient linear offset for a random cgfloat offset to animate too
            withAnimation(
                .easeInOut(duration: getRandomTimeInterval(min: 20, max: 60))
                .repeatForever(autoreverses: true)
            ) {
                idleBackgroundLinearRandomOffset1 = cgfloatrand1
            }
        }
        
        DispatchQueue.main.async { //WHY DISPATCHQUEUE?
            withAnimation(
                .easeInOut(duration: getRandomTimeInterval(min: 20, max: 60))
                .repeatForever(autoreverses: true)
            ) {
                idleBackgroundLinearRandomOffset2 = cgfloatrand2
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
//                Color.black
                
                // White layer that rises from bottom
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black, location: gradientBlackPointClamped), //black
                        .init(color: Color.white, location: gradientMidpointClamped), //midpoint
                        .init(color: Color.white, location: 1.0) //white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
    
    public func getRandomTimeInterval(min: TimeInterval, max: TimeInterval) -> TimeInterval {
        return TimeInterval.random(in: min...max)
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
