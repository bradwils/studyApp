import SwiftUI

struct SettingsView: View {
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
                            SubjectsEditor(isPresented: $isShowingSubjectsEditor)
                                .padding(10)
                                .presentationDetents([.fraction(0.6)])
                                .presentationDragIndicator(.visible)
                                .presentationBackgroundInteraction(.enabled)
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
        }
    }
    
    func dismissedSubjectsEditor() {
    }
}

#Preview {
    SettingsView()
}

