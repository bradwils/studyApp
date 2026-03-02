//  DashboardHeader.swift
//  studyApp

import SwiftUI

//UITWEAK
// Redesigned DashboardHeader:
// - Removed the embedded avatar/menu (it now lives as a standard toolbar button in SocialView).
// - The greeting row now shows a cleaner online-friends chip instead of the old freeform HStack.
// - Stats card uses .glassEffect() directly on the HStack background — no shape needed.
// - Spacing and typography tightened to match SwiftUI List/Form conventions.

/// Summary banner reused across the social feed and related dashboards.
struct DashboardHeader: View {
    var currentSessionTime: String
    var currentSubject: String
    var streakCount: Int
    var totalDailyTime: String
    var onlineFriends = 2 // placeholder

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: Online friends indicator
            // Shown inline below the navigation title so the page reads:
            // title → status → stats → list.
            HStack(spacing: 6) {
                if onlineFriends > 0 {
                    // Green pulse dot to signal live activity
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(onlineFriends) friends studying now")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text("No friends studying right now")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }

            // MARK: Session stats card
            // .glassEffect() applied directly — no explicit shape argument needed.
            HStack(spacing: 20) {
                VStack(alignment: .center, spacing: 4) {
                    Text("Session")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Text(currentSessionTime)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Subject")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Text(currentSubject)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.orange)
                    Text("\(streakCount)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.orange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .glassEffect()
        }
    }
}
//UIEND

#Preview {
    NavigationStack {
        DashboardHeader(currentSessionTime: "01:22", currentSubject: "Mathematics", streakCount: 4, totalDailyTime: "02:34")
            .padding()
    }
}
