//  StudyAppApp.swift
//  studyApp

import SwiftUI
import SwiftData

@main
struct StudyAppApp: App {
	
	var build: String = "REVIEW_settingsAndSessionsPadding"
	
    var body: some Scene {
        WindowGroup {
			MainTabView(buildNum: build)
        }
        .modelContainer(for: [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self])
		
        
    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
    MainTabView(buildNum: "studyAppApp preview")
}
