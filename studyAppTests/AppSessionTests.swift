//
//  AppSessionTests.swift
//  studyApp
//
//  Created by brad wils on 19/10/26.
//
import Testing
@testable import studyApp

struct AppSessionTests {

	@Test("AppSession starts on the Focus tab")
	func defaultsToFocusTab() {
		#expect(AppSession().selectedTab == .focus)
	}

	@Test("Changing selectedTab is reflected on the session", arguments: [AppTab.debug, .social, .groups, .sessions])
	func selectedTabIsSettable(tab: AppTab) {
		let session = AppSession()
		session.selectedTab = tab
		#expect(session.selectedTab == tab)
	}
}
