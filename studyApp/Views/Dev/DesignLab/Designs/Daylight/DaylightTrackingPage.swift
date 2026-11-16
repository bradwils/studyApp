//  DaylightTrackingPage.swift
//  studyApp
//
//  DEV ONLY — the transparent tracking page of the Daylight design.

import SwiftUI

struct DaylightTrackingPage: View {
    let session: FocusLabSession
    let geometry: DaylightGeometry

    @ScaledMetric(relativeTo: .title3) private var nameSize: CGFloat = 20
    @ScaledMetric(relativeTo: .footnote) private var captionSize: CGFloat = 14

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: DaylightGeometry.headerHeight)

            Color.clear.frame(height: geometry.slotLeadHeight)
            Color.clear.frame(height: geometry.timerSlotHeight)

            statusLine
                .padding(.top, 6)

            controls
                .padding(.top, 24)

            Spacer(minLength: 0)

            friendsLine
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sensoryFeedback(.impact(weight: .light), trigger: session.phase)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if session.hasSession {
            subjectLabel
        } else {
            Menu {
                ForEach(session.subjects) { subject in
                    Button(subject.name) { session.selectedSubject = subject }
                }
            } label: {
                subjectLabel
            }
        }
    }

    private var subjectLabel: some View {
        HStack(spacing: 6) {
            Text(session.selectedSubject.name)
                .font(DaylightFont.name(nameSize))
            if !session.hasSession {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundStyle(DaylightPalette.plum)
        .frame(minHeight: 44)
    }

    // MARK: - Status

    private var statusLine: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(statusText(at: context.date))
                .font(DaylightFont.caption(captionSize))
                .foregroundStyle(DaylightPalette.plum.opacity(0.7))
        }
    }

    private func statusText(at date: Date) -> String {
        if session.isPaused { return "On a break" }
        if !session.hasSession, let saved = session.lastCompletedLength {
            return "Saved \(DaylightFormat.duration(saved)) today"
        }
        let today: String = DaylightFormat.duration(session.todayTotal(at: date))
        return "\(today) of 4 h today"
    }

    // MARK: - Controls

    private var primaryTitle: String {
        switch session.phase {
        case .idle: return "Start session"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            DaylightPill(title: primaryTitle, textColor: DaylightPalette.chalk, fill: DaylightPalette.plum) {
                withAnimation(.smooth(duration: 0.4)) { session.toggle() }
            }

            if session.isPaused {
                DaylightPill(title: "End session", textColor: DaylightPalette.plum, outline: DaylightPalette.plum) {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                }
            }
        }
    }

    // MARK: - Friends

    private var friendsText: String {
        let names: [String] = session.friends.map { $0.name }
        switch names.count {
        case 0:
            return ""
        case 1:
            return "\(names[0]) is studying"
        default:
            let head: String = names.dropLast().joined(separator: ", ")
            let tail: String = names[names.count - 1]
            return "\(head) and \(tail) are studying"
        }
    }

    private var friendsLine: some View {
        Text(friendsText)
            .font(DaylightFont.caption(captionSize))
            .foregroundStyle(DaylightPalette.plum.opacity(0.7))
            .multilineTextAlignment(.center)
    }
}
