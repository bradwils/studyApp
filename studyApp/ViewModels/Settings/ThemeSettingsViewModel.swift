import SwiftUI
import SwiftData
import Combine

@MainActor
final class ThemeSettingsViewModel: ObservableObject {
    struct ThemeTemplate: Identifiable {
        let id = UUID()
        let name: String
        let secondary: Color
        let accent: Color
    }

    @Published var selectedColor: Color = .white
    @Published private(set) var themes: [AppTheme] = []

    let templates: [ThemeTemplate] = [
        ThemeTemplate(name: "Summer", secondary: .orange, accent: .red),
        ThemeTemplate(name: "Winter", secondary: .blue, accent: .white),
        ThemeTemplate(name: "Dummy", secondary: .green, accent: .blue)
    ]

    private let defaultThemes: [(name: String, primary: Color, secondary: Color, accent: Color)] = [
        ("Default", .white, .blue, .gray)
    ]

    func bootstrap(using context: ModelContext) {
        refreshThemes(using: context)
        ensureDefaultThemeExists(using: context)
    }

    func createTheme(from template: ThemeTemplate, using context: ModelContext) {
        createTheme(
            named: template.name,
            primary: selectedColor,
            secondary: template.secondary,
            accent: template.accent,
            using: context
        )
    }

    func createTheme(named name: String, primary: Color, secondary: Color, accent: Color, using context: ModelContext) {
        let newTheme = AppTheme(name: name, primary: primary, secondary: secondary, accent: accent)
        context.insert(newTheme)
        refreshThemes(using: context)
    }

    private func ensureDefaultThemeExists(using context: ModelContext) {
        guard themes.isEmpty else { return }

        for theme in defaultThemes {
            context.insert(
                AppTheme(
                    name: theme.name,
                    primary: theme.primary,
                    secondary: theme.secondary,
                    accent: theme.accent
                )
            )
        }

        refreshThemes(using: context)
    }

    private func refreshThemes(using context: ModelContext) {
        let descriptor = FetchDescriptor<AppTheme>(sortBy: [SortDescriptor(\AppTheme.name, order: .forward)])
        themes = (try? context.fetch(descriptor)) ?? []
    }
}
