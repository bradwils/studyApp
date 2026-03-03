//  StudyItemCard.swift
//  studyApp

import SwiftUI

//UITWEAK
// Redesigned friend card v2:
// - Left accent bar: green for active, muted for locked — gives instant visual status at a glance
// - Initials avatar circle tinted to match the accent
// - Name + subject name + subject code together in the label stack
// - Right side: session timer (monospaced, prominent) + lock badge + daily total
// The card uses .glassEffect(.regular.interactive()) without a shape argument.

/// Compact summary row for a study member.
struct StudyItemCard: View {
    var item: SocialFeedItem

    private var initial: String {
        String(item.name.prefix(1)).uppercased()
    }
    private var isActive: Bool { !item.isLocked }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            // MARK: Left accent bar
            // Instantly communicates studying (green) vs locked/idle (muted) without
            // needing to read the lock icon.
            Capsule()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.35))
                .frame(width: 3, height: 40)
                .padding(.trailing, 14)

            // MARK: Initials avatar
            ZStack {
                Circle()
                    .fill(isActive ? Color.green.opacity(0.14) : Color.secondary.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(initial)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isActive ? Color.green : Color.secondary)
            }
            .padding(.trailing, 12)

            // MARK: Name + subject labels
            VStack(alignment: .leading, spacing: 3) {
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
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            }

            Spacer()

            // MARK: Session status (right-aligned)
            VStack(alignment: .trailing, spacing: 5) {
                Text(item.timer)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: isActive ? "lock.open.fill" : "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(isActive ? Color.green : Color.red)
                    Text(item.dailyTotalTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive())
        //UIEND
    }
}

