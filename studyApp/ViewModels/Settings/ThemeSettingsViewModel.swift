import SwiftUI
import SwiftData
import Combine

@MainActor
/// Manages the app themes backed by SwiftData so the Settings UI can show saved palettes and create new ones.
final class ThemeSettingsViewModel: ObservableObject {
    struct ThemeTemplate: Identifiable {
        let id = UUID()
        let name: String
        let primary: Color
        let secondary: Color
        let accent: Color
    }

    @Published var selectedColor: Color = .white // placeholder for later color picker
    @Published var themes: [AppTheme] = []

    let defaultThemes: [ThemeTemplate] = [
        ThemeTemplate(name: "Summer", primary: .yellow, secondary: .orange, accent: .red),
        ThemeTemplate(name: "Winter", primary: .gray, secondary: .blue, accent: .white),
        ThemeTemplate(name: "Dummy", primary: .black, secondary: .green, accent: .blue)
    ]

    /// Loads themes from SwiftData and ensures defaults exist on first launch.
    func bootstrap(using context: ModelContext) {
        refreshThemes(using: context)
        ensureDefaultThemeExists(using: context)
    }

    func createTheme(from template: ThemeTemplate, using context: ModelContext) {
        createTheme(
            named: template.name,
            primary: template.primary,
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

        for template in defaultThemes {
            let theme = AppTheme(name: template.name, primary: template.primary, secondary: template.secondary, accent: template.accent)
            context.insert(theme)
        }

        refreshThemes(using: context)
    }

    private func refreshThemes(using context: ModelContext) {
        let descriptor = FetchDescriptor<AppTheme>(sortBy: [SortDescriptor(\AppTheme.name, order: .forward)])
        themes = (try? context.fetch(descriptor)) ?? []
    }
}
