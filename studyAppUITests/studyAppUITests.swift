//
//  studyAppUITests.swift
//  studyAppUITests
//
//  Created by brad wils on 27/10/25.
//

import XCTest

final class studyAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Session start/pause/end flow

    @MainActor
    func testStartPauseEndSessionFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let mainButton = app.buttons["startPauseButton"]
        XCTAssertTrue(mainButton.waitForExistence(timeout: 5), "Start/Pause button should be visible on the Focus tab")
        XCTAssertEqual(mainButton.label, "Start")

        mainButton.tap()
        XCTAssertTrue(mainButton.waitForExistence(timeout: 2))
        XCTAssertEqual(mainButton.label, "Pause", "Tapping Start should begin a running session")

        mainButton.tap()
        XCTAssertEqual(mainButton.label, "Resume", "Tapping Pause should pause the running session")

        let endButton = app.buttons["endSessionButton"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 2), "End button should only appear while paused")

        endButton.tap()
        XCTAssertTrue(mainButton.waitForExistence(timeout: 2))
        XCTAssertEqual(mainButton.label, "Start", "Ending the session should return to the idle state")
        XCTAssertFalse(app.buttons["endSessionButton"].exists, "End button should disappear once the session has ended")
    }

    // MARK: - Add subject flow

    @MainActor
    func testAddSubjectFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Debug"].tap()

        let editSubjectsButton = app.buttons["editSubjectsButton"]
        XCTAssertTrue(editSubjectsButton.waitForExistence(timeout: 5))
        editSubjectsButton.tap()

        let nameField = app.textFields["subjectNameField"]
        let codeField = app.textFields["subjectCodeField"]
        let addButton = app.buttons["addSubjectButton"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))

        // Add button starts disabled until both fields have valid input.
        XCTAssertFalse(addButton.isEnabled)

        let uniqueCode = "T\(Int(Date().timeIntervalSince1970) % 1000)"
        nameField.tap()
        nameField.typeText("UI Test Subject")
        codeField.tap()
        codeField.typeText(uniqueCode)

        XCTAssertTrue(addButton.isEnabled, "Add button should enable once name and code are filled")
        addButton.tap()

        let newRow = app.staticTexts["UI Test Subject"]
        XCTAssertTrue(newRow.waitForExistence(timeout: 5), "Newly added subject should appear in the list")

        // Fields should clear after a successful add.
        XCTAssertEqual(nameField.value as? String, "Subject name")
    }
}
