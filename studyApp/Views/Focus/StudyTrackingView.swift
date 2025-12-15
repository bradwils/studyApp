import SwiftUI

/// Represents the display state of the lightweight study timer.
///
struct StudyTrackingView: View {
    
    @State private var focusSliderValue: Double = 0
    
    @State private var timerInProgress: Bool = false
    
    @State var sliderDraggableElementWidth: CGFloat = 90
    @State var sliderDraggableElementHeight: CGFloat = 60
    
    @State var onlineFriendCount: Int = 0 //to be dynamic later

    @State private var isLeaderboardPresented: Bool = true
    
    @StateObject private var studyTrackingModel = StudyTrackingModel()
    @StateObject private var subjectStore = SubjectStore()
    @State private var currentStudySessionInProgress: Bool = false
    
    


    
    
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
        .onChange(of: subjectStore.subjects) { old, new in
            if studyTrackingModel.selectedSubject == nil, let first = new.first {
                studyTrackingModel.updateSubjectSelection(first)
            }
            
            
//                .onChange(of: currentTrackWidth) { oldValue, newValue in
//                    trackWidth = newValue
//                }
        }
        .onReceive(studyTrackingModel.$activeSession) { session in
            currentStudySessionInProgress = session != nil
        }



    }

    // MARK: sections

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Subject")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ActiveSubjectList(
                    studyTrackingModel: studyTrackingModel,
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

    private var horizontalContentScrollRow: some View {
        TabView {
            MediaContentTabView()
            
            LeaderboardSheetView()
                .padding(.horizontal)

            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))

        
        
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
//MARK: FOCUS SLIDER STRUCT
struct FocusIntensitySlider: View {
    
    @Namespace private var namespace

    
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    
    @Binding var sliderDraggableElementWidth: CGFloat
    @Binding var sliderDraggableElementHeight: CGFloat
    
    var sliderDraggableElementRadius: CGFloat { sliderDraggableElementWidth / 2 }
    @State private var dragStartTouchOffset: CGFloat?
    let focusSliderFontSize: CGFloat = 20
    @State var trackWidth: CGFloat = 0 // Keep track width available for other logic that depends on the slider bounds

    // Track whether the knob is pressed so the capsule can animate a pop (scale/shadow) while dragging.
    @GestureState private var isSliderElementPressed = false
    // Capture the live translation for a subtle offset that makes the knob feel draggable.
    @GestureState private var knobDragTranslation = CGSize.zero

