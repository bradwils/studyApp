//  DebugDataView.swift
//  studyApp
//
//  DEV ONLY — see CLAUDE.md "Developer-Only Views". Root of the SwiftData
//  debug tools: live counts for every registered model, drilling into
//  DebugModelListView for inspection/deletion of individual records.

import SwiftUI
import SwiftData

struct DebugDataView: View {
    @Query private var themes: [AppTheme]
    @Query private var subjects: [Subject]
    @Query private var sessions: [StudySession]
    @Query private var breaks: [StudyBreak]
    @Query private var sections: [StudySection]
    @Query private var locations: [SessionLocation]

    @Query private var studyTasks: [StudyTask]
    @Query private var taskFieldValues: [TaskFieldValue]
    @Query private var taskFieldDefinitions: [TaskFieldDefinition]
    @Query private var taskFieldOptions: [TaskFieldOption]
    @Query private var taskBoardLayouts: [TaskBoardLayout]
    @Query private var subjectTaskBoards: [SubjectTaskBoard]

    var body: some View {
        List {
            Section {
                modelLink(title: "Themes", systemImage: "paintpalette", count: themes.count) {
                    DebugModelListView(title: "Themes") { (theme: AppTheme) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.name).font(.headline)
                            HStack(spacing: 6) {
                                swatch(theme.primaryColor)
                                swatch(theme.secondaryColor)
                                swatch(theme.accentColor)
                            }
                        }
                    }
                }
                modelLink(title: "Subjects", systemImage: "book", count: subjects.count) {
                    DebugModelListView(title: "Subjects") { (subject: Subject) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(subject.name) (\(subject.code))").font(.headline)
                            Text("\(subject.sessions.count) session(s) · created \(subject.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Study Sessions", systemImage: "timer", count: sessions.count) {
                    DebugModelListView(title: "Study Sessions") { (session: StudySession) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.subjectName ?? "Untitled").font(.headline)
                            Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(Int(session.totalDuration / 60))m")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Study Breaks", systemImage: "cup.and.saucer", count: breaks.count) {
                    DebugModelListView(title: "Study Breaks") { (studyBreak: StudyBreak) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(studyBreak.startedAt.formatted(date: .abbreviated, time: .shortened)).font(.headline)
                            Text("\(Int(studyBreak.duration / 60))m").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Study Sections", systemImage: "chart.bar", count: sections.count) {
                    DebugModelListView(title: "Study Sections") { (section: StudySection) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.startedAt.formatted(date: .abbreviated, time: .shortened)).font(.headline)
                            Text("\(Int(section.duration / 60))m").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Session Locations", systemImage: "mappin.and.ellipse", count: locations.count) {
                    DebugModelListView(title: "Session Locations") { (location: SessionLocation) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.locationLabel.isEmpty ? "Untitled" : location.locationLabel).font(.headline)
                            if let description = location.locationDescription {
                                Text(description).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("SwiftData Models")
            } footer: {
                Text("Tap a model to view, inspect, or delete individual records.")
            }

            Section {
                modelLink(title: "Task Inspector", systemImage: "checklist", count: studyTasks.count) {
                    DebugTaskDataView()
                }
                modelLink(title: "Study Tasks", systemImage: "checkmark.circle", count: studyTasks.count) {
                    DebugModelListView(title: "Study Tasks") { (task: StudyTask) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title.isEmpty ? "Untitled" : task.title).font(.headline)
                            Text("\(task.subjectName ?? "No subject") · \(task.isDone ? "Done" : "Open")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Task Field Values", systemImage: "square.text.square", count: taskFieldValues.count) {
                    DebugModelListView(title: "Task Field Values") { (value: TaskFieldValue) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(value.definition?.name ?? "No definition (orphaned)").font(.headline)
                            Text(value.task?.title ?? "No task").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Task Field Definitions", systemImage: "list.bullet.rectangle", count: taskFieldDefinitions.count) {
                    DebugModelListView(title: "Task Field Definitions") { (definition: TaskFieldDefinition) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(definition.name.isEmpty ? "Untitled" : definition.name).font(.headline)
                            Text("\(definition.kind.rawValue)\(definition.coreKey != nil ? " · core" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Task Field Options", systemImage: "tag", count: taskFieldOptions.count) {
                    DebugModelListView(title: "Task Field Options") { (option: TaskFieldOption) in
                        HStack(spacing: 8) {
                            Circle().fill(Color(hex: option.colorHex) ?? .gray).frame(width: 14, height: 14)
                            Text(option.label.isEmpty ? "Untitled" : option.label).font(.headline)
                        }
                    }
                }
                modelLink(title: "Task Board Layouts", systemImage: "square.grid.2x2", count: taskBoardLayouts.count) {
                    DebugModelListView(title: "Task Board Layouts") { (layout: TaskBoardLayout) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(layout.name.isEmpty ? "Untitled" : layout.name).font(.headline)
                            Text("\((layout.columns ?? []).count) column(s)\(layout.isDefault ? " · default" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                modelLink(title: "Subject Task Boards", systemImage: "link", count: subjectTaskBoards.count) {
                    DebugModelListView(title: "Subject Task Boards") { (board: SubjectTaskBoard) in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(board.subject?.name ?? "No subject").font(.headline)
                            Text(board.layout?.name ?? "No layout").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Task Board (Dev)")
            } footer: {
                Text("Task Inspector cross-references every model below against the storage seam in StudyTask+Fields.swift; the rows below it are the raw per-model lists.")
            }
        }
        .navigationTitle("Debug Data")
    }

    @ViewBuilder
    private func modelLink<Destination: View>(
        title: String,
        systemImage: String,
        count: Int,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            Label {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(count)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } icon: {
                Image(systemName: systemImage)
            }
        }
    }

    private func swatch(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 14, height: 14)
    }
}

#Preview {
    NavigationStack {
        DebugDataView()
    }
    .modelContainer(
        for: [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self] + TaskSchema.models,
        inMemory: true
    )
}
