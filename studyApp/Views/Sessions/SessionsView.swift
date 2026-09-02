import SwiftUI
import SwiftData

struct SessionsView: View {

    @State private var vm = SessionViewerViewModel()
    @State private var isShowingRemoveAllConfirmation = false

    @Environment(\.modelContext) private var context

    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    // Query is already newest-first, and Dictionary(grouping:) preserves
    // relative order, so each day's sessions stay sorted.
    private var sessionsByDay: [(day: Date, sessions: [StudySession])] {
        Dictionary(grouping: sessions) { Calendar.current.startOfDay(for: $0.startedAt) }
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, sessions: $0.value) }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView("No sessions yet", systemImage: "clock.arrow.circlepath")
            } else {
                List {
                    ForEach(sessionsByDay, id: \.day) { group in
                        Section(dayTitle(group.day)) {
                            ForEach(group.sessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    sessionRow(session)
                                }
                            }
                            .onDelete { offsets in
                                vm.deleteSessions(offsets.map { group.sessions[$0] }, context: context)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Options", systemImage: "ellipsis.circle") {
                    Button("Remove All Sessions", systemImage: "trash", role: .destructive) {
                        isShowingRemoveAllConfirmation = true
                    }
                }
                .disabled(sessions.isEmpty)
            }
        }
        .confirmationDialog(
            "Remove all ^[\(sessions.count) session](inflect: true)?",
            isPresented: $isShowingRemoveAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove All Sessions", role: .destructive) {
                vm.removeAllSessions(context: context)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func sessionRow(_ session: StudySession) -> some View {
        HStack(spacing: DS.Space.m) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(session.subjectName ?? "Unknown subject")
                    .font(.headline)
                Text(rowSubtitle(session))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: DS.Space.s)
            Text(formattedDuration(session.totalDuration))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .accessibilityElement(children: .combine)
    }

    private func rowSubtitle(_ session: StudySession) -> String {
        let startTime = session.startedAt.formatted(date: .omitted, time: .shortened)
        guard let code = session.subject?.code else { return startTime }
        return "\(code) · \(startTime)"
    }

    private func dayTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
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
