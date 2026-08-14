import SwiftUI
import SwiftData
import OSLog

struct SettingsView: View {
    
    var logger = Logger(subsystem: "com.studyApp", category: "SettingsView")
    
    private enum Theme: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "System Default"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    @State private var notificationsEnabled = true
    @State private var preferredTheme: Theme = .system
    @State private var studyReminderTime = Date()
    @State private var isShowingSubjectsEditor = false // drives the custom bottom drawer
    
    @State var settingsSheetDetent: PresentationDetent = .medium //MOVE TO VM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("List")) {
                        Button() {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isShowingSubjectsEditor.toggle()
                            }
                        } label: {
                            Label("Edit Subjects", systemImage: "list.bullet")
                        }
                        .sheet(isPresented: $isShowingSubjectsEditor, onDismiss: dismissedSubjectsEditor) {
                            SubjectsEditor(isPresented: $isShowingSubjectsEditor, currentDetent: $settingsSheetDetent)
                                .padding(10)
                                .presentationDetents([.fraction(0.6)])
                                .presentationDragIndicator(.visible)
                                .presentationBackgroundInteraction(.enabled)
                        }
                    }
                    
                    Section(header: Text("Debug")) {
                        Button {
                            insertFakeSession()
                        } label: {
                            Label("Generate Fake Study Session", systemImage: "wand.and.stars")
                        }

                        // Temporary entry point — the whole of the tasks feature's footprint
                        // outside its own folders is this link plus one line in StudyAppApp.
                        // Moves to a subject screen later; see docs/StudyTasks.md §7.
                        NavigationLink {
                            TaskBoardView()
                        } label: {
                            Label("Task Board", systemImage: "checklist")
                        }
                    }

                    Section(footer: Text("Version 1.0.0")) {
                        Button(role: .destructive) {
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                // DEV ONLY — see CLAUDE.md "Developer-Only Views"
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        DebugDataView()
                    } label: {
                        Image(systemName: "ladybug")
                    }
                }
            }
        }
    }
    
    func dismissedSubjectsEditor() {

    }

    func insertFakeSession() {
        let startedAt = Date().addingTimeInterval(-3600)
        let session = StudySession(
            subjectName: "Test Subject",
            startedAt: startedAt,
            endedAt: Date(),
            notes: "Fake session for testing delete"
        )
        modelContext.insert(session)
        do {
            try modelContext.save()
            logger.log("worked!")
        } catch {
            logger.log("Failed to insert: \(error)")
        }
    }
}

#Preview {
    
    SettingsView(settingsSheetDetent: .fraction(0.5))
    
}
