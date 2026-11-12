//
//  AppSessionTests.swift
//  studyApp
//
//  Created by brad wils on 19/10/26.
//
import Testing
@testable import studyApp

///AppSession are based on general behaviour - not logic based, but thinks like the TabView behaviour.
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
