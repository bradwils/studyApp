//  StudyAppApp.swift
//  studyApp

import SwiftUI
import SwiftData

@main
struct StudyAppApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [StudySession.self, StudyBreak.self, SessionLocation.self, AppTheme.self])
    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
    MainTabView()
}
