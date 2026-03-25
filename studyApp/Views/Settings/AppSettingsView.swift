import SwiftUI
import SwiftData

struct AppSettingsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = ThemeSettingsViewModel()

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                ColorPicker("Background", selection: $viewModel.selectedColor)

                Text("Create a new theme")
                    .font(.headline)

                ForEach(viewModel.templates) { template in
                    Button("Create \(template.name) Theme") {
                        viewModel.createTheme(from: template, using: context)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.themes) { theme in
                    Text(theme.name)
                        .foregroundStyle(theme.primaryColor)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.bootstrap(using: context)
        }
    }
}

#Preview {
    AppSettingsView()
        .modelContainer(for: AppTheme.self, inMemory: true)
}
