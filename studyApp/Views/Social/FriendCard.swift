//  FriendCard.swift
//  studyApp

import SwiftUI

// One card for every friend row. Active friends get the accent bar + full
// two-line layout; offline friends get the same card in a muted, compact
// density (smaller avatar, single line, no bar) with identical card padding.
struct FriendCard: View {

    var item: SocialFeedItem

    // A friend counts as studying while their session is unlocked.
    private var isActive: Bool { !item.isLocked }

    private var statusTint: Color { isActive ? DS.Color.active : DS.Color.offline }

    var body: some View {
        HStack(spacing: DS.Space.m) {
            if isActive {
                Capsule()
                    .fill(DS.Color.active)
                    .frame(width: 3, height: 40)
                    .accessibilityHidden(true)
            }

            AvatarBadge(name: item.name, tint: statusTint, size: isActive ? 44 : 32)

            if isActive {
                activeDetails
            } else {
                offlineDetails
            }
        }
        .surfaceCard()
        .contentShape(.rect(cornerRadius: DS.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var activeDetails: some View {
        HStack(spacing: DS.Space.s) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: DS.Space.xs) {
                    Text(item.subject)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Text(item.subjectCode)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: DS.Space.s)

            VStack(alignment: .trailing, spacing: DS.Space.xs) {
                Text(item.timer)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                Text("\(item.dailyTotalTime) today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var offlineDetails: some View {
        HStack(spacing: DS.Space.s) {
            Text(item.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            Text(item.subject)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: DS.Space.s)

            Text(item.timer)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilitySummary: String {
        if isActive {
            "\(item.name), studying \(item.subject), \(item.timer) elapsed, \(item.dailyTotalTime) today"
        } else {
            "\(item.name), offline, \(item.subject), \(item.timer)"
        }
    }
}

#Preview {
    ZStack {
        ScreenBackground()
        VStack(spacing: DS.Space.s) {
            FriendCard(item: SocialFeedItem(name: "Carol", subject: "Chemistry", subjectCode: "CHEM", isLocked: false, timer: "00:30", photo: "person.crop.square", dailyTotalTime: "6:00"))
            FriendCard(item: SocialFeedItem(name: "Earl", subject: "English", subjectCode: "ENG", isLocked: true, timer: "00:50", photo: "person.crop.square.fill", dailyTotalTime: "8:00"))
        }
        .padding(DS.Space.xl)
    }
}
