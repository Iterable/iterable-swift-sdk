//
//  Created by Tapash Majumder on 8/27/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxUITests: XCTestCase {
    private static var timeout = 15.0
    
    static var application: XCUIApplication = {
        let app = XCUIApplication()
        app.launch()
        return app
    }()
    
    // shortcut calculated property
    private var app: XCUIApplication {
        return InboxUITests.application
    }
    
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }
    
    func testShowInboxMessages() {
        app.tabBars.buttons["Inbox"].tap()
        
        let row1 = app.staticTexts["title1"]
        waitForElementToAppear(row1)
        row1.tap()
        
        let link1 = app.links["Click Here1"]
        waitForElementToAppear(link1)
        link1.tap()
        
        let row2 = app.staticTexts["title2"]
        waitForElementToAppear(row2)
        row2.tap()
        
        let link2 = app.links["Click Here2"]
        waitForElementToAppear(link2)
        link2.tap()
        
        waitForElementToAppear(row1)
    }
    
    func testShowInboxOnButtonClick() {
        app.tabBars.buttons["Home"].tap()
        
        app.buttons["Show Inbox"].tap()
        
        let row1 = app.staticTexts["title1"]
        waitForElementToAppear(row1)
        row1.tap()
        
        let link1 = app.links["Click Here1"]
        waitForElementToAppear(app.buttons["Inbox"]) // Nav bar 'back' button
        waitForElementToAppear(link1)
        link1.tap()
        
        let row2 = app.staticTexts["title2"]
        waitForElementToAppear(row2)
        row2.tap()
        
        let link2 = app.links["Click Here2"]
        waitForElementToAppear(link2)
        link2.tap()
        
        waitForElementToAppear(row1)
        
        app.navigationBars.buttons["Done"].tap()
    }
    
    private func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
        let exists = element.waitForExistence(timeout: InboxUITests.timeout)
        
        if fail, !exists {
            XCTFail("expected element: \(element)")
        }
    }
}
