//  DashboardHeader.swift
//  studyApp

import SwiftUI

// MARK: - DashboardHeader

//UITWEAK
// DashboardHeader v3: three stats grouped into one glass container
// separated by Dividers, rather than three independent glass cards.
// The heading row and streak badge are unchanged.
// All glass effects applied without shape arguments.

/// Summary banner displayed above the friends feed on the Social screen.
struct DashboardHeader: View {

    // MARK: Properties

    var currentSessionTime: String
    var currentSubject: String
    var streakCount: Int
    var totalDailyTime: String
    var onlineFriends = 2

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: Heading row
            // Title on the left, streak badge on the right.
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Study Day")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    // MARK: Live friends indicator
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

                // MARK: Streak badge
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

            // MARK: Stats group
            // One glass container with three cells separated by Dividers.
            // Cells are aligned left / center / right for visual variety.
            HStack(spacing: 0) {
                statCell(icon: "timer",      iconColor: .blue,   label: "Session", value: currentSessionTime, alignment: .leading)
                Divider().padding(.vertical, 10)
                statCell(icon: "book.fill",  iconColor: .purple, label: "Subject",  value: currentSubject,        alignment: .center)
                Divider().padding(.vertical, 10)
                statCell(icon: "clock.fill", iconColor: .green,  label: "Today",    value: totalDailyTime,         alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .glassEffect()
        }
    }

    // MARK: - Helpers

    /// A single stat cell used inside the stats group.
    @ViewBuilder
    private func statCell(icon: String, iconColor: Color, label: String, value: String, alignment: HorizontalAlignment) -> some View {
        let frameAlignment: Alignment
        switch alignment {
        case .leading:  frameAlignment = .leading
        case .trailing: frameAlignment = .trailing
        default:        frameAlignment = .center
        }
        VStack(alignment: alignment, spacing: 5) {
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
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}
//UIEND

// MARK: - Preview

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

