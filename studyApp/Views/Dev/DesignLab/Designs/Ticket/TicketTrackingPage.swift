//  TicketTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Ticket's tracking page. Transparent: the paper, timer and caption are in the
//  fixed layers; this page lays the face's tap target and the stub facts over them.

import SwiftUI

struct TicketTrackingPage: View {

    let session: FocusLabSession
    let layout: TicketLayout
    let blend: CGFloat
    @Binding var page: Int?

    private var primaryTitle: String {
        switch session.phase {
        case .idle: return "Start session"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var startedText: String {
        guard let startedAt = session.startedAt else { return "Not yet" }
        return startedAt.formatted(date: .omitted, time: .shortened)
    }

    private var breakTotal: Int {
        session.breakCount + (session.isPaused ? 1 : 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: TicketLayout.headerHeight)
            ticketSlot
                .padding(.top, 16)
            buttons
                .padding(.top, 24)
            if session.hasSession {
                hint
                    .padding(.top, 16)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, TicketLayout.trackingSideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if session.hasSession {
            Text(session.selectedSubject.name)
                .font(TicketFont.bold(17))
                .foregroundStyle(TicketPalette.navy)
                .lineLimit(1)
        } else {
            subjectMenu
        }
    }

    private var subjectMenu: some View {
        Menu {
            ForEach(session.subjects) { subject in
                Button(subject.name) { session.selectedSubject = subject }
            }
        } label: {
            HStack(spacing: 6) {
                Text(session.selectedSubject.name)
                    .font(TicketFont.bold(17))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(TicketPalette.navy)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Ticket slot

    private var ticketSlot: some View {
        VStack(spacing: 0) {
            faceTapArea
                .frame(height: TicketLayout.trackingPerforationY)
            stubFacts
                .frame(height: TicketLayout.trackingStubHeight)
        }
        .frame(height: TicketLayout.trackingHeight)
    }

    private var faceTapArea: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { enterZenMode() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Enter zen mode")
            .accessibilityHidden(!session.hasSession)
    }

    private func enterZenMode() {
        guard session.hasSession else { return }
        withAnimation(.smooth(duration: 0.6)) { page = 1 }
    }

    private var stubFacts: some View {
        let fade: Double = Double(1 - FocusLabMath.window(blend, 0, 0.4))
        return HStack(spacing: 0) {
            fact(label: "Started", value: startedText)
            fact(label: "Breaks", value: "\(breakTotal)")
            fact(label: "Studying now", value: "\(session.friends.count) friends")
        }
        .padding(.horizontal, 22)
        .frame(maxHeight: .infinity)
        .opacity(fade)
    }

    private func fact(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(TicketFont.medium(13))
                .foregroundStyle(TicketPalette.mauve)
            Text(value)
                .font(TicketFont.medium(16))
                .foregroundStyle(TicketPalette.navy)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Buttons

    private var buttons: some View {
        HStack(spacing: 12) {
            TicketPrimaryButton(title: primaryTitle) {
                withAnimation(.smooth(duration: 0.45)) { session.toggle() }
            }
            if session.isPaused {
                TicketSecondaryButton(title: "End session") {
                    withAnimation(.smooth(duration: 0.45)) { session.end() }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: session.phase)
    }

    private var hint: some View {
        Text("Tap the ticket for zen mode")
            .font(TicketFont.medium(13))
            .foregroundStyle(TicketPalette.mauve)
    }
}
