import SwiftUI
import SwiftData

// The tracking page of FocusSessionScreen's pager. Deliberately transparent and
// timer-less: the container draws the background and the pinned timer behind/over
// every page, and `PinnedTimerSlot` is the gap this page leaves for the timer.
struct TrackingPageContent: View {

	let vm: StudyTrackingViewModel

	//MARK: Environment Properties

	@Environment(\.modelContext) private var modelContext

	@Environment(\.horizontalSizeClass) var sizeClass //for later changes

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	//MARK: Glass Namespaces
	@Namespace private var glassNamespace

	// MARK: - State Properties

	@State var onlineFriendCount: Int = 0  //to be dynamic later

	// MARK: - Scaled Metrics

	@ScaledMetric(relativeTo: .caption) private var connectionChipVerticalPadding: CGFloat = 8

	var body: some View {
		// The header band and the timer slot are spacing-0 and top-inset-free so the slot
		// lands exactly headerSlotHeight down, matching FocusSessionScreen's pinned layer.
		// Everything below keeps natural spacing inside a nested stack.
		VStack(spacing: 0) {
			headerRow
				.frame(height: FocusPagerLayout.headerSlotHeight)

			PinnedTimerSlot()

			VStack {
				controlsSection

				connectionRow

				Spacer()

				horizontalContentScrollRow
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.padding(.horizontal)
		.padding(.bottom)
	}

	// MARK: - Sections

	private var headerRow: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Current Subject")
					.font(.caption)
					.foregroundColor(.secondary)

				if vm.hasActiveSession {
					Text(vm.activeSubjectName ?? "No subject")
						.font(.body)
				} else {
					ActiveSubjectList(
						isEnabled: vm.canSelectSubject,
						selectedSubject: Binding(
							get: { vm.selectedSubject },
							set: { vm.selectSubject($0) }
						)
					)
				}
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
		switch vm.phase {
		case .idle:
			return "Start"
		case .paused:
			return "Resume"
		case .running:
			return "Pause"
		}
	}

	private var isSessionPaused: Bool {
		vm.phase == .paused
	}

	private func performMainAction() {
		withMorphAnimation {
			switch vm.phase {
			case .idle:
				vm.startSession(context: modelContext)
			case .paused:
				vm.resumeSession(context: modelContext)
			case .running:
				vm.pauseSession(context: modelContext)
			}
		}
	}
		

	// Glass morph + label swap; skipped entirely under Reduce Motion.
	private func withMorphAnimation(_ changes: () -> Void) {
		if reduceMotion {
			changes()
		} else {
			withAnimation(.smooth(duration: 0.4)) {
				changes()
			}
		}
	}

	private var controlsSection: some View {
		VStack {
			//MARK: Section Length / Buttons
			HStack(alignment: .center) {
						// "Pause at" text: fades in and slides from left when paused
					VStack {
						if vm.hasActiveSession {
							if vm.phase == .running {

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
					.frame(alignment: isSessionPaused ? .trailing : .center) //align to left when paused, right when running
				}
				.padding(.horizontal)

				GlassEffectContainer(spacing: 16) {
					// Both buttons sit directly next to each other (no stretching
					// spacer between them) so the container's fluid glass blend can
					// actually reach across the gap while the end button inserts/removes —
					// that adjacency is what sells the morph, not a manual transition.
					HStack(spacing: 16) {
						Button {
							performMainAction()
						} label: {
							// Sizing/font applied to the content BEFORE the button style,
							// with .glassEffectID chained immediately after it — that order is
							// what lets the container track this as the actual glass surface.
							Text(mainButtonLabel)
								.id(mainButtonLabel)
								.transition(.blurReplace)
								.font(.body)
								.padding(.horizontal)  //padding for start button, makes button wider than text
						}
						.buttonStyle(.glassProminent)
						.glassEffectID("startPauseButton", in: glassNamespace)
						.accessibilityIdentifier("startPauseButton")

						if isSessionPaused {
							Button {
								withMorphAnimation {
									vm.finishSession(context: modelContext)
								}
							} label: {
								Text("End Session")
									.font(.body)
									.padding(.horizontal)  //padding for start button, makes button wider than text
							}
							.buttonStyle(.glass)
							.glassEffectID("endSessionButton", in: glassNamespace)
							.accessibilityIdentifier("endSessionButton")
						}
					}
				}
		}
	}

	public var horizontalContentScrollRow: some View {
		HorizontalContentScrollRow()
	}

}

// MARK: - Preview

#Preview {
	TrackingPageContent(vm: StudyTrackingViewModel())
		.modelContainer(
			for: [Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self],
			inMemory: true
		)
}
