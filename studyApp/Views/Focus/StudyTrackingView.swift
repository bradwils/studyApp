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
    
    // MARK: - ViewModels
    
    @StateObject private var studyTrackingViewModel = StudyTrackingViewModel()
    @StateObject private var subjectStore = SubjectStore()
    
    


    
    
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
                focusGoalTimer
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
        .onChange(of: subjectStore.subjects) { old, new in
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
                    subjects: subjectStore.subjects,
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
    
    

    private var pauseStopRow: some View {
        ZStack {
            // "Pause at" text: fades in and slides from left when paused
            VStack(spacing: 4) {
                Text("Pause at")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("00:12:34")
                    .font(.headline.monospacedDigit())
            } //                        t : f
            //                    hidden : showing
            .opacity(timerInProgress ? 0 : 1)
            .offset(x: timerInProgress ? 50 : -80)
            .animation(.easeInOut(duration: 0.3), value: timerInProgress)

            // Button: centered when running, slides right when paused
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
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))                    }
                }
                .frame(height: 20) // keeps layout from jumping during the transition
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .frame(maxWidth: 150)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
            }
            .offset(x: timerInProgress ? 0 : 80)
            .animation(.easeInOut(duration: 0.3), value: timerInProgress)
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

    private var focusGoalTimer: some View {
        FocusGoalTimer()
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
