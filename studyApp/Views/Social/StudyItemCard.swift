//  StudyItemCard.swift
//  studyApp

import SwiftUI

// MARK: - CardVariant

/// Three visual styles for a friend row.
/// Shown one-per-entry in the list so you can compare them at a glance.
/// Once you've chosen a favourite, delete the other two cases and set a
/// single default in SocialFeedView.friendList.
enum CardVariant {
    /// Coloured left bar + initials circle + subject code (current design).
    case accentBar
    /// Large initials ring + subject shown as a tinted capsule tag.
    case bubbleCard
    /// Minimal single-line row: status dot + name + subject + timer.
    case compactRow
}

// MARK: - StudyItemCard

/// Compact summary row for a study member.
/// The `variant` parameter controls which of the three layouts is rendered.
struct StudyItemCard: View {

    // MARK: Properties

    var item: SocialFeedItem
    var variant: CardVariant = .accentBar

    // MARK: Derived

    private var initial: String  { String(item.name.prefix(1)).uppercased() }
    private var isActive: Bool   { !item.isLocked }
    private var accentColor: Color { isActive ? .green : .secondary.opacity(0.5) }

    // MARK: Body

    var body: some View {
        Group {
            switch variant {
            case .accentBar:  accentBarLayout
            case .bubbleCard: bubbleCardLayout
            case .compactRow: compactRowLayout
            }
        }
    }

    // MARK: - Variant A: Accent bar
    // Left coloured bar signals status instantly.
    // Initials circle, name + subject code, timer + lock badge on right.

    private var accentBarLayout: some View {
        HStack(alignment: .center, spacing: 0) {

            // Status bar
            Capsule()
                .fill(accentColor)
                .frame(width: 3, height: 40)
                .padding(.trailing, 14)

            // Initials avatar
            ZStack {
                Circle()
                    .fill(isActive ? Color.green.opacity(0.14) : Color.secondary.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(initial)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isActive ? Color.green : Color.secondary)
            }
            .padding(.trailing, 12)

            // Name + subject
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

            // Timer + lock status
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
    }

    // MARK: - Variant B: Bubble card
    // Larger avatar with a tinted stroke ring.
    // Subject displayed as a small coloured capsule tag below the name.

    private var bubbleCardLayout: some View {
        HStack(spacing: 14) {

            // Large initials ring
            ZStack {
                Circle()
                    .fill(isActive ? Color.green.opacity(0.15) : Color.secondary.opacity(0.08))
                    .frame(width: 52, height: 52)
                Circle()
                    .strokeBorder(accentColor, lineWidth: 2)
                    .frame(width: 52, height: 52)
                Text(initial)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isActive ? Color.green : Color.secondary)
            }

            // Name + subject tag
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(item.subject)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isActive ? Color.green : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.12), in: Capsule())
            }

            Spacer()

            // Timer + status label
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.timer)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                Text(isActive ? "Studying" : "On break")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive())
    }

    // MARK: - Variant C: Compact row
    // Minimal horizontal row: status dot, name, subject, timer — all on one line.

    private var compactRowLayout: some View {
        HStack(spacing: 10) {

            // Tiny status dot
            Circle()
                .fill(accentColor)
                .frame(width: 9, height: 9)

            Text(item.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Text(item.subject)
                .font(.subheadline)
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


