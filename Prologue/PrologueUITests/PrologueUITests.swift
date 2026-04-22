//
//  PrologueUITests.swift
//  PrologueUITests
//
//  Created by James Clabby on 4/19/26.
//

import XCTest

// MARK: - Helpers

private extension XCUIApplication {
    static func makeUnauthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()
        return app
    }

    static func makeAuthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["UI_TESTING_AUTHENTICATED"] = "1"
        app.launch()
        return app
    }
}

// MARK: - Login screen

final class LoginScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .makeUnauthenticated()
    }
    override func tearDownWithError() throws { app = nil }

    func testLoginTitleAppears() {
        XCTAssertTrue(app.staticTexts["Prologue"].waitForExistence(timeout: 3))
    }

    func testGoogleSignInButtonAppears() {
        XCTAssertTrue(app.buttons["Continue with Google"].waitForExistence(timeout: 3))
    }

    func testSubtitleAppears() {
        XCTAssertTrue(
            app.staticTexts["Your reading life, beautifully tracked."]
                .waitForExistence(timeout: 3)
        )
    }
}

// MARK: - Tab bar

final class TabBarTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .makeAuthenticated()
    }
    override func tearDownWithError() throws { app = nil }

    func testAllTabsExist() {
        XCTAssertTrue(app.tabBars.buttons["Library"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["Search"].exists)
        XCTAssertTrue(app.tabBars.buttons["Friends"].exists)
        XCTAssertTrue(app.tabBars.buttons["Insights"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
    }

    func testLibraryTabIsSelectedByDefault() {
        XCTAssertTrue(app.navigationBars["My Library"].waitForExistence(timeout: 3))
    }
}

// MARK: - LibraryView

final class LibraryViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .makeAuthenticated()
        XCTAssertTrue(app.navigationBars["My Library"].waitForExistence(timeout: 3))
    }
    override func tearDownWithError() throws { app = nil }

    func testNavigationTitle() {
        XCTAssertTrue(app.navigationBars["My Library"].exists)
    }

    func testSegmentedPickerHasAllStatusOptions() {
        XCTAssertTrue(app.buttons["Want to Read"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["In Progress"].exists)
        XCTAssertTrue(app.buttons["Read"].exists)
        XCTAssertTrue(app.buttons["Did Not Finish"].exists)
    }

    func testInProgressIsSelectedByDefault() {
        XCTAssertTrue(app.buttons["In Progress"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["In Progress"].isSelected)
    }

    func testSwitchingStatusShowsEmptyState() {
        for label in ["Want to Read", "Read", "Did Not Finish"] {
            app.buttons[label].tap()
            XCTAssertTrue(app.staticTexts["No Books Here"].waitForExistence(timeout: 3))
        }
    }

}

// MARK: - ProfileTab

final class ProfileTabTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .makeAuthenticated()
        XCTAssertTrue(app.tabBars.buttons["Profile"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 3))
    }
    override func tearDownWithError() throws { app = nil }

    func testNavigationTitle() {
        XCTAssertTrue(app.navigationBars["Profile"].exists)
    }

    func testSignOutButtonExists() {
        app.swipeUp()
        XCTAssertTrue(app.buttons["Sign Out"].waitForExistence(timeout: 3))
    }

    func testDeleteAccountButtonExists() {
        app.swipeUp()
        XCTAssertTrue(app.buttons["Delete Account"].waitForExistence(timeout: 3))
    }

    func testEditProfileLinkExists() {
        XCTAssertTrue(app.buttons["Edit Profile"].waitForExistence(timeout: 3))
    }
}

// MARK: - InsightsView

final class InsightsViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .makeAuthenticated()
        XCTAssertTrue(app.tabBars.buttons["Insights"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Insights"].tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 3))
    }
    override func tearDownWithError() throws { app = nil }

    func testNavigationTitle() {
        XCTAssertTrue(app.navigationBars["Insights"].exists)
    }

    func testAnnualGoalSectionExists() {
        XCTAssertTrue(app.staticTexts["Annual Goal"].waitForExistence(timeout: 3))
    }

    func testSetGoalButtonExists() {
        XCTAssertTrue(app.buttons["Set Goal"].waitForExistence(timeout: 3))
    }

    func testStatCardsExist() {
        XCTAssertTrue(app.staticTexts["Books Read"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Words Read"].exists)
    }

    func testReadingVolumeChartSectionExists() {
        XCTAssertTrue(app.staticTexts["Reading Volume"].waitForExistence(timeout: 3))
    }

    func testChartScopePickerHasAllSegments() {
        XCTAssertTrue(app.buttons["Week"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Month"].exists)
        XCTAssertTrue(app.buttons["Year"].exists)
    }

    func testTappingSetGoalOpensAlert() {
        app.buttons["Set Goal"].tap()
        XCTAssertTrue(app.alerts["Annual Reading Goal"].waitForExistence(timeout: 3))
    }

    func testGoalAlertHasTextField() {
        app.buttons["Set Goal"].tap()
        let alert = app.alerts["Annual Reading Goal"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.textFields["Number of books"].exists)
    }

    func testGoalAlertHasSaveAndCancel() {
        app.buttons["Set Goal"].tap()
        let alert = app.alerts["Annual Reading Goal"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.buttons["Save"].exists)
        XCTAssertTrue(alert.buttons["Cancel"].exists)
    }

    func testCancelDismissesGoalAlert() {
        app.buttons["Set Goal"].tap()
        let alert = app.alerts["Annual Reading Goal"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Cancel"].tap()
        XCTAssertFalse(app.alerts["Annual Reading Goal"].exists)
    }
}

// MARK: - SocialView

final class SocialViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .makeAuthenticated()
        XCTAssertTrue(app.tabBars.buttons["Friends"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Friends"].tap()
        XCTAssertTrue(app.navigationBars["Friends"].waitForExistence(timeout: 3))
    }
    override func tearDownWithError() throws { app = nil }

    func testNavigationTitle() {
        XCTAssertTrue(app.navigationBars["Friends"].exists)
    }

    func testSearchBarExists() {
        XCTAssertTrue(
            app.searchFields["Search readers\u{2026}"].waitForExistence(timeout: 3)
        )
    }

    func testEmptyFriendsMessageExists() {
        XCTAssertTrue(
            app.staticTexts["No friends yet. Search for readers above."]
                .waitForExistence(timeout: 3)
        )
    }
}

// MARK: - SearchView

final class SearchViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .makeAuthenticated()
        XCTAssertTrue(app.tabBars.buttons["Search"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Discover"].waitForExistence(timeout: 3))
    }
    override func tearDownWithError() throws { app = nil }

    func testNavigationTitle() {
        XCTAssertTrue(app.navigationBars["Discover"].exists)
    }

    func testSearchBarExists() {
        XCTAssertTrue(
            app.searchFields["Title, author, or ISBN\u{2026}"]
                .waitForExistence(timeout: 3)
        )
    }

    func testBarcodeScannerButtonExists() {
        XCTAssertTrue(app.buttons["Scan Barcode"].waitForExistence(timeout: 3))
    }
}
