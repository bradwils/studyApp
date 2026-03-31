import SwiftUI

/// Represents the display state of the lightweight study timer.
struct StudyTrackingView: View {
    @StateObject private var vm = StudyTrackingViewModel()
    @StateObject private var userProfileStore = UserProfileStore.shared

    var body: some View {
        ZStack {
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
                mainTimerElement

                Spacer()
                    .frame(height: .infinity)

                pauseStopRow

                Spacer()
                    .frame(height: .infinity)

                focusSliderSection
                connectionRow
                horizontalContentScrollRow
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .onAppear {
            vm.configureSubjects(userProfileStore.profile.subjects)
        }
        .onChange(of: userProfileStore.profile.subjects) { _, newSubjects in
            vm.configureSubjects(newSubjects)
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Subject")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ActiveSubjectList(
                    subjects: userProfileStore.profile.subjects,
                    selection: subjectSelectionBinding,
                    isEnabled: !vm.currentStudySessionInProgress
                )
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(vm.totalStudyDurationText)
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

                    Text(vm.totalStudyDurationText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.primary)
                }
            } else {
                EmptyView()
            }
        }
    }

    private var mainTimerElement: some View {
        VStack(spacing: -20) {
            Text(vm.sessionDurationText)
                .font(.system(size: 100).monospacedDigit())
                .fontWeight(.semibold)

            Text("(total time spent studying this session)")
                .font(.caption)
        }
        .padding(.top, 8)
    }

    private var connectionRow: some View {
        HStack(spacing: 6) {
            Text("\(vm.onlineFriendCount) online friends")
                .font(.caption)

            Image(systemName: "dot.radiowaves.up.forward")
                .font(.subheadline)
                .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.periodic(delay: 4.0)))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect()
    }

    private var pauseStopRow: some View {
        HStack(spacing: 14) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(vm.breakMetricValueText)
                    .font(.headline.monospacedDigit())
                Text(vm.breakMetricTitleText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: 8) {
                Button(vm.currentStudySessionInProgress ? (vm.timerInProgress ? "Pause" : "Resume") : "Start") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                        vm.toggleSessionProgress()
                    }
                }
                .buttonStyle(.glass)
                .buttonSizing(.automatic)

                if vm.currentStudySessionInProgress {
                    Button("End") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                            vm.endCurrentSession()
                        }
                    }
                    .buttonStyle(.glass)
                    .buttonSizing(.automatic)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 4)
    }

    private var focusSliderSection: some View {
        FocusIntensitySlider(
            value: $vm.focusSliderValue,
            range: 0...100,
            sliderDraggableElementWidth: $vm.sliderDraggableElementWidth,
            sliderDraggableElementHeight: $vm.sliderDraggableElementHeight
        )
        .frame(height: 40)
        .accessibilityLabel("Focus intensity")
        .padding(.vertical, 14)
        .padding(.horizontal, 5)
    }

    private var horizontalContentScrollRow: some View {
        HorizontalContentScrollRow()
    }

    private var subjectSelectionBinding: Binding<Subject?> {
        Binding(
            get: { vm.selectedSubject },
            set: { vm.updateSubjectSelection($0) }
        )
    }
}

#Preview {
    NavigationStack {
        StudyTrackingView()
    }
}
