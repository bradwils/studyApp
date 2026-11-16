//  PosterTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Poster's tracking page. Transparent; the timer slot is left empty.

import SwiftUI

struct PosterTrackingPage: View {

    let session: FocusLabSession
    let layout: PosterLayout
    let blend: CGFloat

    @ScaledMetric(relativeTo: .title) private var nameSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var captionSize: CGFloat = 15

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .frame(height: PosterLayout.headerHeight, alignment: .leading)
            lowerContent
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PosterLayout.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
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
        HStack(spacing: 8) {
            Text(session.selectedSubject.name)
                .font(PosterFont.heavy(nameSize))
                .foregroundStyle(PosterPalette.forest)
                .lineLimit(1)
            if !session.hasSession {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PosterPalette.leaf)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Below the header

    private var lowerContent: some View {
        let fade: Double = Double(1 - FocusLabMath.window(blend, 0, 0.5))
        return VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: PosterLayout.trackingTop - PosterLayout.headerHeight + layout.slotHeight)
            caption
                .padding(.top, 6)
            facts
                .padding(.top, 28)
            buttons
                .padding(.top, 28)
        }
        .opacity(fade)
        .allowsHitTesting(blend < 0.5)
    }

    private var caption: some View {
        Text(captionText)
            .font(PosterFont.label(captionSize))
            .foregroundStyle(PosterPalette.leaf)
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

    // MARK: - Facts

    private var facts: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let breaks: Int = session.breakCount + (session.isPaused ? 1 : 0)
            HStack(alignment: .top, spacing: 28) {
                PosterFact(label: "Today", value: todayText(at: context.date))
                PosterFact(label: "Breaks", value: "\(breaks)")
                PosterFact(label: "Here", value: "\(session.friends.count)")
            }
        }
    }

    private func todayText(at date: Date) -> String {
        let totalMinutes: Int = Int(session.todayTotal(at: date) / 60)
        let hours: Int = totalMinutes / 60
        let minutes: Int = totalMinutes % 60
        if hours == 0 { return "\(minutes) min" }
        return "\(hours) h \(minutes)"
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
            PosterPrimaryButton(title: primaryTitle) {
                withAnimation(.smooth(duration: 0.4)) { session.toggle() }
            }
            if session.isPaused {
                PosterLinkButton(title: "End session") {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                }
            }
        }
    }
}

private struct PosterFact: View {

    let label: String
    let value: String

    @ScaledMetric(relativeTo: .title2) private var valueSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var labelSize: CGFloat = 15

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(PosterFont.label(labelSize))
                .foregroundStyle(PosterPalette.leaf)
            Text(value)
                .font(PosterFont.heavy(valueSize))
                .foregroundStyle(PosterPalette.forest)
        }
    }
}
