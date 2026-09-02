import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: StudySession

    var body: some View {
        List {
            Section {
                heroCard
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Overview") {
                LabeledContent("Subject", value: session.subjectName ?? "Unknown subject")
                LabeledContent("Started", value: session.startedAt.formatted(date: .abbreviated, time: .shortened))
                if let endedAt = session.endedAt {
                    LabeledContent("Ended", value: endedAt.formatted(date: .abbreviated, time: .shortened))
                } else {
                    LabeledContent("Status", value: "In progress")
                }
                LabeledContent("Total duration", value: formattedDuration(session.totalDuration))
                LabeledContent("Active duration", value: formattedDuration(session.totalActiveDuration))
            }

            if let studyScore = session.studyScore {
                Section("Score") {
                    LabeledContent("Study score", value: "\(studyScore)/10")
                }
            }

            if let notes = session.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            if let breaks = session.breaks, !breaks.isEmpty {
                Section("Breaks (\(breaks.count))") {
                    ForEach(breaks) { studyBreak in
                        intervalRow(startedAt: studyBreak.startedAt, duration: studyBreak.duration)
                    }
                }
            }

            if let sections = session.sections, !sections.isEmpty {
                Section("Sections (\(sections.count))") {
                    ForEach(sections) { section in
                        intervalRow(startedAt: section.startedAt, duration: section.duration)
                    }
                }
            }

            if let location = session.location {
                Section("Location") {
                    LabeledContent("Label", value: location.locationLabel)
                    if let description = location.locationDescription {
                        LabeledContent("Description", value: description)
                    }
                }
            }

            if let friends = session.friends, !friends.isEmpty {
                Section("Studied with") {
                    ForEach(friends, id: \.self) { friend in
                        Text(friend)
                    }
                }
            }

            Section("Other") {
                LabeledContent("Interruptions", value: "\(session.interruptionCount)")
            }
        }
        .navigationTitle(session.subjectName ?? "Session")
        .toolbarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        VStack(spacing: DS.Space.s) {
            Text(session.subjectName ?? "Unknown subject")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(formattedDuration(session.totalDuration))
                .font(.largeTitle.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .surfaceCard()
        .accessibilityElement(children: .combine)
    }

    private func intervalRow(startedAt: Date, duration: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(startedAt.formatted(date: .omitted, time: .shortened))
            Text(formattedDuration(duration))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        Duration.seconds(interval).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(
            session: StudySession(
                subjectName: "Mathematics",
                startedAt: .now.addingTimeInterval(-3600),
                endedAt: .now
            )
        )
    }
    .modelContainer(for: StudySession.self, inMemory: true)
}
