//  PureFocusView.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.

import SwiftUI

//need to use white UI elements exclusively.
struct PureFocusView: View {
    
    @State var timerTimeInterval: TimeInterval = 0 //0.0 gets binded to our durationpicker, so this gets changed as the picker changes value.
    
    // MARK: - State Properties
    
    @StateObject private var viewModel = PureFocusViewModel()
    
    //Lock (focus feature)
    @State private var focusLockEnabled: Bool = false;

    // Duration picker bounds (moved out of DurationPicker)
    @State private var minHours: Int = 0
    @State private var maxHours: Int = 8
    @State private var minMinutes: Int = 0
    @State private var maxMinutes: Int = 59

    var body: some View {
        ZStack(alignment: .bottom) {
            // Animated gradient background
            TimerGradientBackground(
                progress: viewModel.timerProgress,
                isTimerActive: $viewModel.timerActivelyRunning
            )
            
            VStack() {
                topScreenCode
                Spacer()
                    .frame(maxHeight: 150)
                
                // Timer controls
                timerControlsSection
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)

            CustomBottomSheet()
        }
        .toolbar(.hidden, for: .tabBar)
        .foregroundColor(dynamicForegroundColor)
        .navigationBarBackButtonHidden(false)
    }
    
    // MARK: - Subviews
    
    private var timerControlsSection: some View {
        VStack(spacing: 20) {
            // Remaining time display
            Text(remainingTimeFormatted)
                .bold()
                .font(.system(size: 70))
                .monospacedDigit()
            
            remainingTime
                
            
            // Duration picker (when timer is not running)
            if !viewModel.timerActivelyRunning && viewModel.elapsedTime == 0 {
                durationPicker
            }
            
//            //DEBUG
//            if (viewModel.timerActivelyRunning) {
//                Text("running: TRUE")
//            } else {
//                Text("running: FALSE")
//            }
//            
//            if (viewModel.timerActivelyExists) { //DEBUG
//                Text("exists: TRUE")
//            } else {
//                Text("exists: FALSE")
//            }
            
            
            // Timer control buttons
            HStack(spacing: 20) {
                //UITWEAK
                // .buttonStyle(.glass) is an iOS 26 style that provides the system glass
                // appearance + the interactive press highlight for free. We no longer need
                // to manually manage foreground/background colors or pressed states.
                // Start/Pause button
                Button(action: {
                    viewModel.toggleTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.timerActivelyRunning ? "pause.fill" : "play.fill")
                        
                        if (viewModel.timerActivelyExists) {
                            Text(viewModel.timerActivelyRunning ? "Pause" : "Resume")
                        } else {
                            Text("Start")
                        }
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                //UIEND
                
                //lock button: PAID FEATURE
                Button(action: {
                    withAnimation(
                        .easeInOut(duration: 0.5)
                    ) {
                        focusLockEnabled.toggle()
                        
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: focusLockEnabled ? "lock.fill" : "lock.open.fill")
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .offUp.byLayer), options: .nonRepeating))
                            
                        
                        if (viewModel.timerActivelyExists) {
                            Text(viewModel.timerActivelyRunning ? "Pause" : "Resume")
                        } else {
                            Text("Start")
                        }
                    }
                }
                .buttonStyle(.glass)
                
                //UITWEAK
                // Reset button (only show when timer has started)
                // Uses the same .glass style so it visually matches the other controls.
                if viewModel.elapsedTime > 0 {
                    Button(action: {
                        withAnimation {
                            viewModel.resetTimer()
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(14)
                    }
                    .buttonStyle(.glass)
                }
                //UIEND
            }
            .padding(.top, 10)
        }
    }
    
    private var durationPicker: some View {
        
        
        VStack(spacing: 8) {

            DurationPicker(duration: $viewModel.currentTimerTotalDuration, minHours: $minHours, maxHours: $maxHours, minMinutes: $minMinutes, maxMinutes: $maxMinutes) //
        }
    }
    
    private var topScreenCode: some View {
        Text("LLLL")
            .font(.system(size: 35))
            .lineLimit(1)
    }
    
    // MARK: - Computed Properties
    
    private var remainingTimeFormatted: String {
        viewModel.remainingTime.formattedClock
    }
    
    /// Dynamically adjust foreground color based on background brightness
    private var dynamicForegroundColor: Color {
        viewModel.timerProgress > 0.6 ? .black : .white
    }
    
    //new timer stuff
    var remainingTime: some View {
        Text("vm.totalduration: \(viewModel.currentTimerTotalDuration)")
    }
}
    
                
#Preview {
    PureFocusView()
}
    


//TODO: make the picker bind to vm.currentTimerTotalDuration properly.
