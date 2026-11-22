//  StudyAppApp.swift
//  studyApp

import SwiftUI
import SwiftData

@main
struct StudyAppApp: App {
	//Root properties with some key information about what's happening in the app
	@State private var session = AppSession()
	@State private var tracking = StudyTrackingViewModel()

    var body: some Scene {
        WindowGroup {
			MainTabView(tracking: tracking)
				.environment(session)
        }
        .modelContainer(for: AppSchema.models)

    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
	MainTabView(tracking: StudyTrackingViewModel())
		.environment(AppSession())
		.modelContainer(
			for: [Subject.self, StudySession.self, StudyBreak.self, StudySection.self, SessionLocation.self, RemoteUser.self],
			inMemory: true
		)
}
