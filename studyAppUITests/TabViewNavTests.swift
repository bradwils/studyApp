//
//  TabViewNavTests.swift
//  studyAppUITests
//
//  Created by brad wils on 19/10/26.
//

import XCTest

final class TabViewNavTests: XCTestCase {

	//case xyz = <TabView button label>
	//defining all expected options for the navbar
	enum Destination: String, CaseIterable {
		case focus = "Focus"
		case debug = "Debug"
		case social = "Social"
		case groups = "Groups"
		case sessions = "Sessions"

		// Focus has no nav title, so it is identified by its start/pause button instead.
		@MainActor
		func destinationElement(in app: XCUIApplication) -> XCUIElement {
			switch self {
			case .focus: app.buttons["startPauseButton"] //check for a button by accessibilityIdentifier due to no NavTitle in use
			case .debug: app.navigationBars["Settings"] //check for NavTitle of Settings
			case .social: app.navigationBars["Social"] //etc
			case .groups: app.navigationBars["Groups"]
			case .sessions: app.navigationBars["Sessions"]
			}
		}
	}

	override func setUp() {
		continueAfterFailure = false
	}

	
	//Note - currently works BASED ON THE ASSUMPTION OF NavigationTitle being used for ALL ELEMENTS (except for focus, where there is currently none).
	//This will likely require some revamping later on to use better ways of knowing where we are.
	@MainActor
	func testTabsShowTheirDestination() {
		for destination in Destination.allCases {
			XCTContext.runActivity(named: "Tapping \(destination.rawValue) shows its destination") { _ in
				let app = XCUIApplication()
				app.launch()

				// The app opens on Focus, so move away first or the Focus case proves nothing.
				let awayTab: Destination = destination == .sessions ? .social : .sessions
				app.tabBars.buttons[awayTab.rawValue].tap()

				app.tabBars.buttons[destination.rawValue].tap()
				XCTAssertTrue(destination.destinationElement(in: app).waitForExistence(timeout: 3))
				app.terminate()
			}
		}
	}
}
