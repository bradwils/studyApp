//  StudyAppApp.swift
//  studyApp

import SwiftUI
import SwiftData

@main
struct StudyAppApp: App {
	
	var build: String = "master"
	
    var body: some Scene {
        WindowGroup {
			MainTabView(identifier: build)
        }
        .modelContainer(for: [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self, RemoteUser.self])
        
    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
	MainTabView(identifier: "preview")
}
