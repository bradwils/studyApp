import SwiftUI
import SwiftData



//expecting many issues when merging this; check for dependencies, different expectations from elements when parsing/initialising, etc.
struct StudyTrackingView: View {

    // MARK: Environment Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Glass Namespaces

    @Namespace private var glassNamespace

    // MARK: - State Properties

    // Drives the PureFocusView fullScreenCover below — set to true by the slider
    // itself (via its `complete` binding) once the user drags it past the commit threshold.
    @State private var pureFocusViewState = false

    // Bound to FocusIntensitySlider's knob position (0...100); reset to 0 on appear and
    // again once the slider commits, so the tray is always empty when this view is shown.
    @State private var focusSliderValue: Double = 0

    // Mock — no data source yet; connectionRow stays hidden until this is wired.
    @State private var onlineFriendCount: Int = 0

    // MARK: - Scaled Metrics

    // The slider knob is proportioned by design rather than by content, so it
    // scales with Dynamic Type instead of sitting at fixed points.
    @ScaledMetric private var sliderKnobWidth: CGFloat = 90
    @ScaledMetric private var sliderKnobHeight: CGFloat = 60

    // MARK: - ViewModels

    @State private var vm = StudyTrackingViewModel()

    // Re-anchors the today query when the app lives across midnight.
    @State private var dayStart = Calendar.current.startOfDay(for: .now)

    var body: some View {
        ZStack {
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

            VStack(spacing: DS.Space.xl) {
                headerRow
                timerAndControlsSection
                focusSliderSection
                connectionRow
                Spacer(minLength: 0)
                HorizontalContentScrollRow()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(DS.Space.l)
        }
        .onAppear {
            focusSliderValue = 0
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                dayStart = Calendar.current.startOfDay(for: .now)
            }
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Current Subject")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ActiveSubjectList(
                    isEnabled: !vm.sessionIsRunning,
                    selectedSubject: $vm.selectedSubject
                )
            }

            Spacer(minLength: DS.Space.l)

