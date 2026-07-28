import SwiftUI

struct SessionDetailView: View {
    let session: StudySession

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Subject", value: session.subjectName ?? "Backup")
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
                        VStack(alignment: .leading) {
                            Text(studyBreak.startedAt.formatted(date: .omitted, time: .shortened))
                            Text(formattedDuration(studyBreak.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let sections = session.sections, !sections.isEmpty {
                Section("Sections (\(sections.count))") {
                    ForEach(sections) { section in
                        VStack(alignment: .leading) {
                            Text(section.startedAt.formatted(date: .omitted, time: .shortened))
                            Text(formattedDuration(section.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        Duration.seconds(interval).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: StudySession(startedAt: .now.addingTimeInterval(-3600), endedAt: .now))
    }
}
