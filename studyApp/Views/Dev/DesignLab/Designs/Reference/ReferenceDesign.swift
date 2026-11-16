//  ReferenceDesign.swift
//  studyApp
//
//  DEV ONLY — the current FocusSessionScreen rebuilt on the lab kit, as a baseline to
//  compare the other designs against.

import SwiftUI

struct ReferenceDesign: View {

    let session: FocusLabSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageOffset: CGFloat = 0
    @State private var page: Int? = 0

    @ScaledMetric(relativeTo: .largeTitle) private var timerSize: CGFloat = 84
    @ScaledMetric(relativeTo: .largeTitle) private var timerSlotHeight: CGFloat = 120

    private let headerHeight: CGFloat = 96

    // Reduce Motion snaps to the destination instead of travelling with the drag.
    private var blend: CGFloat {
        guard !reduceMotion else { return pageOffset < 0.5 ? 0 : 1 }
        return pageOffset
    }

    var body: some View {
        ZStack {
            background
            pinnedTimer
            FocusLabPager(
                pageOffset: $pageOffset,
                page: $page,
                showsFocusPage: session.hasSession,
                isLocked: session.isLocked
            ) {
                trackingPage
            } focus: {
                focusPage
            }
        }
    }

    // MARK: - Fixed layers

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink.opacity(0.35), Color.blue.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(1 - blend)

            LinearGradient(
                colors: [Color.black, Color.purple.opacity(0.9), Color.black.opacity(0.7)],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .opacity(blend)
        }
        .ignoresSafeArea()
    }

    private var pinnedTimer: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: headerHeight)

            FocusLabClock(session: session, idleText: "--:--")
                .font(.system(size: timerSize, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.primary.labBlend(.white, blend))
                .frame(height: timerSlotHeight)

            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Tracking page

    private var trackingPage: some View {
        VStack(spacing: 0) {
            trackingHeader
                .frame(height: headerHeight)

            Color.clear.frame(height: timerSlotHeight)

            VStack(spacing: 20) {
                sessionButtons

                Text("\(session.friends.count) friends studying now")
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .glassEffect()

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal)
    }

    private var trackingHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Current subject")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(session.subjects) { subject in
                        Button(subject.name) { session.selectedSubject = subject }
                    }
                } label: {
                    Text(session.selectedSubject.name)
                        .font(.body.weight(.medium))
                }
                .disabled(session.hasSession)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(formattedElapsed(session.todayTotal(at: context.date)))
                        .font(.title3.monospacedDigit().weight(.medium))
                }
            }
        }
    }

    private var mainButtonTitle: String {
        switch session.phase {
        case .idle: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var sessionButtons: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.smooth(duration: 0.4)) { session.toggle() }
            } label: {
                Text(mainButtonTitle)
                    .padding(.horizontal)
            }
            .buttonStyle(.glassProminent)

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                } label: {
                    Text("End session")
                        .padding(.horizontal)
                }
                .buttonStyle(.glass)
            }
        }
    }

    // MARK: - Focus page

    private var focusPage: some View {
        VStack(spacing: 0) {
            Text(session.selectedSubject.code)
                .font(.system(size: 35))
                .foregroundStyle(.white)
                .frame(height: headerHeight)

            Color.clear.frame(height: timerSlotHeight)

            VStack(spacing: 20) {
                if session.hasFocusBlock {
                    Button("End focus block") {
                        withAnimation(.smooth(duration: 0.35)) { session.clearFocusBlock() }
                    }
                    .buttonStyle(.glass)
                } else {
                    focusPresets

                    Button("Start focus block") {
                        withAnimation(.smooth(duration: 0.35)) { session.startFocusBlock() }
                    }
                    .buttonStyle(.glass)
                }

                Button(session.isLocked ? "Unlock" : "Lock screen") {
                    session.isLocked.toggle()
                }
                .buttonStyle(.glass)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 24)
    }

    private var focusPresets: some View {
        HStack(spacing: 8) {
            ForEach(FocusLabSession.focusPresets, id: \.self) { preset in
                let isSelected = session.focusDuration == preset
                Button {
                    session.focusDuration = preset
                } label: {
                    Text("\(Int(preset / 60))m")
                        .font(.subheadline.weight(isSelected ? .bold : .regular))
                        .foregroundStyle(.white.opacity(isSelected ? 1 : 0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
            }
        }
    }
}

#Preview {
    ReferenceDesign(session: FocusLabSession())
}
