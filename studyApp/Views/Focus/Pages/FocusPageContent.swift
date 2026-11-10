//  FocusPageContent.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.

import SwiftUI
import SwiftData

// The focus page of FocusSessionScreen's pager. Transparent and timer-less: the
// container draws the gradient and the pinned timer, and `FocusPageScaffold` leaves
// the gap for it.
//need to use white UI elements exclusively.
struct FocusPageContent: View {

    let vm: StudyTrackingViewModel

    let isLocked: Bool
    let onLockChange: (Bool) -> Void

	@State private var selectedDuration: TimeInterval = 0

    var body: some View {
        // TODO: CustomBottomSheet — in a wider orientation move it to the side and re-align PureFocusView (VStack vs HStack by horizontalSizeClass).
        FocusPageScaffold(horizontalPadding: 24) {
            topScreenCode
        } content: {
            VStack {
                timerControlsSection

                Spacer()
            }
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

                // Reset button (only show when a target exists) — drops the target only,
                // the session itself keeps running.
                // Uses the same .glass style so it visually matches the other controls.
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
                //UIEND
            }
            .padding(.top, 10)
        }
    }

    private var topScreenCode: some View {
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
    let state = FocusScreenState(pages: [.tracking, .focus])
    state.updatePosition(raw: 1)

    return ZStack {
        // FocusPageContent is deliberately transparent — FocusSessionScreen normally
        // paints this behind it. Without it the preview is just a blank white page.
        FocusBackgroundLayer(screenState: state, tracking: vm)

        FocusPageContent(vm: vm, isLocked: false, onLockChange: { _ in })
    }
    .modelContainer(container)
}
