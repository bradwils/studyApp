//  LampTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Lamp's tracking page. Transparent; the timer slot is left empty.

import SwiftUI

struct LampTrackingPage: View {

    let session: FocusLabSession
    let slotHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: LampLayout.headerHeight, alignment: .top)
            Color.clear
                .frame(height: slotHeight)
                .padding(.top, LampLayout.slotGap)
            status
                .padding(.top, 8)
            buttons
                .padding(.top, 28)
            Spacer(minLength: 0)
            footer
                .padding(.bottom, 24)
        }
        .padding(.horizontal, LampLayout.sidePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            subjectName
                .frame(minHeight: 44)
            Text(session.selectedSubject.code)
                .font(LampFont.regular(15))
                .foregroundStyle(LampPalette.ash)
        }
    }

    @ViewBuilder
    private var subjectName: some View {
        if session.hasSession {
            nameText
        } else {
            Menu {
                ForEach(session.subjects) { subject in
                    Button(subject.name) { session.selectedSubject = subject }
                }
            } label: {
                HStack(spacing: 6) {
                    nameText
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LampPalette.ash)
                }
                .contentShape(Rectangle())
            }
        }
    }

    private var nameText: some View {
        Text(session.selectedSubject.name)
            .font(LampFont.bold(20))
            .foregroundStyle(LampPalette.parchment)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    // MARK: - Status

    private var status: some View {
        Text(statusText)
            .font(LampFont.regular(15))
            .foregroundStyle(LampPalette.ash)
            .multilineTextAlignment(.center)
    }

    private var statusText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Lamp's on. Start when you're ready" }
            let minutes: Int = max(1, Int((length / 60).rounded()))
            return "Saved \(minutes) min"
        case .running:
            return "Studying"
        case .paused:
            return "On a break"
        }
    }

    // MARK: - Buttons

    private var primaryTitle: String {
        switch session.phase {
        case .idle: return "Start session"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.smooth(duration: 0.4)) { session.toggle() }
            } label: {
                LampPill(title: primaryTitle, fill: LampPalette.ember, textColor: LampPalette.night)
            }
            .buttonStyle(LampPressStyle())

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                } label: {
                    LampPill(title: "End session", fill: LampPalette.umber, textColor: LampPalette.parchment)
                }
                .buttonStyle(LampPressStyle())
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(alignment: .top, spacing: 0) {
                footerColumn("Today", todayText(at: context.date))
                footerColumn("Breaks", "\(breakCount)")
                footerColumn("Friends", "\(session.friends.count) studying")
            }
        }
    }

    private func footerColumn(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(LampFont.regular(15))
                .foregroundStyle(LampPalette.ash)
            Text(value)
                .font(LampFont.regular(18))
                .foregroundStyle(LampPalette.parchment)
        }
        .frame(maxWidth: .infinity)
    }

    private var breakCount: Int {
        session.breakCount + (session.isPaused ? 1 : 0)
    }

    private func todayText(at date: Date) -> String {
        let totalMinutes: Int = Int(session.todayTotal(at: date) / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        if hours == 0 { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }
}
