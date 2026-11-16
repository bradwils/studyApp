//  StrataTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Strata's tracking page. Transparent; the stack shows through below the buttons.

import SwiftUI

struct StrataTrackingPage: View {

    let session: FocusLabSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            status
                .padding(.top, 4)
            buttons
                .padding(.top, 20)
            Spacer(minLength: 0)
            footer
                .padding(.bottom, 16)
        }
        .padding(.horizontal, StrataLayout.contentX)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Status

    private var status: some View {
        Text(statusText)
            .font(StrataFont.sans(13, .regular))
            .foregroundStyle(StrataPalette.smoke)
    }

    private var statusText: String {
        switch session.phase {
        case .idle:
            guard let length = session.lastCompletedLength else { return "Nothing laid down yet" }
            let minutes: Int = max(1, Int((length / 60).rounded()))
            return "Saved \(minutes) min"
        case .running:
            return runningText
        case .paused:
            return "On a break"
        }
    }

    private var runningText: String {
        let count: Int = session.breakCount
        if count == 0 { return "Studying" }
        if count == 1 { return "Studying, 1 break" }
        return "Studying, \(count) breaks"
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
                StrataPrimaryLabel(title: primaryTitle)
            }
            .buttonStyle(StrataPressStyle())

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                } label: {
                    StrataOutlineLabel(title: "End session")
                }
                .buttonStyle(StrataPressStyle())
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            footerRow(total: session.todayTotal(at: context.date))
        }
    }

    private var friendsText: String {
        let count: Int = session.friends.count
        return count == 1 ? "1 friend here" : "\(count) friends here"
    }

    private func footerRow(total: TimeInterval) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Today")
                .font(StrataFont.sans(13, .regular))
                .foregroundStyle(StrataPalette.smoke)
            Text(StrataFormat.duration(total))
                .font(StrataFont.sans(15, .medium))
                .foregroundStyle(StrataPalette.ink)
            Spacer(minLength: 12)
            Text(friendsText)
                .font(StrataFont.sans(15, .regular))
                .foregroundStyle(StrataPalette.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(StrataPalette.seam, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StrataTrackingHeader: View {

    let session: FocusLabSession

    var body: some View {
        subjectHeader
            .padding(.horizontal, StrataLayout.contentX)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var subjectHeader: some View {
        if session.hasSession {
            Text(session.selectedSubject.name)
                .font(StrataFont.sans(20, .semibold))
                .foregroundStyle(StrataPalette.ink)
                .frame(minHeight: 44, alignment: .leading)
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
                .font(StrataFont.sans(20, .semibold))
                .foregroundStyle(StrataPalette.ink)
            Image(systemName: "chevron.down")
                .font(StrataFont.sans(12, .semibold))
                .foregroundStyle(StrataPalette.smoke)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}
