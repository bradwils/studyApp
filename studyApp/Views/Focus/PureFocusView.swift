//  PureFocusView.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.

import SwiftUI

//need to use white UI elements exclusively.
struct PureFocusView: View {
    
    @Environment(\.dismiss) var dismiss //get the environment dismiss value
    
    @Binding var isPresented: Bool //to be able to dismiss
    
    @State var timerTimeInterval: TimeInterval = 0 //0.0 gets binded to our durationpicker, so this gets changed as the picker changes value.
    
    // MARK: - State Properties
    
    @State private var vm = PureFocusViewModel()

    //Lock (focus feature)
    @State private var focusLockEnabled: Bool = false;



    var body: some View {
        ZStack(alignment: .bottom) {
            // Animated gradient background
            TimerGradientBackground(
                progress: vm.timerProgress,
                isTimerActive: $vm.timerActivelyRunning
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Leave") {
                    dismiss() // Programmatic dismissal
                }
            }
        }
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
            if !vm.timerActivelyRunning && vm.elapsedTime == 0 {
                durationPicker
            }
            
            // Timer control buttons
            HStack(spacing: 20) {
                //UITWEAK
                // .buttonStyle(.glass) is an iOS 26 style that provides the system glass
                // appearance + the interactive press highlight for free. We no longer need
                // to manually manage foreground/background colors or pressed states.
                // Start/Pause button
                Button(action: {
                    vm.toggleTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: vm.timerActivelyRunning ? "pause.fill" : "play.fill")
                        
                        if (vm.timerActivelyExists) {
                            Text(vm.timerActivelyRunning ? "Pause" : "Resume")
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
                            
                        
                        if (vm.timerActivelyExists) {
                            Text(vm.timerActivelyRunning ? "Pause" : "Resume")
                        } else {
                            Text("Start")
                        }
                    }
                }
                .buttonStyle(.glass)
                
                //UITWEAK
                // Reset button (only show when timer has started)
                // Uses the same .glass style so it visually matches the other controls.
                if vm.elapsedTime > 0 {
                    Button(action: {
                        withAnimation {
                            vm.resetTimer()
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
            DurationPicker(duration: $vm.currentTimerTotalDuration, minHours: $vm.minHours, maxHours: $vm.maxHours, minMinutes: $vm.minMinutes, maxMinutes: $vm.maxMinutes)
        }
    }
    
    private var topScreenCode: some View {
        Text("LLLL")
            .font(.system(size: 35))
            .lineLimit(1)
    }
    
    // MARK: - Computed Properties
    
    private var remainingTimeFormatted: String {
        vm.remainingTime.formattedClock
    }
    
    /// Dynamically adjust foreground color based on background brightness
    private var dynamicForegroundColor: Color {
        vm.timerProgress > 0.6 ? .black : .white
    }
    
    //new timer stuff
    var remainingTime: some View {
        Text("vm.totalduration: \(vm.currentTimerTotalDuration)")
    }
}
    
                
#Preview {
    PureFocusView(isPresented: .constant(true))
}
    


//TODO: make the picker bind to vm.currentTimerTotalDuration properly.
