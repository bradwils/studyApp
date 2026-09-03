//  PureFocusView.swift
//  studyApp
//
//  Created by brad wils on 15/12/25.

import SwiftUI
import SwiftData
import UIKit

// The focus page of FocusSessionScreen's pager. Transparent and timer-less: the
// container draws the gradient and the pinned timer, and `PinnedTimerSlot` is the
// gap this page leaves for it.
//need to use white UI elements exclusively.
struct FocusPageContent: View {

    let vm: StudyTrackingViewModel

    @Environment(\.modelContext) private var modelContext

    // MARK: - Target Duration

    @State private var isEditingTarget = false
    @State private var draftTarget: TimeInterval = 0

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
            CustomBottomSheet()
        }
        .toolbar(vm.focusLockEnabled ? .hidden : .visible, for: .tabBar)
        .onChange(of: vm.focusLockEnabled) { _, locked in
            // A freshly engaged lock gets a fresh set of confirmation taps.
            if locked {
                unlockTapCount = 0
            }
        }
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

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                //UITWEAK
                // .buttonStyle(.glass) is an iOS 26 style that provides the system glass
                // appearance + the interactive press highlight for free. We no longer need
                // to manually manage foreground/background colors or pressed states.
                // Start/Pause button
                Button(action: {
                    performMainAction()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: mainButtonSymbol)

                        Text(mainButtonLabel)
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                //UIEND

                //lock button: PAID FEATURE
                Button(action: {
                    handleLockTap()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: vm.focusLockEnabled ? "lock.fill" : "lock.open.fill")
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .offUp.byLayer), options: .nonRepeating))

                        Text(vm.focusLockEnabled ? "Unlock" : "Lock")
                    }
                }
                .buttonStyle(.glass)
                .modifier(ShakeEffect(animatableData: unlockShakeTrigger))

                //UITWEAK
                // Reset button (only show when a target exists) — drops the target only,
                // the session itself keeps running.
                // Uses the same .glass style so it visually matches the other controls.
                if vm.targetDuration != nil {
                    Button(action: {
                        withAnimation {
                            vm.clearTarget()
                            isEditingTarget = false
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
        if vm.targetDuration == nil && !isEditingTarget {
            Button("Set target") {
                isEditingTarget = true
            }
            .buttonStyle(.glass)
        } else {
            VStack(spacing: 8) {
                durationPicker

                if vm.targetDuration != draftTarget {
                    Button("Set") {
                        vm.setTarget(draftTarget)
                        isEditingTarget = false
                    }
                    .buttonStyle(.glass)
                }
            }
        }
    }

    private var durationPicker: some View {
        @Bindable var vm = vm
        return DurationPicker(duration: $draftTarget, minHours: $vm.minHours, maxHours: $vm.maxHours, minMinutes: $vm.minMinutes, maxMinutes: $vm.maxMinutes)
    }

    private var topScreenCode: some View {
        Text(vm.selectedSubject?.code ?? "—")
            .font(.system(size: 35))
            .lineLimit(1)
    }
}


#Preview {
    FocusPageContent(vm: StudyTrackingViewModel())
        .modelContainer(for: Subject.self, inMemory: true)
}
