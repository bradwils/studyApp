import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("List")) {
                        Button() {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                viewModel.toggleSubjectsEditor()
                            }
                        } label: {
                            Label("Edit Subjects", systemImage: "list.bullet")
                        }
                        .sheet(isPresented: $viewModel.isShowingSubjectsEditor, onDismiss: dismissedSubjectsEditor) {
                            SubjectsEditor(isPresented: $viewModel.isShowingSubjectsEditor)
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

    private func dismissedSubjectsEditor() {
        viewModel.dismissSubjectsEditor()
    }
}

#Preview {
    SettingsView()
}
