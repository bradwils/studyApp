import Combine
import SwiftUI

/// Represents the display state of the lightweight study timer.
///
struct StudyTrackingView: View {

    // MARK: - State Properties

    // Drives the PureFocusView fullScreenCover below — set to true by the slider
    // itself (via its `complete` binding) once the user drags it past the commit threshold.
    @State private var pureFocusViewState = false

    // Bound to FocusIntensitySlider's knob position (0...100); reset to 0 on appear and
    // again once the slider commits, so the tray is always empty when this view is shown.
    @State private var focusSliderValue: Double = 0
    @State var sliderDraggableElementWidth: CGFloat = 90
    @State var sliderDraggableElementHeight: CGFloat = 60
    @State var onlineFriendCount: Int = 0  //to be dynamic later
    @State private var isLeaderboardPresented: Bool = true
    @State private var currentStudySessionInProgress: Bool = false

    // MARK: - ViewModels

    @State private var vm = StudyTrackingViewModel()

    // MARK: - Helpers

    //TIMEINTERVAL -> HOURMINUTESECOND
    private func formattedHMS(from timeInterval: TimeInterval) -> String {
        let duration = Duration.seconds(timeInterval)
        return duration.formatted(.time(pattern: .hourMinuteSecond))
    }

    // "00:00" below an hour, scaling to "H:MM:SS" once the session crosses 60 minutes.
    private func formattedElapsed(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return hours > 0
        ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
        : String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // base gradient
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.35),
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.35),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // “radial” highlight on the right side
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.35),
                    Color.clear,
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
                timerAndControlsSection

                Spacer()

                focusSliderSection  //complex and fucked

                connectionRow

                horizontalContentScrollRow
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
                //.check if above modifier is needed or not

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .onAppear {
            focusSliderValue = 0
        }

        // Presented modally (not pushed) so the tab bar is never toggled — see PureFocusView
        // for why: toggling it via .toolbar(.hidden, for: .tabBar) on a pushed view caused
        // a layout snap when popping back, since the tab bar's own reveal animation runs
        // independently of the push/pop transition.
        .fullScreenCover(isPresented: $pureFocusViewState) {
            NavigationStack {
                PureFocusView(isPresented: $pureFocusViewState)
            }
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
                    isEnabled: !currentStudySessionInProgress,
                    selectedSubject: $vm.selectedSubject
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
        Group {
            if vm.hasAlreadyStudiedToday() {
                HStack {
                    Text("Time spent studying today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("<- 00:00:00")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.primary)
                }
            } else {
                EmptyView()
            }
        }
    }

    private var connectionRow: some View {
        //UITWEAK
        // Wrapping the online-friends indicator in a glass capsule gives it depth and
        // makes it look like a live status chip — similar to AirPods/Dynamic Island pills.
        HStack(spacing: 6) {
            Text("\(onlineFriendCount) online friends")
                .font(.caption)

            Image(systemName: "dot.radiowaves.up.forward")
                .font(.subheadline)
                .symbolEffect(
                    .variableColor.iterative.dimInactiveLayers.nonReversing,
                    options: .repeat(.periodic(delay: 4.0))
                )
                .foregroundColor(.green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect()
        //UIEND
    }

    private var timerAndControlsSection: some View {
    
        //if there is an active session, skip the 'empty/daily' section
        VStack(spacing: 24) {
            VStack {
                Group {
                    switch vm.currentSessionState {
                    case .noSession:
                        Text("--:--")
                    case .sessionPaused(let timestamp): //parses lastPausedAt
                        ElapsedTimerText(anchor: timestamp)
                    case .sessionRunning(let timestamp): //parses start anchor
                        ElapsedTimerText(anchor: timestamp) //needs to be a timeInterval
                    }
                }
                .font(
                    .system(
                        size: 90,
                        weight: .semibold,
                        design: .monospaced
                    )
                )
            }
            .padding(.top, 8)

            Spacer()

            //MARK: Section Length / Buttons
            ZStack {
                HStack {
                    HStack {  //child hstack1, aligned to be right-most within the available space
                        // "Pause at" text: fades in and slides from left when paused
                        VStack(spacing: 4) {
                            if vm.activeSession != nil {
                                if vm.ssw?.stopwatchIsRunning ?? false {  //

                                    Text(
                                        "temp"
                                    )  //parse through a helper; format the timeinterval as hour/minute/second
                                    .font(.headline.monospacedDigit())
                                    .frame(alignment: .center)

                                    Text("since last break")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(alignment: .center)

                                } else {  //if we're paused

                                    Text(
                                        "temp"
                                    )  //parse through a helper; format the timeinterval as hour/minute/second
                                    .font(.headline.monospacedDigit())
                                    .frame(alignment: .center)

                                    Text("Break Length")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(alignment: .center)

                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 20)

                    HStack {  //child hstack2, aligned to be left-most within the available space
                        Button {
                            if vm.activeSession == nil {
                                //No session in progress.
                                print("launching session")
                                vm.startSession()  //start session, and then
                            } else {  //we have an active session, so this button should either be 'pause', or split into two sub-buttons.
                                //We currently have a session underway
                                if vm.ssw?.stopwatchIsRunning ?? false {  //pause
                                    //The session is current in progress, so we pause
                                    vm.pauseSession()
                                    print("pausing session")
                                } else {  //not running
                                    //The session is not in progress, so we resume.
                                    vm.resumeSession()
                                    print("resuming")
                                }
                            }
                        } label: {
                            if vm.activeSession == nil {
                                //No session in progress.
                                Text("Start ")  //start session, and then
                            } else {
                                //We currently have a session underway
                                if vm.ssw?.stopwatchIsRunning ?? false {  //session in progress
                                    //The session is current and in progress, so we pause
                                    Text("inprog: pause?")
                                } else {  //not running
                                    //The session is not in progress, so we resume.
                                    Text("inprog: start?")
                                }
                            }

                            //                            Text(vm.activeSession == nil ? "Start" : "Pause")
                            //                                .id(vm.sessionIsRunning)
                            //                                .transition(
                            //                                    .push(from: .bottom)
                            //                                        .combined(with: .blurReplace)
                            //                                )
                            //                                .animation(.smooth(duration: 1), value: vm.sessionIsRunning)
                            //                                .frame(height: 22)
                            //                                .clipped()
                        }
                        .buttonStyle(.glass)
                        .frame(
                            height: 20
                        )  // keeps layout from jumping during the transition
                        .font(.headline)
                        .padding(
                            .horizontal,
                            10
                        )  //padding for start button, makes button wider than text
                        .padding(.vertical, 12)
                        //                        .frame(maxWidth: .infinity)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )  //align to left

                    //Liquid glass morph this later
                    Button {
                        print("end session button")
                    } label: {
                        if vm.activeSession != nil && !(vm.ssw?.stopwatchIsRunning ?? false) {
                            Text("end")
                        }
                    }
                    .buttonStyle(.glass)
                    .frame(
                        height: 20
                    )  // keeps layout from jumping during the transition
                    .font(.headline)
                    .padding(
                        .horizontal,
                        10
                    )  //padding for start button, makes button wider than text
                    .padding(.vertical, 12)

                }
                //            .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 4)
        }
    }

    // Drag-to-commit slider: dragging past 90% sets `pureFocusViewState = true`,
    // which triggers the fullScreenCover presenting PureFocusView (see body above).
    private var focusSliderSection: some View {
        FocusIntensitySlider(
            sliderProgress: $focusSliderValue,
            range: 0...100,
            complete: $pureFocusViewState,
            sliderDraggableElementWidth: $sliderDraggableElementWidth,
            sliderDraggableElementHeight: $sliderDraggableElementHeight
        )
        .frame(height: 40)
        .accessibilityLabel("Focus intensity")
        .padding(.vertical, 14)
        .padding(.horizontal, 5)
        .onChange(of: pureFocusViewState) { old, new in  // this is a t/f
            if old && !new {
                focusSliderValue = 0
            }
        }
    }

    public var horizontalContentScrollRow: some View {
        HorizontalContentScrollRow()
    }

}

// MARK: - Preview

#Preview {
    StudyTrackingView()
}
