//  MarginTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Margin's tracking page. Transparent; the timer slot is left empty.

import SwiftUI

struct MarginTrackingPage: View {

    let session: FocusLabSession
    let slotHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .frame(height: MarginLayout.headerHeight, alignment: .topLeading)
            Color.clear
                .frame(height: slotHeight)
                .padding(.top, 24)
            caption
                .padding(.top, 10)
            ledger
                .padding(.top, 32)
            buttons
                .padding(.top, 36)
            Spacer(minLength: 0)
        }
        .padding(.top, MarginLayout.topInset)
        .padding(.leading, MarginLayout.contentX)
        .padding(.trailing, MarginLayout.trailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            subjectName
                .frame(minHeight: 44, alignment: .leading)
            Text(session.selectedSubject.code)
                .font(MarginFont.sans(13, .regular))
                .foregroundStyle(MarginPalette.graphite)
        }
    }

    @ViewBuilder
    private var subjectName: some View {
        if session.hasSession {
            nameLabel
        } else {
            Menu {
                ForEach(session.subjects) { subject in
                    Button(subject.name) { session.selectedSubject = subject }
                }
            } label: {
                nameLabel
            }
        }
    }

    private var nameLabel: some View {
        HStack(spacing: 6) {
            Text(session.selectedSubject.name)
                .font(MarginFont.serif(24, .medium))
                .foregroundStyle(MarginPalette.ink)
            if !session.hasSession {
                Image(systemName: "chevron.down")
                    .font(MarginFont.sans(13, .semibold))
                    .foregroundStyle(MarginPalette.graphite)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Caption

    private var caption: some View {
        Text(captionText)
            .font(MarginFont.sans(13, .regular))
            .foregroundStyle(MarginPalette.graphite)
    }

    private var captionText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Not started" }
            let minutes: Int = max(1, Int((length / 60).rounded()))
            return "Saved \(minutes) min"
        case .running:
            return "Studying since \(clockTime(session.startedAt))"
        case .paused:
            return "On a break since \(clockTime(session.pausedAt))"
        }
    }

    private func clockTime(_ date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Ledger

    private var ledger: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(alignment: .leading, spacing: 0) {
                ledgerRow("Today", longDuration(session.todayTotal(at: context.date)))
                ledgerRow("Breaks", breaksText(at: context.date))
                ledgerRow("Also here", sentence(session.friends.map { $0.name }))
            }
        }
    }

    private func ledgerRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(label)
                .font(MarginFont.sans(15, .regular))
                .foregroundStyle(MarginPalette.graphite)
                .frame(width: MarginLayout.labelWidth, alignment: .leading)
            Text(value)
                .font(MarginFont.sans(15, .medium))
                .foregroundStyle(MarginPalette.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
    }

    private func longDuration(_ interval: TimeInterval) -> String {
        let totalMinutes: Int = Int(interval / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        if hours == 0 { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }

    private func breaksText(at date: Date) -> String {
        guard session.hasSession else { return "None yet" }
        let count: Int = session.breakCount + (session.isPaused ? 1 : 0)
        guard count > 0 else { return "None yet" }
        let minutes: Int = Int(session.breakTime(at: date) / 60)
        return "\(count), \(minutes) min in total"
    }

    private func sentence(_ names: [String]) -> String {
        guard let last = names.last else { return "No one yet" }
        if names.count == 1 { return last }
        let head: String = names.dropLast().joined(separator: ", ")
        return "\(head) and \(last)"
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
        HStack(spacing: 20) {
            Button {
                withAnimation(.smooth(duration: 0.4)) { session.toggle() }
            } label: {
                Text(primaryTitle)
                    .font(MarginFont.sans(16, .medium))
                    .foregroundStyle(MarginPalette.paper)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .frame(minHeight: 46)
                    .background(MarginPalette.ink, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(MarginPressStyle())

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                } label: {
                    Text("End session")
                        .font(MarginFont.sans(16, .regular))
                        .underline()
                        .foregroundStyle(MarginPalette.ink)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(MarginPressStyle())
            }
        }
    }
}
