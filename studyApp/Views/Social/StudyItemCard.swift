//  StudyItemCard.swift
//  studyApp

import SwiftUI

/// Compact summary row for a study member.
struct StudyItemCard: View {
    var item: SocialFeedItem

    //UITWEAK: Track press state for interactive glass effect
    @State private var isPressed = false
    //UIEND

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
        //UITWEAK: Glass effect background with interactive states for native iOS feel
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                // Use glass effect for modern native iOS appearance with blur and translucency
                .glassEffect(.regular.interactive())
        )
        // Enhanced shadow with interactive depth changes
        .shadow(
            color: Color.black.opacity(isPressed ? 0.12 : 0.08),
            radius: isPressed ? 16 : 12,
            x: 0,
            y: isPressed ? 10 : 8
        )
        // Subtle scale effect for tactile feedback
        .scaleEffect(isPressed ? 0.98 : 1.0)
        // Smooth spring animation for press interactions
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        // Gesture to track press state for interactive feedback
        .onTapGesture {
            // Animate press then release
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }
        //UIEND
    }
}