    private var normalizedProgress: Double {
        guard range.upperBound != range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            dottedLineFiller

            GeometryReader { geo in
                // Track width excludes the knob width so the thumb stays inside the slider bounds.
                let currentTrackWidth = max(geo.size.width - sliderDraggableElementWidth, 0)
                let clampedProgress = min(max(normalizedProgress, 0), 1)
                // Knob offset matches the normalized progress along the available track width.
                let knobOffset = clampedProgress * currentTrackWidth
                let knobTotalOffset = CGFloat(min(max(knobOffset, 0), currentTrackWidth))
                let dragGesture = DragGesture(minimumDistance: 0)
                    .updating($isSliderElementPressed) { _, state, _ in
                        state = true
                    }
                    .updating($knobDragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { gesture in
                        let knobCenter = knobOffset + sliderDraggableElementRadius
                        let startOffset: CGFloat = dragStartTouchOffset ?? (gesture.startLocation.x - knobCenter)
                        if dragStartTouchOffset == nil {
                            dragStartTouchOffset = startOffset
                        }
                        let desiredCenter = gesture.location.x - startOffset
                        let leftEdge = desiredCenter - sliderDraggableElementRadius
                        let xPosition = min(max(0, leftEdge), currentTrackWidth)
                        // Convert the thumb position into normalized progress along the track.
                        let progress = currentTrackWidth > 0 ? xPosition / currentTrackWidth : 0
                        let newValue = range.lowerBound + Double(progress) * (range.upperBound - range.lowerBound)
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        dragStartTouchOffset = nil
                        if value > 90 {
                            value = 0
                        } else {
                            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0)) {
                                value = 0
                            }
                        }
                    }

                ZStack(alignment: .leading) {
                    Capsule() //ending capsule outline
                        .glassEffect()
                        .frame(width: sliderDraggableElementWidth, height: sliderDraggableElementHeight)
                        .overlay {
                            ZStack {
                                Capsule()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7, 10]))
                                Button(action: {}) {
                                    Text("")
                                        .font(.system(size: focusSliderFontSize, weight: .heavy))
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)
                                .allowsHitTesting(false)
                            }
                        }
                        .offset(x: currentTrackWidth)
                        .opacity(0.4)
                        .foregroundColor(.secondary)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0), Color.white.opacity(1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: knobTotalOffset + sliderDraggableElementWidth, height: sliderDraggableElementHeight)

                    Capsule()
                        .glassEffect()
                        .frame(width: sliderDraggableElementWidth, height: sliderDraggableElementHeight)
                        .overlay {
                            Button(action: {}) {
                                Text("Focus")
                                    .font(.system(size: focusSliderFontSize, weight: .heavy))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(false)
                        }
                        .scaleEffect(isSliderElementPressed ? 1.05 : 1)
                        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0), value: isSliderElementPressed)
                        .shadow(color: Color.black.opacity(isSliderElementPressed ? 0.4 : 0.25), radius: isSliderElementPressed ? 10 : 8, x: 0, y: 4)
                        .offset(x: knobTotalOffset)
                        .gesture(dragGesture)
                }
                .frame(height: sliderDraggableElementHeight)
                .onAppear {
                    trackWidth = currentTrackWidth
                }
                .onChange(of: currentTrackWidth) { oldValue, newValue in
                    trackWidth = newValue
                }
            }
        }
        .frame(height: sliderDraggableElementHeight)
    }
}

struct LeaderboardSheetView: View {
    private let topSafeAreaSpacing: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: topSafeAreaSpacing)

            List {
                Text("Leaderboard Sheet")
                Text("A")
                Text("A")
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}


struct MediaContentTabView: View {
    var body: some View {
        HStack {
            //element one
            
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    //cover art, TBD
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.2))
                        .aspectRatio(1.0, contentMode: .fill)
                        .frame(maxWidth: 120, maxHeight: 120) //iphone size
                    //ipad sixe tbd
                    
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
                .padding(.vertical, 12)
                
            }
            .frame(maxHeight: .infinity, alignment: .center)
            
            //element two
            
            
            
            
            
        }
        .padding(.horizontal)    }
}


struct ActiveSubjectList: View {
    @ObservedObject var studyTrackingModel: StudyTrackingModel
    var subjects: [Subject]
    var isEnabled: Bool

    @State private var subjectSelection: Subject?

    var body: some View {
        Group {
            if subjects.isEmpty {
                Text("No subjects yet")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Picker("Subject", selection: selectionBinding) {
                    ForEach(subjects) { subject in
                        Text(subject.name)
                            .tag(subject)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!isEnabled)
                .onAppear { //update the view before it appears
                    if subjectSelection == nil {
                        subjectSelection = studyTrackingModel.selectedSubject ?? subjects.first
                    }
                    if studyTrackingModel.selectedSubject == nil, let fallback = subjectSelection {
                        studyTrackingModel.updateSubjectSelection(fallback)
                    }
                }
                .onChange(of: subjects) { old, new in
                    if subjectSelection == nil, let fallback = new.first {
                        subjectSelection = fallback
                        studyTrackingModel.updateSubjectSelection(fallback)
                    }
                }
                .onChange(of: subjectSelection) { old, new in //if selected subject changes,
                    studyTrackingModel.updateSubjectSelection(new)
                }
                .onChange(of: studyTrackingModel.selectedSubject) { old, new in //if subject changes elsewhere, update
                    if new != subjectSelection {
                        subjectSelection = new
                    }
                }
            }
        }
    }

    private var selectionBinding: Binding<Subject> {
        Binding(
            get: { subjectSelection ?? subjects.first! },
            set: { subjectSelection = $0 }
        )
    }
}

// MARK: - Mock Leaderboard Sheet

