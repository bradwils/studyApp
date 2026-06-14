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
        .modelContainer(for: [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self, SessionLocation.self])
        
    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
    MainTabView()
}
