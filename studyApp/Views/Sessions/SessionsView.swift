import SwiftUI
import SwiftData

struct SessionsView: View {
    
    @State private var vm = SessionViewerViewModel()
    
    @Environment(\.modelContext) private var context: ModelContext
    
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    var body: some View {
        
        Button(action: {
            vm.removeAllSessions(context: context)
        })
        {
            Text("Remove Sessions")
        }
        .buttonStyle(.glass)
        
        Spacer()
        Group {
            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sessions) { session in
                    Text(session.subjectName ?? "Backup")
                }
            }
        }
        .navigationTitle("Sessions")
        Spacer()
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
