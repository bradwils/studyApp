import Foundation
import Combine

/// Holds UI state for the Settings tab, such as theme preference and subjects editor presentation.
final class SettingsViewModel: ObservableObject {
    enum ThemePreference: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system:
                return "System Default"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }
    }

    @Published var notificationsEnabled = true
    @Published var preferredTheme: ThemePreference = .system
    @Published var studyReminderTime = Date()
    @Published var isShowingSubjectsEditor = false

    func toggleSubjectsEditor() {
        isShowingSubjectsEditor.toggle()
    }

    func dismissSubjectsEditor() {
        isShowingSubjectsEditor = false
    }
}
