//  StudyAppApp.swift
//  studyApp

import SwiftUI
import SwiftData

@main
struct StudyAppApp: App {
	//Root properties with some key information about what's happening in the app
	@State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
			MainTabView()
				.environment(session)
        }
        .modelContainer(for: AppSchema.models)

    }
}

#Preview("App Entry") {
    // Preview the main entry point of the app
	MainTabView()
		.environment(AppSession())
}
