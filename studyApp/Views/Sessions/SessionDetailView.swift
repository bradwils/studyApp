import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: StudySession

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
			Section() {
                LabeledContent("Subject", value: session.subjectName ?? "subjectName missing")
                LabeledContent("Started", value: session.startedAt.formatted(date: .abbreviated, time: .shortened))
                if let endedAt = session.endedAt {
                    LabeledContent("Ended", value: endedAt.formatted(date: .abbreviated, time: .shortened))
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

            studyTimeSection

            if let studyScore = session.studyScore {
                Section("Score") {
                    LabeledContent("Study score", value: "\(studyScore)/10")
                }
            }

            Section("Notes") {
                TextField("Add a note", text: notes, axis: .vertical)
                    .accessibilityIdentifier("sessionNotesField")
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
        .onDisappear { try? modelContext.save() }
    }

    @ViewBuilder
    private var studyTimeSection: some View {
        let end = session.endedAt ?? .now
        let spans = StudyTimeline.spans(for: session, now: end)
        let totals = StudyTimeline.totals(spans)
        if end > session.startedAt, !spans.isEmpty {
            Section("Study time") {
                SessionStudyBar(spans: spans, range: session.startedAt...end)
                    .padding(.vertical, 4)
                ForEach(StudyTimeKind.allCases, id: \.self) { kind in
                    if let total = totals[kind] {
                        LabeledContent {
                            Text(formattedDuration(total))
                        } label: {
                            Label {
                                Text(kind.title)
                            } icon: {
                                Circle().fill(kind.color).frame(width: 10, height: 10)
                            }
                        }
                    }
                }
            }
        }
    }

    private var notes: Binding<String> {
        Binding(
            get: { session.notes ?? "" },
            set: { session.notes = $0.isEmpty ? nil : $0 }
        )
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
