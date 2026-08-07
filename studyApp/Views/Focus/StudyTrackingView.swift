import Combine
import SwiftUI
import SwiftData

/// Represents the display state of the lightweight study timer.
///
struct StudyTrackingView: View {
	
	//MARK: Environment Properties
	
	@Environment(\.modelContext) private var modelContext
	
	@Environment(\.horizontalSizeClass) var sizeClass //for later changes
	
	//MARK: Glass Namespaces
	@Namespace private var glassNamespace
	
	// MARK: - State Properties
	
	// Drives the PureFocusView fullScreenCover below — set to true by the slider
	// itself (via its `complete` binding) once the user drags it past the commit threshold.
	@State private var pureFocusViewState = false
	
	// Bound to FocusIntensitySlider's knob position (0...100); reset to 0 on appear and
	// again once the slider commits, so the tray is always empty when this view is shown.
	@State private var focusSliderValue: Double = 0
	@State var onlineFriendCount: Int = 0  //to be dynamic later
	@State private var isLeaderboardPresented: Bool = true
	@State private var currentStudySessionInProgress: Bool = false

	// MARK: - Scaled Metrics

	// The slider knob and the hero timer are proportioned by design rather than by
	// content, so they scale with Dynamic Type instead of sitting at fixed points.
	@ScaledMetric private var sliderKnobWidth: CGFloat = 90
	@ScaledMetric private var sliderKnobHeight: CGFloat = 60
	@ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 90
	@ScaledMetric(relativeTo: .caption) private var connectionChipVerticalPadding: CGFloat = 8

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
					Color.purple.opacity(0.35),
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.ignoresSafeArea()
			
			LinearGradient(
				colors: [
					Color.white.opacity(0.35),
					Color.blue.opacity(0.35),
				],
				startPoint: .topTrailing,
				endPoint: .bottomLeading
			)
			.ignoresSafeArea()
			
			VStack {
				headerRow
				timeSummaryRow
					.padding()

				timerAndControlsSection
				
				focusSliderSection  //complex and fucked
				
				connectionRow
				
				Spacer()
				
				horizontalContentScrollRow
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
			.padding()
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
				PureFocusView(isPresented: $pureFocusViewState, subject: vm.selectedSubject)
			}
		}
		
	}
	
	// MARK: - Sections
	
	private var headerRow: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Current Subject")
					.font(.caption)
					.foregroundColor(.secondary)
				
				ActiveSubjectList(
					isEnabled: !currentStudySessionInProgress,
					selectedSubject: $vm.selectedSubject
				)
			}
			
			Spacer()
			
			VStack(alignment: .trailing) {
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
		HStack {
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
		.padding(.horizontal)
		.padding(.vertical, connectionChipVerticalPadding)
		.glassEffect()

	}
	
	private var mainButtonLabel: String {
		switch vm.currentSessionState {
		case .noSession:
			return "Start"
		case .sessionPaused:
			return "Resume"
		case .sessionRunning:
			return "Pause"
		}
	}

	private var isSessionPaused: Bool {
		if case .sessionPaused = vm.currentSessionState { return true }
		return false
	}

	private var timerAndControlsSection: some View {

		//if there is an active session, skip the 'empty/daily' section
		VStack {
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
						size: timerFontSize,
						weight: .semibold,
						design: .monospaced
					)
				)
			}

			Spacer()
			
			//MARK: Section Length / Buttons
			ZStack {
				HStack {
					HStack {  //child hstack1, aligned to be right-most within the available space
						// "Pause at" text: fades in and slides from left when paused
						VStack {
							if vm.activeSession != nil {
								if vm.ssw?.stopwatchIsRunning ?? false {  //

									Text(
										"temp"
									)  //parse through a helper; format the timeinterval as hour/minute/second
									.font(.headline.monospacedDigit())

									Text("since last break")
										.font(.caption)
										.foregroundColor(.secondary)

								} else {

									Text(
										"temp"
									)  //parse through a helper; format the timeinterval as hour/minute/second
									.font(.headline.monospacedDigit())

									Text("Break Length")
										.font(.caption)
										.foregroundColor(.secondary)

								}
							}
						}
						.frame(maxWidth: .infinity, alignment: isSessionPaused ? .trailing : .center) //align to left when paused, right when running
					}
					.padding(.horizontal)

					HStack {  //child hstack2, aligned to be left-most within the available space
						GlassEffectContainer(spacing: 16) {
							// Both buttons sit directly next to each other (no stretching
							// spacer between them) so the container's fluid glass blend can
							// actually reach across the gap while the end button inserts/removes —
							// that adjacency is what sells the morph, not a manual transition.
							HStack(spacing: 16) {
								Button {
									withAnimation(.smooth(duration: 0.4)) {
										switch vm.currentSessionState {
										case .noSession:
											vm.startSession(ctx: modelContext)

										case .sessionPaused:
											print("resuming session")
											vm.resumeSession()

										case .sessionRunning: //parses start anchor
											print("pausing session")
											vm.pauseSession()

										}
									}
								} label: {
									// Sizing/font applied to the content BEFORE .buttonStyle(.glass),
									// with .glassEffectID chained immediately after it — that order is
									// what lets the container track this as the actual glass surface.
									Text(mainButtonLabel)
										.id(mainButtonLabel)
										.transition(.blurReplace)
										.font(.headline)
										.padding(.horizontal)  //padding for start button, makes button wider than text
								}
								.buttonStyle(.glass)
								.glassEffectID("startPauseButton", in: glassNamespace)

								if isSessionPaused {
									Button {
										vm.endSession(context: modelContext)
									} label: {
										Text("Endbutton")
											.font(.headline)
											.padding(.horizontal)  //padding for start button, makes button wider than text
									}
									.buttonStyle(.glass)
									.glassEffectID("endSessionButton", in: glassNamespace)
									// No manual `.transition` here — GlassEffectContainer +
									// matching glassEffectIDs already supplies the morph
									// transition on insert/remove; adding our own fights it.
								}
							}
							.frame(
								maxWidth: .infinity,
								alignment: .leading
							)  //align to left
						}
					}
				}
			}
		}
	}
	
	// Drag-to-commit slider: dragging past 90% sets `pureFocusViewState = true`,
	// which triggers the fullScreenCover presenting PureFocusView (see body above).
	private var focusSliderSection: some View {
		FocusIntensitySlider(
			sliderProgress: $focusSliderValue,
			range: 0...100,
			complete: $pureFocusViewState,
			sliderDraggableElementWidth: .constant(sliderKnobWidth),
			sliderDraggableElementHeight: .constant(sliderKnobHeight)
		)
		.accessibilityLabel("Focus intensity")
		.padding()
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
