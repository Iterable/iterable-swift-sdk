//
//
//  Created by Tapash Majumder on 9/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

class UITests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testShowSystemNotification() {
        // Tap the Left Button
        app.buttons["Show System Notification"].tap()

        let alert = app.alerts.element
        XCTAssertTrue(alert.exists)
        
        XCTAssertTrue(alert.staticTexts["Zee Title"].exists)
        XCTAssertTrue(alert.staticTexts["Zee Body"].exists)

        let leftButton = app.buttons["Left Button"]
        leftButton.tap()

        XCTAssertTrue(app.staticTexts["Left Button"].exists)

        // Tap the Right Button
        app.buttons["Show System Notification"].tap()
        
        
        let rightButton = app.buttons["Right Button"]
        rightButton.tap()
        
        XCTAssertTrue(app.staticTexts["Right Button"].exists)
    }

}