            TodayTotalColumn(dayStart: dayStart)
        }
    }

    private var timerAndControlsSection: some View {
        VStack(spacing: DS.Space.l) {
            heroTimer
            sessionReadout
            controlCluster
        }
    }

    @ViewBuilder
    private var heroTimer: some View {
        switch vm.currentSessionState {
        case .noSession:
            PrimaryTimerText("--:--", accessibilityLabel: "No session running", baseSize: 90)
        case .sessionPaused(let pausedAt): //anchor is lastPausedAt: hero counts the break up
            AnchoredTimerText(anchor: pausedAt, spokenPrefix: "Break time")
        case .sessionRunning(let anchor): //anchor is the break-adjusted session start
            AnchoredTimerText(anchor: anchor, spokenPrefix: "Elapsed time")
        }
    }

    @ViewBuilder
    private var sessionReadout: some View {
        switch vm.currentSessionState {
        case .noSession:
            EmptyView()

        case .sessionRunning:
            // Until a break exists this would just duplicate the hero, so it only
            // appears once the session has actually had one.
            if let lastBreakEnd = vm.studyBreaks.last?.endedAt {
                VStack(spacing: DS.Space.xs) {
                    TimelineView(.periodic(from: lastBreakEnd, by: 1)) { context in
                        let elapsed = max(context.date.timeIntervalSince(lastBreakEnd), 0)
                        Text(formattedElapsed(elapsed))
                            .font(.headline)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.linear, value: Int(elapsed))
                            .accessibilityLabel(spokenDuration(elapsed))
                    }

                    Text("since last break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }

        case .sessionPaused:
            // Static while paused (the stopwatch anchor is frozen), so no TimelineView.
            if let studied = vm.ssw?.totalRunningTime, studied > 0 {
                VStack(spacing: DS.Space.xs) {
                    Text(formattedElapsed(studied))
                        .font(.headline)
                        .monospacedDigit()
                        .accessibilityLabel(spokenDuration(studied))

                    Text("studied before this break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var controlCluster: some View {
        GlassEffectContainer(spacing: DS.Space.l) {
            // Both buttons sit directly next to each other (no stretching
            // spacer between them) so the container's fluid glass blend can
            // actually reach across the gap while the end button inserts/removes —
            // that adjacency is what sells the morph, not a manual transition.
            HStack(spacing: DS.Space.l) {
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
                        .padding(.horizontal, DS.Space.l)
                }
                .buttonStyle(.glassProminent)
                .glassEffectID("startPauseButton", in: glassNamespace)
                .accessibilityIdentifier("startPauseButton")

                if isSessionPaused {
                    Button {
                        withMorphAnimation {
                            vm.endSession(context: modelContext)
                        }
                    } label: {
                        Text("End Session")
                            .font(.body)
                            .padding(.horizontal, DS.Space.l)
                    }
                    .buttonStyle(.glass)
                    .glassEffectID("endSessionButton", in: glassNamespace)
                    .accessibilityIdentifier("endSessionButton")
                    // No manual `.transition` here — GlassEffectContainer +
                    // matching glassEffectIDs already supplies the morph
                    // transition on insert/remove; adding our own fights it.
                }
            }
        }
    }

    @ViewBuilder
    private var connectionRow: some View {
        if onlineFriendCount > 0 {
            iconAndTextPill(
                text: onlineFriendCount == 1 ? "1 friend online" : "\(onlineFriendCount) friends online",
                systemImage: "dot.radiowaves.up.forward",
                tint: DS.Color.active,
                variant: .glass
            )
            .symbolEffect(
                .variableColor.iterative.dimInactiveLayers.nonReversing,
                options: .repeat(.periodic(delay: 4.0)),
                isActive: !reduceMotion
            )
        }
    }

    // Drag-to-commit slider: dragging past 90% sets `pureFocusViewState = true`,
    // which triggers the fullScreenCover presenting PureFocusView (see body above).
    private var focusSliderSection: some View {
        FocusIntensitySlider(
            sliderProgress: $focusSliderValue,
            range: 0...100,
            complete: $pureFocusViewState,
            knobWidth: sliderKnobWidth,
            knobHeight: sliderKnobHeight
        )
        .accessibilityLabel("Focus intensity")
        .onChange(of: pureFocusViewState) { old, new in
            if old && !new {
                focusSliderValue = 0
            }
        }
    }

    // MARK: - Helpers

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

    private func performMainAction() {
        withMorphAnimation {
            switch vm.currentSessionState {
            case .noSession:
                vm.startSession(ctx: modelContext)
            case .sessionPaused:
                vm.resumeSession()
            case .sessionRunning:
                vm.pauseSession()
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
}

// Owns its day-anchored query so a changed dayStart rebuilds the predicate
// (the parent refreshes it at midnight); only completed sessions count — the
// in-flight one is already on the hero timer.
private struct TodayTotalColumn: View {
    @Query private var todaySessions: [StudySession]

    init(dayStart: Date) {
        _todaySessions = Query(
            filter: #Predicate<StudySession> { $0.startedAt >= dayStart && $0.endedAt != nil }
        )
    }

    private var todayTotal: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.totalDuration }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: DS.Space.xs) {
            Text("Total")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formattedElapsed(todayTotal))
                .font(.title3.weight(.medium))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: todayTotal)
        }
        .redacted(reason: todayTotal == 0 ? .placeholder : [])
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            todayTotal == 0
                ? "No study time recorded today"
                : "Total studied today: \(spokenDuration(todayTotal))"
        )
    }
}

// Anchored TimelineView: ticks align with integer-second boundaries of the
// elapsed time instead of drifting with render time, rendered through
// PrimaryTimerText for the DS hero treatment.
private struct AnchoredTimerText: View {
    var anchor: Date
    var spokenPrefix: String

    var body: some View {
        TimelineView(.periodic(from: anchor, by: 1)) { context in
            let elapsed = max(context.date.timeIntervalSince(anchor), 0)
            PrimaryTimerText(
                formattedElapsed(elapsed),
                accessibilityLabel: "\(spokenPrefix) \(spokenDuration(elapsed))",
                baseSize: 90
            )
        }
    }
}

// VoiceOver-friendly rendering of a duration — the raw digit string reads poorly.
private func spokenDuration(_ interval: TimeInterval) -> String {
    Duration.seconds(interval).formatted(
        .units(allowed: [.hours, .minutes, .seconds], width: .wide, maximumUnitCount: 2)
    )
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StudyTrackingView()
    }
    .modelContainer(for: [StudySession.self, Subject.self], inMemory: true)
    .tint(.indigo)
}
