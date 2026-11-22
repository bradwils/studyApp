import SwiftUI
import SwiftData

// The tracking page of FocusSessionScreen's pager. Deliberately transparent and
// timer-less: FocusPagerScaffold draws the background and the pinned timer behind/over
// every page, and wraps this in a `FocusPageScaffold` under `TrackingPageHeader`.
struct TrackingPageContent: View {

    let vm: StudyTrackingViewModel

    // MARK: - Environment Properties

    @Environment(\.modelContext) private var modelContext

    // MARK: - State Properties

    @State var onlineFriendCount: Int = 0  //to be dynamic later

    // MARK: - Scaled Metrics

    @ScaledMetric(relativeTo: .caption) private var connectionChipVerticalPadding: CGFloat = 8

    var body: some View {
        VStack {
            controlsSection

            connectionRow

            Spacer()

            HorizontalContentScrollRow()
        }
        .padding(.bottom)
    }

    // MARK: - Sections

    private var connectionRow: some View {
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
            HStack(alignment: .center) {
                VStack {
                    if vm.hasActiveSession {
                        Text("temp")
                            .font(.headline.monospacedDigit())

                        Text(vm.phase == .running ? "since last break" : "Break Length")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(alignment: vm.phase == .paused ? .trailing : .center)
            }
            .padding(.horizontal)

            SessionControls(
                phase: vm.phase,
                onPrimary: performMainAction,
                onFinish: { vm.finishSession(context: modelContext) }
            )
        }
    }

}

// The tracking page's header band: the subject picker and today's total.
struct TrackingPageHeader: View {

    let vm: StudyTrackingViewModel

    var body: some View {
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
}

// MARK: - Preview

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    return FocusSessionScreen(vm: StudyTrackingViewModel())
        .modelContainer(container)
}
