//
//  StudySessionLiveActivity.swift
//  studyApp
//
//  Live Activity widget for displaying active study sessions on Lock Screen and Dynamic Island
//

import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity widget for study sessions
struct StudySessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudySessionAttributes.self) { context in
            // Lock screen/banner UI
            StudySessionLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text(context.state.subjectCode)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        if context.state.isPaused {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.state.subjectName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)

                        // Timer display
                        Text(formatDuration(context.state.sessionDuration))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.blue)
                            .monospacedDigit()

                        // Additional metrics
                        HStack(spacing: 16) {
                            if context.state.interruptionCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                    Text("\(context.state.interruptionCount)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.orange)
                            }

                            if context.state.totalBreakDuration > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.system(size: 10))
                                    Text(formatDuration(context.state.totalBreakDuration))
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                // Compact leading (left side of Dynamic Island)
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island)
                Text(formatDurationCompact(context.state.sessionDuration))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(context.state.isPaused ? .orange : .green)
                    .monospacedDigit()
            } minimal: {
                // Minimal view (when multiple activities are active)
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
        }
    }
}

/// Lock Screen view for the Live Activity
struct StudySessionLiveActivityView: View {
    let context: ActivityViewContext<StudySessionAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Subject icon
            VStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)

                if context.state.isPaused {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }
            .frame(width: 50)

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.subjectName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(context.state.subjectCode)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Timer
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(context.state.sessionDuration))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(context.state.isPaused ? .orange : .blue)
                    .monospacedDigit()

                // Status text
                Text(context.state.isPaused ? "Paused" : "Studying")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(context.state.isPaused ? .orange : .green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
    }
}

// MARK: - Helper Functions

/// Formats a duration in seconds to HH:MM:SS or MM:SS format
private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Formats a duration in compact format for Dynamic Island
private func formatDurationCompact(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60

    if hours > 0 {
        return String(format: "%d:%02d", hours, minutes)
    } else {
        return String(format: "%d", minutes)
    }
}
