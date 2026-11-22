//  FocusPageContent.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.

import SwiftUI
import SwiftData

// The focus page of FocusSessionScreen's pager. Transparent and timer-less:
// FocusPagerScaffold draws the gradient and the pinned timer, and wraps this in a
// `FocusPageScaffold` under `FocusPageHeader`.
struct FocusPageContent: View {

    let vm: StudyTrackingViewModel

    let isLocked: Bool
    let onLockChange: (Bool) -> Void

    @State private var selectedDuration: TimeInterval = 0

    var body: some View {
        // TODO: CustomBottomSheet — in a wider orientation move it to the side and re-align PureFocusView (VStack vs HStack by horizontalSizeClass).
        VStack {
            timerControlsSection

            Spacer()
        }
    }

    private var timerControlsSection: some View {
        VStack(spacing: 20) {
            FocusTargetControls(
                duration: $selectedDuration,
                hasTarget: vm.hasFocusTarget,
                canStart: FocusDurationLimits.standard.allows(selectedDuration) && vm.phase == .running,
                onStart: { vm.startFocusTarget(duration: selectedDuration) }
            )

            HStack(spacing: 20) {
                FocusLockControl(isLocked: isLocked, onLockChange: onLockChange)

                // Resetting the target leaves the study session running.
                if vm.hasFocusTarget {
                    Button(action: {
                        withAnimation {
                            vm.resetFocusTarget()
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(14)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Reset focus target")
                }
            }
            .padding(.top, 10)
        }
    }
}

// The focus page's header band: the subject code.
struct FocusPageHeader: View {

    let vm: StudyTrackingViewModel

    var body: some View {
        Text(vm.displayedSubjectCode ?? "—")
            .font(.system(size: 35))
            .lineLimit(1)
    }
}

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vm = StudyTrackingViewModel()
    vm.startSession(context: container.mainContext)
    vm.startFocusTarget(duration: 25 * 60)

    return FocusSessionScreen(vm: vm)
        .modelContainer(container)
}
