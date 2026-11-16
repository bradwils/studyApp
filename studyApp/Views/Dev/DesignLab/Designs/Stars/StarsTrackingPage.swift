//  StarsTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Stars' tracking page. Transparent; the status row under the timer is left empty.

import SwiftUI

struct StarsTrackingHeader: View {

    let session: FocusLabSession

    @ViewBuilder
    var body: some View {
        if session.hasSession {
            nameText
        } else {
            Menu {
                ForEach(session.subjects) { option in
                    Button(option.name) { session.selectedSubject = option }
                }
            } label: {
                HStack(spacing: 6) {
                    nameText
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(StarsPalette.haze)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
        }
    }

    private var nameText: some View {
        Text(session.selectedSubject.name)
            .font(StarsFont.heading(18))
            .foregroundStyle(StarsPalette.star)
            .lineLimit(1)
    }
}

struct StarsTrackingPage: View {

    let session: FocusLabSession

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: StarsLayout.statusRowHeight)
            buttons
                .padding(.top, 16)
            Spacer(minLength: 0)
            footer
                .padding(.bottom, 24)
        }
        .padding(.horizontal, StarsLayout.sidePadding)
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
                withAnimation(.smooth(duration: 0.5)) { session.toggle() }
            } label: {
                StarsPill(
                    title: primaryTitle,
                    textColor: StarsPalette.midnight,
                    fill: StarsPalette.starlight,
                    stroke: Color.clear
                )
            }
            .buttonStyle(StarsPressStyle())

            if session.isPaused {
                Button {
                    withAnimation(.smooth(duration: 0.5)) { session.end() }
                } label: {
                    StarsPill(
                        title: "End session",
                        textColor: StarsPalette.star,
                        fill: Color.clear,
                        stroke: StarsPalette.star.opacity(0.5)
                    )
                }
                .buttonStyle(StarsPressStyle())
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            footerLine(at: context.date)
        }
    }

    private func footerLine(at date: Date) -> some View {
        let today: String = StarsFormat.duration(session.todayTotal(at: date))
        let friends: Int = session.friends.count
        return HStack {
            Text("Today \(today)")
            Spacer(minLength: 12)
            Text("\(friends) friends up late")
        }
        .font(StarsFont.text(14))
        .foregroundStyle(StarsPalette.haze)
        .lineLimit(1)
    }
}
