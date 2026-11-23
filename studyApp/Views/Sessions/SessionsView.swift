import SwiftUI
import SwiftData

struct SessionsView: View {
    let activeSessionID: UUID?
    
    @State private var vm = SessionViewerViewModel()
    @State private var isShowingRemoveAllConfirmation = false
    
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
                        .deleteDisabled(session.id == activeSessionID)
                    }
                    .onDelete { offsets in
                        vm.deleteSessions(offsets.map { sessions[$0] }, activeSessionID: activeSessionID, context: context)
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Remove Sessions", role: .destructive) {
                    isShowingRemoveAllConfirmation = true
                }
                .disabled(!hasRemovableSessions)
            }
        }
        .confirmationDialog(
            "Remove session history?",
            isPresented: $isShowingRemoveAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Session History", role: .destructive) {
                vm.removeAllSessions(activeSessionID: activeSessionID, context: context)
            }
            .disabled(!hasRemovableSessions)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All completed and unfinished sessions and their breaks, study sections and locations will be permanently removed. Your current active session, if any, is kept. This can't be undone.")
        }
        .onChange(of: activeSessionID) { _, _ in
            isShowingRemoveAllConfirmation = false
        }
        .onChange(of: sessions.map(\.id)) { _, _ in
            isShowingRemoveAllConfirmation = false
        }
    }

    private var hasRemovableSessions: Bool {
        sessions.contains { $0.id != activeSessionID }
    }

    private func sessionRow(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.subjectName ?? "Backup")
                .font(.headline)
            Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(formattedDuration(session.totalDuration))")
                .font(.caption)
                .foregroundStyle(.secondary)
            if session.endedAt == nil {
                Text(session.id == activeSessionID ? "In progress" : "Unfinished")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        Duration.seconds(interval).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#Preview {
    NavigationStack {
        SessionsView(activeSessionID: nil)
    }
    .modelContainer(for: StudySession.self, inMemory: true)
}
