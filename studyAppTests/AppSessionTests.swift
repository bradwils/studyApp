//
//  AppSessionTests.swift
//  studyApp
//
//  Created by brad wils on 19/10/26.
//
import Testing
@testable import studyApp

/// Checks the default tab and changes to shared navigation state.
///
/// ## Declaration
///
/// ```swift
/// struct AppSessionTests
/// ```
///
/// Exercises the session directly with Swift Testing; visible tab navigation is
/// covered separately by the UI tests.
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
