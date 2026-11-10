import SwiftUI
import SwiftData

// The tracking page of FocusSessionScreen's pager. Deliberately transparent and
// timer-less: the container draws the background and the pinned timer behind/over
// every page, and `FocusPageScaffold` leaves the gap for the timer.
struct TrackingPageContent: View {

	let vm: StudyTrackingViewModel

	//MARK: Environment Properties

	@Environment(\.modelContext) private var modelContext

	@Environment(\.horizontalSizeClass) var sizeClass //for later changes

	// MARK: - State Properties

	@State var onlineFriendCount: Int = 0  //to be dynamic later

	// MARK: - Scaled Metrics

	@ScaledMetric(relativeTo: .caption) private var connectionChipVerticalPadding: CGFloat = 8

	var body: some View {
		FocusPageScaffold {
			headerRow
		} content: {
			VStack {
				controlsSection

				connectionRow

				Spacer()

				horizontalContentScrollRow
			}
		}
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

	private var isSessionPaused: Bool {
		vm.phase == .paused
	}

	private func performMainAction() {
		switch vm.phase {
		case .idle:
			vm.startSession(context: modelContext)
		case .paused:
			vm.resumeSession(context: modelContext)
		case .running:
			vm.pauseSession(context: modelContext)
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

				SessionControls(
					phase: vm.phase,
					onPrimary: performMainAction,
					onFinish: { vm.finishSession(context: modelContext) }
				)
		}
	}

	public var horizontalContentScrollRow: some View {
		HorizontalContentScrollRow()
	}

}

// MARK: - Preview

#Preview {
	// swiftlint:disable:next force_try
	let container = try! ModelContainer(
		for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
		configurations: ModelConfiguration(isStoredInMemoryOnly: true)
	)
	let vm = StudyTrackingViewModel()
	let state = FocusScreenState(pages: [.tracking])

	return ZStack {
		// The page is deliberately transparent; the shell normally paints this behind it.
		FocusBackgroundLayer(screenState: state, tracking: vm)

		TrackingPageContent(vm: vm)
	}
	.modelContainer(container)
}
