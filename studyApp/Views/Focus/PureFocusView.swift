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
                isTimerActive: $viewModel.isTimerRunning
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
            if !viewModel.isTimerRunning && viewModel.elapsedTime == 0 {
                durationPicker
            }
            if (viewModel.isTimerRunning) {
                Text("TRUE")
            } else {
                Text("FALSE")
            }
            
            // Timer control buttons
            HStack(spacing: 20) {
                // Start/Pause button
                Button(action: {
                    viewModel.toggleTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                        Text(viewModel.isTimerRunning ? "Pause" : "Start")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(dynamicButtonColor)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(dynamicButtonBackground)
                    )
                }
                
                // Reset button (only show when timer has started)
                if viewModel.elapsedTime > 0 {
                    Button(action: {
                        withAnimation {
                            viewModel.resetTimer()
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(dynamicButtonColor)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(dynamicButtonBackground)
                            )
                    }
                }
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
    
    /// Dynamically adjust button colors for contrast
    private var dynamicButtonColor: Color {
        viewModel.timerProgress > 0.6 ? .white : .black
    }
    
    private var dynamicButtonBackground: Color {
        viewModel.timerProgress > 0.6 ? .black.opacity(0.8) : .white.opacity(0.85)
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
