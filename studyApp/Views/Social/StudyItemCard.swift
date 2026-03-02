//  StudyItemCard.swift
//  studyApp

import SwiftUI

/// Compact summary row for a study member.
struct StudyItemCard: View {
    var item: SocialFeedItem

    /// Returns the first character of the member's name uppercased, used as an avatar initial.
    private var initial: String {
        String(item.name.prefix(1)).uppercased()
    }

    var body: some View {
        //UITWEAK
        // Redesigned card: replaced the generic SF Symbol icon with an initials circle,
        // tightened up the info hierarchy, and removed the location placeholder row.
        // .glassEffect(.regular.interactive()) gives the card a native pressed highlight
        // with no shape parameter needed — the system infers the shape from the view.
        HStack(alignment: .center, spacing: 14) {

            // MARK: Initials avatar
            // A simple circle with the member's first initial is much more personal
            // than a generic system icon, and scales well when real photos are added later.
            ZStack {
                Circle()
                    .fill(item.isLocked ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(initial)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(item.isLocked ? Color.red : Color.green)
            }

            // MARK: Name + subject
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(item.subject)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // MARK: Session status
            VStack(alignment: .trailing, spacing: 6) {
                // Session timer in a small monospaced label so digits don't jump
                Text(item.timer)
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(Color.primary)

                // Lock indicator + daily total
                HStack(spacing: 4) {
                    Image(systemName: item.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.caption2)
                        .foregroundStyle(item.isLocked ? Color.red : Color.green)
                    Text(item.dailyTotalTime)
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive())
        //UIEND
    }
}

