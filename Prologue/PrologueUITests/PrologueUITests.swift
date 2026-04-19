//
//  PrologueUITests.swift
//  PrologueUITests
//
//  Created by James Clabby on 4/19/26.
//

import XCTest

final class PrologueUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLoginScreenAppears() throws {
        // With no authenticated session the login screen should be visible
        XCTAssert(app.staticTexts["Prologue"].exists)
        XCTAssert(app.buttons["Continue with Google"].exists)
    }
}
