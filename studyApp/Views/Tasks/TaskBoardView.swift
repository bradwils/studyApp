//  TaskBoardView.swift
//  studyApp
//
//  Entry point for a subject's task board. Optional subject so this can run standalone
//  with its own picker today, and drop into a subject screen later as a one-argument
//  change with the picker hidden — see docs/StudyTasks.md §7.

import SwiftUI
import SwiftData

struct TaskBoardView: View {
    let subject: Subject?

    @State private var vm: TaskBoardVM
    @State private var layout: TaskBoardLayout?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Query(sort: \StudyTask.sortIndex) private var allTasks: [StudyTask]

    init(subject: Subject? = nil) {
        self.subject = subject
        let boardVM = TaskBoardVM()
        boardVM.selectedSubject = subject
        _vm = State(initialValue: boardVM)
    }

    var body: some View {
        content
            .navigationTitle(vm.selectedSubject?.name ?? "Tasks")
            .toolbar { toolbarContent }
            // Keyed on the selected subject so switching subjects (picker, or a future
            // one-argument embed) re-resolves the board/layout for the new selection.
            .task(id: vm.selectedSubject?.id) {
                TaskSeeding.ensureDefaultLayout(in: modelContext)

                // No Picker tag matches nil, so an unselected board shows an empty control
                // rather than an obvious prompt. Standalone defaults to the first subject;
                // when embedded, the caller's subject already won.
                if subject == nil, vm.selectedSubject == nil, let first = subjects.first {
                    vm.selectedSubject = first
                }

                guard let selectedSubject = vm.selectedSubject else {
                    layout = nil
                    return
                }
                layout = TaskSeeding.board(for: selectedSubject, in: modelContext)?.layout
            }
    }

    private var content: some View {
        Group {
            if subject == nil && subjects.isEmpty {
                noSubjectsEmptyState
            } else {
                VStack(spacing: 0) {
                    if subject == nil {
                        subjectPicker
                    }
                    boardContent
                }
            }
        }
    }

    private var subjectPicker: some View {
        Picker("Subject", selection: $vm.selectedSubject) {
            ForEach(subjects, id: \.persistentModelID) { option in
                Text(option.name).tag(option as Subject?)
            }
        }
        .pickerStyle(.menu)
        .padding()
    }

    private var boardContent: some View {
        Group {
            if vm.selectedSubject == nil {
                noSubjectSelectedEmptyState
            } else if visibleTasks.isEmpty {
                noTasksEmptyState
            } else {
                taskList
            }
        }
    }

    private var taskList: some View {
        List {
            ForEach(visibleTasks, id: \.persistentModelID) { task in
                // Toggle sits beside the link, not inside its label — a Button nested in a
                // NavigationLink label never gets its own taps in a List.
                HStack(alignment: .top, spacing: 12) {
                    TaskDoneToggle(isDone: task.isDone) {
                        vm.toggleDone(task, columns: orderedColumns, context: modelContext)
                    }
                    NavigationLink {
                        TaskDetailView(task: task, columns: orderedColumns)
                    } label: {
                        TaskRowView(task: task, columns: orderedColumns)
                    }
                }
            }
            .onDelete { offsets in
                vm.deleteTasks(offsets.map { visibleTasks[$0] }, context: modelContext)
            }
        }
    }

    private var visibleTasks: [StudyTask] {
        vm.visibleTasks(from: allTasks)
    }

    // Columns are stored unordered on the layout; every consumer wants sortIndex order.
    private var orderedColumns: [TaskFieldDefinition] {
        TaskSeeding.orderedColumns(of: layout)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort by", selection: $vm.sortOption) {
                    ForEach(TaskBoardVM.SortOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                Toggle("Hide Completed", isOn: $vm.hideCompleted)
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                vm.addTask(context: modelContext)
            } label: {
                Label("Add Task", systemImage: "plus")
            }
            .disabled(vm.selectedSubject == nil)
        }
    }

    private var noSubjectsEmptyState: some View {
        ContentUnavailableView(
            "No Subjects Yet",
            systemImage: "books.vertical",
            description: Text("Add a subject in Settings before tracking tasks.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSubjectSelectedEmptyState: some View {
        ContentUnavailableView(
            "Choose a Subject",
            systemImage: "hand.point.up.left",
            description: Text("Pick a subject above to see its tasks.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noTasksEmptyState: some View {
        ContentUnavailableView(
            "No Tasks Yet",
            systemImage: "checklist",
            description: Text("Tap + to add the first task for \(vm.selectedSubject?.name ?? "this subject").")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        TaskBoardView()
    }
    .modelContainer(for: [Subject.self] + TaskSchema.models, inMemory: true)
}
