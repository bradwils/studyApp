//  DashboardHeader.swift
//  studyApp

import SwiftUI

//UITWEAK
// Redesigned DashboardHeader v2:
// - "Your Study Day" heading with streak badge inline at the top
// - Three equal-width stat cards (session time, subject, today total) with icons
// - Online-friends indicator stays as a minimal dot + text chip below the stats
// All glass effects applied without shape arguments per project convention.

/// Summary banner displayed above the friends feed.
struct DashboardHeader: View {
    var currentSessionTime: String
    var currentSubject: String
    var streakCount: Int
    var totalDailyTime: String
    var onlineFriends = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: Heading row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Study Day")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    // Live friends chip
                    HStack(spacing: 5) {
                        Circle()
                            .fill(onlineFriends > 0 ? Color.green : Color.secondary.opacity(0.4))
                            .frame(width: 7, height: 7)
                        Text(onlineFriends > 0
                             ? "\(onlineFriends) friends studying now"
                             : "No friends online right now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Streak badge — prominent but compact
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streakCount)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .glassEffect()
            }

            // MARK: Stat cards row
            // Three equal-width cards each carrying a label, icon, and value.
            HStack(spacing: 10) {
                StudyStatCard(
                    icon: "timer",
                    iconColor: .blue,
                    label: "Session",
                    value: currentSessionTime
                )
                StudyStatCard(
                    icon: "book.fill",
                    iconColor: .purple,
                    label: "Subject",
                    value: currentSubject
                )
                StudyStatCard(
                    icon: "clock.fill",
                    iconColor: .green,
                    label: "Today",
                    value: totalDailyTime
                )
            }
        }
    }
}
//UIEND

// MARK: - Helper: individual stat card

/// A compact glass card showing a single study metric.
private struct StudyStatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect()
    }
}

#Preview {
    NavigationStack {
        DashboardHeader(
            currentSessionTime: "01:22",
            currentSubject: "Mathematics",
            streakCount: 12,
            totalDailyTime: "03:41"
        )
        .padding()
    }
}
