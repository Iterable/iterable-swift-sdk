//
//  Created by Tapash Majumder on 8/27/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxUITests: XCTestCase, IterableInboxUITestsProtocol {
    var app: XCUIApplication!
    
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        clearNetwork()
    }
    
    func testShowInboxMessages() {
        gotoTab(.inbox)
        
        app.tableCell(withText: "title1").tap()
        
        app.link(withText: "Click Here1").waitToAppear().tap()
        
        app.tableCell(withText: "title2").waitToAppear().tap()
        
        app.link(withText: "Click Here2").waitToAppear().tap()
        
        app.tableCell(withText: "title1").waitToAppear()
    }
    
    func testShowInboxOnButtonClick() {
        gotoTab(.home)
        
        app.button(withText: "Show Inbox").tap()
        
        app.tableCell(withText: "title1").waitToAppear().tap()
        
        app.link(withText: "Click Here1").waitToAppear()
        app.navButton(withText: "Inbox").waitToAppear() // Nav bar 'back' button
        app.link(withText: "Click Here1").tap()
        
        app.tableCell(withText: "title2").waitToAppear().tap()
        app.link(withText: "Click Here2").waitToAppear().tap()
        
        app.tableCell(withText: "title1").waitToAppear()
        app.navButton(withText: "Done").tap()
    }
    
    func testTrackSession() {
        gotoTab(.inbox)
        sleep(2)
        gotoTab(.network)
        
        let dict = body(forEvent: Const.Path.trackInboxSession)
        let impressions = dict[keyPath: KeyPath(JsonKey.impressions)] as! [[String: Any]]
        XCTAssertEqual(impressions.count, 3)
    }
    
    func testDeleteActionSwipeToDelete() {
        gotoTab(.inbox)
        let count1 = app.tables.cells.count
        
        gotoTab(.home)
        app.button(withText: "Add Inbox Message").tap()
        
        gotoTab(.inbox)
        let count2 = app.tables.cells.count
        XCTAssertEqual(count2, count1 + 1)
        app.lastCell().deleteSwipe()
        XCTAssertEqual(app.tables.cells.count, count1)
        
        gotoTab(.network)
        let dict = body(forEvent: Const.Path.inAppConsume)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.deleteAction), value: InAppDeleteSource.inboxSwipe.jsonValue as! String, inDictionary: dict)
    }
    
    func testDeleteActionDeleteButton() {
        gotoTab(.inbox)
        let count1 = app.tables.cells.count
        
        gotoTab(.home)
        app.button(withText: "Add Inbox Message").tap()
        
        gotoTab(.inbox)
        let count2 = app.tables.cells.count
        XCTAssertEqual(count2, count1 + 1)
        
        app.lastCell().tap()
        app.link(withText: "Delete").waitToAppear().tap()
        
        app.tableCell(withText: "title1").waitToAppear()
        XCTAssertEqual(app.tables.cells.count, count1)
        
        gotoTab(.network)
        let dict = body(forEvent: Const.Path.inAppConsume)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.deleteAction), value: InAppDeleteSource.deleteButton.jsonValue as! String, inDictionary: dict)
    }
    
    func testPullToRefresh() {
        gotoTab(.home)
        app.button(withText: "Add Message To Server").tap()
        
        gotoTab(.inbox)
        let count1 = app.tables.cells.count
        app.tableCell(withText: "title1").pullToRefresh()
        
        let count2 = app.tables.cells.count
        XCTAssertEqual(count2, count1 + 1)
        
        app.lastCell().tap()
        app.link(withText: "Delete").waitToAppear().tap()
        
        app.tableCell(withText: "title1").waitToAppear()
        XCTAssertEqual(app.tables.cells.count, count1)
    }
}
