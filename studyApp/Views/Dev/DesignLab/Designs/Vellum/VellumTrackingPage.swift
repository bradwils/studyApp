//  VellumTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Vellum's tracking page. Transparent; the tile slot is left empty and the buttons
//  sit on the fanned sheets.

import SwiftUI

struct VellumTrackingPage: View {

    let session: FocusLabSession
    let layout: VellumLayout

    var body: some View {
        VStack(spacing: 0) {
            subject
                .frame(maxWidth: .infinity)
                .frame(height: VellumLayout.headerHeight)
            Color.clear
                .frame(height: VellumLayout.slotGap)
            Color.clear
                .frame(width: layout.tile, height: layout.tile)
            caption
                .padding(.top, 12)
            Spacer(minLength: 0)
            buttons
            friendsLine
                .padding(.top, 16)
            Color.clear
                .frame(height: max(layout.height * 0.30 - 70, 20))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, VellumLayout.sidePadding)
    }

    // MARK: - Header

    @ViewBuilder
    private var subject: some View {
        if session.hasSession {
            Text(session.selectedSubject.name)
                .font(VellumFont.text(20, .semibold))
                .foregroundStyle(VellumPalette.ink)
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
                    .font(VellumFont.text(20, .semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(VellumFont.text(12, .semibold))
            }
            .foregroundStyle(VellumPalette.ink)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Caption

    private var caption: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(captionText(at: context.date))
                .font(VellumFont.text(14, .regular))
                .foregroundStyle(VellumPalette.dust)
        }
    }

    private func captionText(at date: Date) -> String {
        let totalMinutes: Int = Int(session.todayTotal(at: date) / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        let today: String = hours == 0 ? "\(minutes) min today" : "\(hours) h \(minutes) min today"
        let breaks: Int = session.breakCount + (session.isPaused ? 1 : 0)
        if breaks == 0 { return today }
        return breaks == 1 ? "\(today), 1 break" : "\(today), \(breaks) breaks"
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
                Text(primaryTitle)
                    .font(VellumFont.text(17, .semibold))
                    .foregroundStyle(VellumPalette.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .frame(minHeight: 48)
                    .background(VellumPalette.ink, in: Capsule())
            }
            .buttonStyle(VellumPressStyle())

            if session.isPaused {
                endButton
            }
        }
    }

    private var endButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.4)) { session.end() }
        } label: {
            Text("End session")
                .font(VellumFont.text(17, .semibold))
                .foregroundStyle(VellumPalette.ink)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background(VellumPalette.white, in: Capsule())
        }
        .buttonStyle(VellumPressStyle())
    }

    // MARK: - Friends

    private var friendsText: String {
        let names: [String] = session.friends.map { friend in friend.name }
        guard let last = names.last else { return "" }
        guard names.count > 1 else { return "\(last) is studying" }
        let lead: String = names.dropLast().joined(separator: ", ")
        return "\(lead) and \(last) are studying"
    }

    private var friendsLine: some View {
        Text(friendsText)
            .font(VellumFont.text(14, .regular))
            .foregroundStyle(VellumPalette.ink.opacity(0.8))
            .multilineTextAlignment(.center)
    }
}
