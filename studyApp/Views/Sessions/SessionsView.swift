import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                List(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.subjectName ?? session.subject?.name ?? "Unknown subject")
                            .font(.headline)

                        Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(formattedDuration(session.totalActiveDuration))
                            .font(.subheadline.monospacedDigit())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Sessions")
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        Duration.seconds(interval).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#Preview {
    NavigationStack {
        SessionsView()
    }
    .modelContainer(for: StudySession.self, inMemory: true)
}
