//  FocusPageContent.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.

import SwiftUI
import SwiftData

// The focus page of FocusSessionScreen's pager. Transparent and timer-less: the
// container draws the gradient and the pinned timer, and `PinnedTimerSlot` is the
// gap this page leaves for it.
//need to use white UI elements exclusively.
struct FocusPageContent: View {

    let vm: StudyTrackingViewModel

    @Environment(\.modelContext) private var modelContext
	
	@State var selectedDuration: TimeInterval = 0

    // MARK: - Target Duration

    /// Natural height of the duration picker, captured once while it's laid out
    /// normally so the roll-up animation has a concrete value to collapse from.
    @State private var pickerNaturalHeight: CGFloat?

    // MARK: - Unlock Confirmation (shake-to-confirm)

    /// Taps required on the lock button, while locked, before focus lock releases.
    private let unlockTapsRequired = 10
    /// Minimum gap between taps that count — filters out accidental double-taps/mashing.
    private let unlockTapMinInterval: TimeInterval = 0.15

    @State private var unlockTapCount = 0
    @State private var lastUnlockTapAt: Date = .distantPast
    @State private var unlockShakeTrigger: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Spacing 0 above the slot for the same reason as the tracking page: the slot
            // must sit exactly headerSlotHeight down to meet the pinned timer layer.
            VStack(spacing: 0) {
                topScreenCode
                    .frame(height: FocusPagerLayout.headerSlotHeight)

                PinnedTimerSlot()

                VStack {
                    timerControlsSection

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)

			//THIS WILL BE CHANGED SO WHEN WE HAVE A WIDER ORIENTATION, MOVE THIS TO BE ON THE SIDE AND ADJUST PUREFOCUSVIEW ALIGNMENT TO MATCH. so, (simple) we'll vstack it instead of hstack depending on horizontalSizeClass
//            CustomBottomSheet()
        }
        .toolbar(vm.focusLockEnabled ? .hidden : .visible, for: .tabBar)
        .onChange(of: vm.focusLockEnabled) { _, locked in
            // A freshly engaged lock gets a fresh set of confirmation taps.
            if locked {
                unlockTapCount = 0
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: unlockShakeTrigger)
    }

    // MARK: - Unlock Confirmation

    /// Locking is a single tap; unlocking takes `unlockTapsRequired` deliberate taps,
    /// each acknowledged with a shake + haptic.
    private func handleLockTap() {
        guard vm.focusLockEnabled else {
            withAnimation(.easeInOut(duration: 0.5)) {
                vm.focusLockEnabled = true
            }
            return
        }

        let now = Date()
        guard now.timeIntervalSince(lastUnlockTapAt) >= unlockTapMinInterval else { return }
        lastUnlockTapAt = now

        unlockTapCount += 1
        guard unlockTapCount < unlockTapsRequired else {
            withAnimation(.easeInOut(duration: 0.5)) {
                vm.focusLockEnabled = false
            }
            return
        }

        withAnimation(.linear(duration: 0.25)) {
            unlockShakeTrigger += 1
        }
    }

    // MARK: - Session Controls

    private var mainButtonSymbol: String {
        if case .sessionRunning = vm.currentSessionState { return "pause.fill" }
        return "play.fill"
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

    private func performMainAction() {
        switch vm.currentSessionState {
        case .noSession:
            vm.startSession(ctx: modelContext)
        case .sessionPaused:
            vm.resumeSession()
        case .sessionRunning:
            vm.pauseSession()
        }
    }

    // MARK: - Subviews

    private var timerControlsSection: some View {
        VStack(spacing: 20) {
            targetSection

            HStack(spacing: 20) {

                //lock button: PAID FEATURE
                Button(action: {
                    handleLockTap()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: vm.focusLockEnabled ? "lock.fill" : "lock.open.fill")
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .offUp.byLayer), options: .nonRepeating))

                        Text(vm.focusLockEnabled ? "Unlock State" : "Lock State")
                    }
                }
                .buttonStyle(.glass)
                .modifier(ShakeEffect(animatableData: unlockShakeTrigger))

                // Reset button (only show when a target exists) — drops the target only,
                // the session itself keeps running.
                // Uses the same .glass style so it visually matches the other controls.
				if (vm.activePureFocusSession != nil) {
                    Button(action: {
                        withAnimation {
                            vm.closePureFocusSession()
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(14)
                    }
                    .buttonStyle(.glass)
                }
                //UIEND
            }
            .padding(.top, 10)
        }
    }

    @ViewBuilder
    private var targetSection: some View {

		VStack(spacing: 8) {
			durationPicker

			if !vm.isFocusSessionRunning {
				Button("Start Focus Session") {
					withAnimation(.easeInOut(duration: 0.35)) {
						vm.startPureFocusSession(selectedDuration)
					}
				}
				.buttonStyle(.glass)
			}
		}
    }

    private var durationPicker: some View {
        @Bindable var vm = vm
        return DurationPicker(duration: $selectedDuration, minHours: $vm.minHours, maxHours: $vm.maxHours, minMinutes: $vm.minMinutes, maxMinutes: $vm.maxMinutes)
            // Roll up like a sliding door: collapse to a measured-then-zero height instead
            // of fading, so the lock controls below rise into its place at the same rate
            // the picker retracts — both driven by the one VStack layout animation.
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                guard !vm.isFocusSessionRunning, height > 0 else { return }
                pickerNaturalHeight = height
            }
            .frame(height: vm.isFocusSessionRunning ? 0 : pickerNaturalHeight, alignment: .top)
            .clipped()
    }

    private var topScreenCode: some View {
        Text(vm.selectedSubject?.code ?? "—")
            .font(.system(size: 35))
            .lineLimit(1)
    }
}


#Preview {
    let vm = StudyTrackingViewModel()

    ZStack {
        // FocusPageContent is deliberately transparent — FocusSessionScreen normally
        // paints this behind it. Without it the preview is just a blank white page.
        TimerGradientBackground(progress: vm.pureFocusSessionProgress ?? 0, isTimerActive: vm.timerIsRunning)
            .ignoresSafeArea()

        FocusPageContent(vm: vm)
    }
    .modelContainer(for: Subject.self, inMemory: true)
}
