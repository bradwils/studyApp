import SwiftUI

struct SessionDetailView: View {
    let session: StudySession
    var body: some View {
        List {
			Section() {
                LabeledContent("Subject", value: session.subjectName ?? "subjectName missing")
                LabeledContent("Started", value: formattedTimestamp(session.startedAt))
                if let endedAt = session.endedAt {
                    LabeledContent("Ended", value: formattedTimestamp(endedAt))
                } else {
                    LabeledContent("Status", value: "In progress")
                }
                LabeledContent("Total duration", value: formattedDuration(session.totalDuration))
                LabeledContent("Active duration", value: formattedDuration(session.totalActiveDuration))
			} header: {
				HStack {
					Text("Overview")
					Spacer()
					if (session.subject == nil) {
						Text("NO SUBJECT ATTATCHED")
							.foregroundStyle(Color.red)
							.bold()
					}
				}
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
                            Text(formattedTime(studyBreak.startedAt))
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
                            Text(formattedTime(section.startedAt))
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

    private func formattedTimestamp(_ date: Date) -> String {
        let text = formattedTime(date, dateStyle: .abbreviated)
        let zone = session.timeZone()
        guard zone.identifier != TimeZone.current.identifier,
              let abbreviation = zone.abbreviation(for: date) else { return text }
        return "\(text) \(abbreviation)"
    }

    private func formattedTime(_ date: Date, dateStyle: Date.FormatStyle.DateStyle = .omitted) -> String {
        date.formatted(Date.FormatStyle(date: dateStyle, time: .shortened, timeZone: session.timeZone()))
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
