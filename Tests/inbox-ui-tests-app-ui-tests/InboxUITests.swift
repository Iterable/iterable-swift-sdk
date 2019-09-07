//
//  Created by Tapash Majumder on 8/27/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxUITests: XCTestCase, IterableInboxUITestsProtocol {
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
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
        
        app.tapButton(withName: "Show Inbox")
        
        app.tableCell(withText: "title1").waitToAppear().tap()
        
        app.link(withText: "Click Here1").waitToAppear()
        app.navButton(withName: "Inbox").waitToAppear() // Nav bar 'back' button
        app.link(withText: "Click Here1").tap()
        
        app.tableCell(withText: "title2").waitToAppear().tap()
        app.link(withText: "Click Here2").waitToAppear().tap()
        
        app.tableCell(withText: "title1").waitToAppear()
        app.tapNavButton(withName: "Done")
    }
    
    func testTrackSession() {
        gotoTab(.inbox)
        sleep(2)
        gotoTab(.network)
        
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
}
