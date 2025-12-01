//  StudyAppApp.swift
//  studyApp

import SwiftUI

@main
struct StudyAppApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
    MainTabView()
}
