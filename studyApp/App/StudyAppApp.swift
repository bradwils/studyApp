//  StudyAppApp.swift
//  studyApp

import SwiftUI
import SwiftData

@main
struct StudyAppApp: App {
	@State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
			MainTabView()
				.environment(session)
        }
        .modelContainer(for: [AppTheme.self, Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self, RemoteUser.self])

    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
	MainTabView()
		.environment(AppSession())
}
