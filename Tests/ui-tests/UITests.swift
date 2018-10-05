//
//
//  Created by Tapash Majumder on 9/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest


class UITests: XCTestCase {
    static var application: XCUIApplication = {
        let app = XCUIApplication()
        app.launch()
        return app
    }()

    // shortcut calculated property
    private var app: XCUIApplication {
        return UITests.application
    }
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testShowSystemNotification() {
        // Tap the Left Button
        app.buttons["Show System Notification"].tap()

        let alert = app.alerts.element
        waitForElementToAppear(alert)
        
        XCTAssertTrue(alert.staticTexts["Zee Title"].exists)
        XCTAssertTrue(alert.staticTexts["Zee Body"].exists)

        app.buttons["Left Button"].tap()

        waitForElementToAppear(app.staticTexts["Left Button"])

        app.buttons["Show System Notification"].tap()
        waitForElementToAppear(alert)

        // Tap the Right Button
        app.buttons["Right Button"].tap()
        waitForElementToAppear(app.staticTexts["Right Button"])
    }

    func testShowInApp1() {
        // Tap the Left Button
        app.buttons["Show InApp#1"].tap()
        
        let clickMe = app.links["Click Me"]
        waitForElementToAppear(clickMe)
        clickMe.tap()

        let callbackUrl = self.app.staticTexts["http://website/resource#something"]
        waitForElementToAppear(callbackUrl)
    }

    func testShowInApp2() {
        // Tap the Left Button
        app.buttons["Show InApp#2"].tap()
        
        let clickHere = app.links["Click Here"]
        _  = waitForElementToAppear(clickHere)
        clickHere.tap()

        let callbackLink = app.staticTexts["https://www.google.com/q=something"]
        waitForElementToAppear(callbackLink)
    }

    private func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
        let predicate = NSPredicate(format: "exists == true")
        let expectation1 = expectation(for: predicate, evaluatedWith: element,
                                      handler: nil)
        
        let result = XCTWaiter().wait(for: [expectation1], timeout: 15)

        if fail && result != .completed {
            XCTFail("expected element: \(element)")
        }
    }
}
