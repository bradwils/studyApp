//  DialTrackingPage.swift
//  studyApp
//
//  DEV ONLY — Dial's tracking page. Transparent; the ring slot is left empty.

import SwiftUI

struct DialTrackingPage: View {

    let session: FocusLabSession
    let ringDiameter: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: DialLayout.headerHeight, alignment: .top)
                .padding(.horizontal, DialLayout.sidePadding)
            slot
            buttons
                .padding(.top, 20)
            friendsSection
                .padding(.top, 28)
                .padding(.horizontal, DialLayout.sidePadding)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var slot: some View {
        let side: CGFloat = DialLayout.slotSide(diameter: ringDiameter)
        return Color.clear
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity)
            .padding(.top, DialLayout.slotTop)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                subjectName
                    .frame(minHeight: 44, alignment: .leading)
                Text(session.selectedSubject.code)
                    .font(DialFont.text(13, .regular))
                    .foregroundStyle(DialPalette.tick)
            }
            Spacer(minLength: 0)
            todayColumn
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
                .font(DialFont.text(17, .semibold))
                .foregroundStyle(DialPalette.ink)
                .lineLimit(1)
            if !session.hasSession {
                Image(systemName: "chevron.down")
                    .font(DialFont.text(11, .semibold))
                    .foregroundStyle(DialPalette.tick)
            }
        }
        .contentShape(Rectangle())
    }

    private var todayColumn: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(alignment: .trailing, spacing: 2) {
                Text("Today")
                    .font(DialFont.text(13, .regular))
                    .foregroundStyle(DialPalette.tick)
                Text(dialDuration(session.todayTotal(at: context.date)))
                    .font(DialFont.text(17, .medium))
                    .monospacedDigit()
                    .foregroundStyle(DialPalette.ink)
                    .lineLimit(1)
            }
            .frame(minHeight: 44, alignment: .top)
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
                Text(primaryTitle)
                    .font(DialFont.text(17, .medium))
                    .foregroundStyle(DialPalette.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .frame(minHeight: 48)
                    .background(DialPalette.cobalt, in: Capsule())
            }
            .buttonStyle(DialPressStyle())

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
                .font(DialFont.text(17, .medium))
                .foregroundStyle(DialPalette.ink)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .overlay {
                    Capsule().stroke(DialPalette.ink.opacity(0.25), lineWidth: 1)
                }
        }
        .buttonStyle(DialPressStyle())
    }

    // MARK: - Friends

    private var friendsTitle: String {
        let count: Int = session.friends.count
        return count == 1 ? "1 friend studying" : "\(count) friends studying"
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(friendsTitle)
                .font(DialFont.text(13, .regular))
                .foregroundStyle(DialPalette.tick)
            HStack(alignment: .top, spacing: 8) {
                ForEach(session.friends) { friend in
                    friendCell(friend)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func friendCell(_ friend: FocusLabSession.LabFriend) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(friend.name)
                .font(DialFont.text(15, .medium))
                .foregroundStyle(DialPalette.ink)
                .lineLimit(1)
            Text("\(friend.minutes) min")
                .font(DialFont.text(13, .regular))
                .foregroundStyle(DialPalette.tick)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
