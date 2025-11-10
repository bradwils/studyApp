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
        NavigationStack { //is this nesaccary?
            
            ZStack {
                Form {
                    Section(header: Text("List")) {
                        Button() {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { //with an animation
                                isShowingSubjectsEditor.toggle()
                            }
                        } label: {
                            Label("Edit Subjects", systemImage: "list.bullet")
                        }
                        .sheet(isPresented: $isShowingSubjectsEditor, onDismiss: dismissedSubjectsEditor) {
                            SubjectsEditor(isPresented: $isShowingSubjectsEditor)
                            // Sheet view (slide up from below) is toggled to be up or not based on the isShowingSubjectsEditor, which is also passed as a binding into the view so we can close the view from within with a close button.
                                .padding(10)
                                .presentationDetents([.fraction(0.6)])
                                .presentationDragIndicator(.visible)
                                .presentationBackgroundInteraction(.enabled)
                            
                        }
                    }
                    
                    Section(footer: Text("Version 1.0.0")) {
                        Button(role: .destructive) {
                            // Sign-out logic.
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

