import SwiftUI

/// Represents the display state of the lightweight study timer.
///
struct StudyTrackingView: View {
    
    // MARK: - State Properties
    
    @State private var focusSliderValue: Double = 0
    @State private var timerInProgress: Bool = false
    @State var sliderDraggableElementWidth: CGFloat = 90
    @State var sliderDraggableElementHeight: CGFloat = 60
    @State var onlineFriendCount: Int = 0 //to be dynamic later
    @State private var isLeaderboardPresented: Bool = true
    @State private var currentStudySessionInProgress: Bool = false
    
    @State var timeSinceLastBreakEnded: TimeInterval = 179 //time since last breal has ended
    
    @State var timeSinceLastBreakStarted: TimeInterval = 61 //time since last break started
    
    // MARK: - ViewModels
    
    @StateObject private var studyTrackingViewModel = StudyTrackingViewModel()
    @StateObject private var userProfileStore = UserProfileStore.shared
    
    // MARK: - Helpers
    
    //TIMEINTERVAL -> HOURMINUTESECOND
    private func formattedHMS(from timeInterval: TimeInterval) -> String {
        let duration = Duration.seconds(timeInterval)
        return duration.formatted(.time(pattern: .hourMinuteSecond))
    }
    
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
                MainTimerElement
                connectionRow
                pauseStopRow
                
                focusSliderSection //complex and fucked
                
                horizontalContentScrollRow
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    //.check if above modifier is needed or not













            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        
//        .sheet(isPresented: $isLeaderboardPresented) {
//            LeaderboardSheetView()
//                .padding(10)
//                .presentationDragIndicator(.visible)
//                .presentationBackgroundInteraction(.enabled)
//                .presentationDetents([.height(50), .fraction(0.3), .fraction(0.9)])
//                
//            
//            
//        }
        .onChange(of: userProfileStore.profile.subjects) { old, new in
            if studyTrackingViewModel.selectedSubject == nil, let first = new.first {
                studyTrackingViewModel.updateSubjectSelection(first)
            }
            
            
//                .onChange(of: currentTrackWidth) { oldValue, newValue in
//                    trackWidth = newValue
//                }
        }
        .onReceive(studyTrackingViewModel.$activeSession) { session in
            currentStudySessionInProgress = session != nil
        }



    }

    // MARK: - Sections

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Subject")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ActiveSubjectList(
                    studyTrackingModel: studyTrackingViewModel,
                    subjects: userProfileStore.profile.subjects,
                    isEnabled: !currentStudySessionInProgress
                )
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

    private var MainTimerElement: some View {
        
            TimerSection()
            .padding(.top, 8)
    }

    private func TimerSection() -> some View {
        VStack(spacing: 8) {

            Text("11:22")
                .font(.system(size: 100).monospacedDigit())
                .fontWeight(.semibold)

        }
    }

    private var connectionRow: some View {
        HStack(spacing: 6) {

            
            Text("\(onlineFriendCount) online friends")
                .font(.caption)
            
            
            Image(systemName: "dot.radiowaves.up.forward")
            
                .font(.subheadline)
                .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.periodic(delay: 4.0)))
                .foregroundColor(.green)
        }
        
        
//        .foregroundColor(.secondary)
        
    }
    
    

    private var pauseStopRow: some View { //last paused / last resumed & start/resume and stop button
        ZStack {
            HStack {
                HStack { //child hstack1, aligned to be right-most within the available space
                    // "Pause at" text: fades in and slides from left when paused
                    VStack(spacing: 4) {
                        if (timerInProgress) { //if we're currently tracking (not paused)
                            Text("Since last break")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(alignment: .center)
                            
                            Text(formattedHMS(from: timeSinceLastBreakEnded)) //parse through a helper; format the timeinterval as hour/minute/second
                                .font(.headline.monospacedDigit())
                                .frame(alignment: .center)

                        } else { //if we're paused
                            Text("Break Timer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(alignment: .center)

                            
                            Text(formattedHMS(from: timeSinceLastBreakStarted)) //parse through a helper; format the timeinterval as hour/minute/second
                                .font(.headline.monospacedDigit())
                                .frame(alignment: .center)

                        }

                    } //                        t : f
                    //                    hidden : showing
                    .offset(x: timerInProgress ? 0 : 0)
                    .animation(.easeInOut(duration: 0.3), value: timerInProgress)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                
                
                HStack { //child hstack2, aligned to be left-most within the available space
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                            timerInProgress.toggle()
                        }
                    } label: {
                        ZStack {
                            if timerInProgress {
                                Text("Stop")
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                            } else {
                                Text("Start")
                                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            }
                        }
                        .frame(height: 20) // keeps layout from jumping during the transition
                        .font(.headline)
                        .padding(.horizontal, 32) //padding for start button, makes button wider than text
                        .padding(.vertical, 12)
                        .frame(maxWidth: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.18))
                        )
                    }
                    .animation(.easeInOut(duration: 0.3), value: timerInProgress)
                    .frame(alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading) //align to left

                
                
            }
//            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 4)

    }

    private var focusSliderSection: some View {
        
            
//                Text("Focus intensity")
//                    .font(.subheadline.weight(.semibold))
//                    .foregroundStyle(.primary)

                

//                Text("DEBUG: \(Int(focusSliderValue))%")
//                    .font(.subheadline.monospacedDigit())
//                    .foregroundStyle(.secondary)
        

        
        FocusIntensitySlider(value: $focusSliderValue, range: 0...100, sliderDraggableElementWidth: $sliderDraggableElementWidth, sliderDraggableElementHeight: $sliderDraggableElementHeight)
            .frame(height: 40)
            .accessibilityLabel("Focus intensity")
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }

    public var horizontalContentScrollRow: some View {
        HorizontalContentScrollRow()
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        StudyTrackingView()
    }
}

