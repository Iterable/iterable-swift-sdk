//
//  Created by Tapash Majumder on 8/10/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

class InboxUITests: XCTestCase {
    private static var timeout = 15.0
    private var app = XCUIApplication()
    
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testShowPopupInboxTab() {
        app.buttons["Show Popup Inbox Tab"].tap()
        
        let row1 = app.staticTexts["Title #1"]
        waitForElementToAppear(row1)
        row1.tap()
        
        let link1 = app.links["Click Here1"]
        waitForElementToAppear(link1)
        link1.tap()
        
        let row2 = app.staticTexts["Title #2"]
        waitForElementToAppear(row2)
        row2.tap()
        
        let link2 = app.links["Click Here2"]
        waitForElementToAppear(link2)
        link2.tap()
        
        waitForElementToAppear(row1)
    }
    
    func testShowNavInboxTab() {
        app.buttons["Show Nav Inbox Tab"].tap()
        
        let row1 = app.staticTexts["Title #1"]
        waitForElementToAppear(row1)
        row1.tap()
        
        let link1 = app.links["Click Here1"]
        waitForElementToAppear(app.buttons["Inbox"]) // Nav bar 'back' button
        waitForElementToAppear(link1)
        link1.tap()
        
        let row2 = app.staticTexts["Title #2"]
        waitForElementToAppear(row2)
        row2.tap()
        
        let link2 = app.links["Click Here2"]
        waitForElementToAppear(link2)
        link2.tap()
        
        waitForElementToAppear(row1)
    }
    
    private func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
        let exists = element.waitForExistence(timeout: InboxUITests.timeout)
        
        if fail, !exists {
            XCTFail("expected element: \(element)")
        }
    }
}
