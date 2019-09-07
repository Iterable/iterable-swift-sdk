//
//  Created by Tapash Majumder on 8/27/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxUITests: XCTestCase {
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        clearNetwork()
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
    
    func testTrackSession() {
        app.tabBars.buttons["Inbox"].tap()
        sleep(2)
        app.tabBars.buttons["Network"].tap()
        
        let request = serializableRequest(forEvent: String.ITBL_PATH_TRACK_INBOX_SESSION)
        let body = request.body! as! [String: Any]
        let impressions = body[keyPath: KeyPath(JsonKey.impressions)] as! [[String: Any]]
        XCTAssertEqual(impressions.count, 3)
    }
    
    func testSwipeToDelete() {
        gotoTab(.inbox)
        let count1 = app.tables.cells.count
        
        gotoTab(.home)
        app.tapButton(withName: "Add Inbox Message")
        
        gotoTab(.inbox)
        let count2 = app.tables.cells.count
        XCTAssertEqual(count2, count1 + 1)
        app.tableCell(withText: "title4").deleteSwipe()
        XCTAssertEqual(app.tables.cells.count, count1)
        
        gotoTab(.network)
        let dict = body(forEvent: String.ITBL_PATH_INAPP_CONSUME)
        XCTAssertEqual(dict[keyPath: KeyPath(JsonKey.deleteAction)] as! String, InAppDeleteSource.inboxSwipeLeft.jsonValue as! String)
    }
    
    func body(forEvent event: String) -> [String: Any] {
        let request = serializableRequest(forEvent: event)
        return request.body! as! [String: Any]
    }
    
    func serializableRequest(forEvent event: String) -> SerializableRequest {
        let serializedString = lastElement(forEvent: event).staticTexts["serializedString"].label
        return SerializableRequest.create(from: serializedString)
    }
    
    private static var timeout = 15.0
    
    private static var application: XCUIApplication = {
        let app = XCUIApplication()
        app.launch()
        return app
    }()
    
    // shortcut calculated property
    private var app: XCUIApplication {
        return InboxUITests.application
    }
    
    private enum TabName: String {
        case
            home = "Home",
            inbox = "Inbox",
            network = "Network"
    }
    
    private func clearNetwork() {
        gotoTab(.network)
        app.tapButton(withName: "Clear")
    }
    
    private func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
        let exists = element.waitForExistence(timeout: InboxUITests.timeout)
        
        if fail, !exists {
            XCTFail("expected element: \(element)")
        }
    }
    
    private func lastElement(forEvent event: String) -> XCUIElement {
        let eventRows = app.tables.cells.containing(.staticText, identifier: String.ITBL_API_PATH + event)
        let count = eventRows.count
        return eventRows.element(boundBy: count - 1)
    }
    
    private func gotoTab(_ tabName: TabName) {
        app.gotoTab(tabName.rawValue)
    }
}
