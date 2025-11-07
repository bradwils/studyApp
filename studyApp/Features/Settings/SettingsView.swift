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

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    NavigationLink {
                        Text("Account details go here.")
                    } label: {
                        Label("Account", systemImage: "person.crop.circle")
                    }

                    NavigationLink {
                        Text("Subscription settings go here.")
                    } label: {
                        Label("Subscription", systemImage: "creditcard")
                    }
                }

                Section(header: Text("Study")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Study reminders", systemImage: "bell.badge")
                    }

                    DatePicker("Reminder time",
                               selection: $studyReminderTime,
                               displayedComponents: .hourAndMinute)

                    Picker("Theme", selection: $preferredTheme) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
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
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
