//  TapeTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Tape's tracking page. Transparent; the band slot is left empty.

import SwiftUI

struct TapeTrackingPage: View {

    let session: FocusLabSession
    let bandTop: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: bandTop, alignment: .top)
            Color.clear
                .frame(height: TapeLayout.bandHeight)
            bottom
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            subject
            caption
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var subject: some View {
        if session.hasSession {
            subjectLabel
        } else {
            Menu {
                ForEach(session.subjects) { option in
                    Button(option.name) { session.selectedSubject = option }
                }
            } label: {
                subjectLabel
            }
        }
    }

    private var subjectLabel: some View {
        HStack(spacing: 6) {
            Text(session.selectedSubject.name)
                .font(TapeFont.text(20, .semibold))
                .foregroundStyle(TapePalette.ink)
                .lineLimit(1)
            if !session.hasSession {
                Image(systemName: "chevron.down")
                    .font(TapeFont.text(12, .semibold))
                    .foregroundStyle(TapePalette.ink)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private var caption: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(captionText(at: context.date))
                .font(TapeFont.text(13, .regular))
                .foregroundStyle(TapePalette.haze)
                .lineLimit(1)
        }
    }

    private func captionText(at date: Date) -> String {
        let today: String = TapeFormat.duration(session.todayTotal(at: date))
        let breaks: Int = session.breakCount + (session.isPaused ? 1 : 0)
        if breaks == 0 { return "Today \(today)" }
        let noun: String = breaks == 1 ? "break" : "breaks"
        return "Today \(today), \(breaks) \(noun)"
    }

    // MARK: - Bottom

    private var bottom: some View {
        VStack(spacing: 0) {
            buttons
                .padding(.top, 24)
            friendsLine
                .padding(.top, 20)
            Spacer(minLength: 0)
            if session.hasSession {
                Text("Swipe up for focus")
                    .font(TapeFont.text(13, .regular))
                    .foregroundStyle(TapePalette.haze.opacity(0.7))
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var friendsLine: some View {
        let line: String = TapeFormat.friendsLine(session.friends)
        if !line.isEmpty {
            Text(line)
                .font(TapeFont.text(13, .regular))
                .foregroundStyle(TapePalette.haze)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

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
                pill(primaryTitle, textColor: TapePalette.tape, fill: TapePalette.ink)
            }
            .buttonStyle(TapePressStyle())

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.4)) { session.end() }
                } label: {
                    pill("End session", textColor: TapePalette.ink, fill: TapePalette.tape)
                }
                .buttonStyle(TapePressStyle())
            }
        }
    }

    private func pill(_ title: String, textColor: Color, fill: Color) -> some View {
        Text(title)
            .font(TapeFont.text(17, .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .frame(minHeight: 48)
            .background(fill, in: Capsule())
    }
}
