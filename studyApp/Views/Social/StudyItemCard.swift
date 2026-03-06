//  StudyItemCard.swift
//  studyApp

import SwiftUI

// MARK: - OnlineUserCard

/// Friend row for someone who is currently studying.
/// Accent bar layout: coloured left bar, initials circle, name + subject, timer + lock badge.
struct OnlineUserCard: View {

    var item: SocialFeedItem

    private var initial: String { String(item.name.prefix(1)).uppercased() }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            // MARK: Status bar (green = studying)
            Capsule()
                .fill(Color.green)
                .frame(width: 3, height: 40)
                .padding(.trailing, 14)

            // MARK: Initials avatar
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.14))
                    .frame(width: 44, height: 44)
                Text(initial)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.green)
            }
            .padding(.trailing, 12)

            // MARK: Name + subject
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Text(item.subject)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(item.subjectCode)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // MARK: Timer + lock status
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.timer)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Image(systemName: "lock.open.fill")
                        .font(.caption)
                        .foregroundStyle(Color.green)
                    Text(item.dailyTotalTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive())
    }
}

// MARK: - OfflineUserCard

/// Friend row for someone who is on a break or not currently studying.
/// Compact row layout: status dot, name, subject, timer — all on one line.
struct OfflineUserCard: View {

    var item: SocialFeedItem

    var body: some View {
        HStack(spacing: 10) {

            // MARK: Status dot (muted = not studying)
            Circle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 9, height: 9)

            Text(item.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Text(item.subject)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(item.timer)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .glassEffect(.regular.interactive())
    }
}

