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
        .modelContainer(for: [AppTheme.self, Subject.self]) //store AppThemes & Subjects in SwiftData
        
    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
    MainTabView()
}
