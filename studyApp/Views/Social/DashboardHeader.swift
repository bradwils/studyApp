//  DashboardHeader.swift
//  studyApp

import SwiftUI

// Summary banner above the friends feed: heading row with live-friends line
// and streak chip, plus a three-cell stats card.
struct DashboardHeader: View {

    var currentSessionTime: String
    var currentSubject: String
    var streakCount: Int
    var totalDailyTime: String
    var onlineFriends: Int

    private var friendsStatusText: String {
        switch onlineFriends {
        case 0: "No friends online right now"
        case 1: "1 friend studying now"
        default: "\(onlineFriends) friends studying now"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("Your Study Day")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: DS.Space.xs) {
                        Circle()
                            .fill(onlineFriends > 0 ? DS.Color.active : DS.Color.offline.opacity(0.4))
                            .frame(width: 7, height: 7)
                            .accessibilityHidden(true)
                        Text(friendsStatusText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                iconAndTextPill(text: "\(streakCount)", systemImage: "flame.fill", tint: DS.Color.streak)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(streakCount) day study streak")
            }

            // StatCell carries its own internal padding, so the group takes
            // surfaceCard directly with no extra padding of its own.
            HStack(spacing: 0) {
                StatCell(systemImage: "timer", tint: .indigo, label: "Session", value: currentSessionTime, alignment: .leading)
                Divider().padding(.vertical, DS.Space.s)
                StatCell(systemImage: "book.fill", tint: .indigo, label: "Subject", value: currentSubject, alignment: .center)
                Divider().padding(.vertical, DS.Space.s)
                StatCell(systemImage: "clock.fill", tint: .indigo, label: "Today", value: totalDailyTime, alignment: .trailing)
            }
            .surfaceCard()
        }
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        VStack(spacing: DS.Space.xl) {
            DashboardHeader(
                currentSessionTime: "01:22",
                currentSubject: "Mathematics",
                streakCount: 12,
                totalDailyTime: "03:41",
                onlineFriends: 3
            )
            DashboardHeader(
                currentSessionTime: "00:00",
                currentSubject: "Math",
                streakCount: 0,
                totalDailyTime: "00:00",
                onlineFriends: 0
            )
        }
        .padding(DS.Space.l)
    }
}
