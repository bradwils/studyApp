import SwiftUI
import SwiftData

struct SessionsView: View {
    
    @State private var vm = SessionViewerViewModel()
    
    @Environment(\.modelContext) private var context: ModelContext
    
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView("No sessions yet", systemImage: "clock.arrow.circlepath")
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            sessionRow(session)
                        }
                    }
                    .onDelete { offsets in
                        vm.deleteSessions(offsets.map { sessions[$0] }, context: context)
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Remove Sessions", role: .destructive) {
                    vm.removeAllSessions(context: context)
                }
            }
        }
    }

    private func sessionRow(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.subjectName ?? "Backup")
                .font(.headline)
            Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(formattedDuration(session.totalDuration))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
