//  StudyItemCard.swift
//  studyApp

import SwiftUI

/// Compact summary row for a study member.
struct StudyItemCard: View {
    var item: ListItem

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0))
                    .frame(width: 56, height: 56)
                Image(systemName: item.photo)
                    .foregroundColor(.primary)
                    .offset(x: -6, y: -6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(item.subjectCode)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color.blue)
                    Text("location placeholder")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: item.isLocked ? "lock.fill" : "lock.open.fill")
                        .foregroundStyle(item.isLocked ? Color.red : Color.green)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(item.timer)
                            .font(.caption)
                            .foregroundStyle(Color.blue)
                        Text(item.dailyTotalTime)
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
    }
}
