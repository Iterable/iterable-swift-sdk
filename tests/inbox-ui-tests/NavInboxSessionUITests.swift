//
//  Copyright © 2022 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class NavInboxSessionUITests: XCTestCase, IterableInboxUITestsProtocol {
    lazy var app: XCUIApplication! = UITestsGlobal.application
    
    // Skipping these tests until we have the time to update them.
    // https://iterable.atlassian.net/browse/MOB-10461
    
//    override func setUp() {
//        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
//        app = XCUIApplication()
//        app.launch()
//        clearNetwork()
//    }
//    
//    func test_simple_tab_switch() {
//        gotoTab(.home)
//        app.button(withText: "Load Dataset 1").tap()
//        
//        gotoTab(.customInbox)
//        sleep(1)
//        gotoTab(.network)
//
//        XCTAssertEqual(count(forEvent: Const.Path.trackInboxSession), 1)
//
//        let dict = body(forEvent: Const.Path.trackInboxSession)
//        let impressions = dict[keyPath: KeyPath(keys: JsonKey.impressions)] as! [[String: Any]]
//        XCTAssertEqual(impressions.count, 3)
//    }
//
//    func test_view_messages_continues_session() {
//        gotoTab(.home)
//        app.button(withText: "Load Dataset 1").tap()
//        
//        gotoTab(.customInbox)
//        // view first message
//        app.tableCell(withText: "title1").waitToAppear().tap()
//        app.navButton(withText: "Custom Inbox").waitToAppear().tap()
//        // view second message
//        app.tableCell(withText: "title2").waitToAppear().tap()
//        app.navButton(withText: "Custom Inbox").waitToAppear().tap()
//        
//        gotoTab(.network)
//        XCTAssertEqual(count(forEvent: Const.Path.trackInboxSession), 1)
//
//        let dict = body(forEvent: Const.Path.trackInboxSession)
//        let impressions = dict[keyPath: KeyPath(keys: JsonKey.impressions)] as! [[String: Any]]
//        XCTAssertEqual(impressions.count, 3)
//    }
//
//    func test_currently_viewing_message_continues_session() {
//        gotoTab(.home)
//        app.button(withText: "Load Dataset 1").tap()
//        
//        gotoTab(.customInbox)
//        // view first message
//        app.tableCell(withText: "title1").waitToAppear().tap()
//        gotoTab(.network)
//        app.swipeUp()
//        app.swipeUp()
//        XCTAssertEqual(count(forEvent: Const.Path.trackInboxSession), 1)
//
//        let dict = body(forEvent: Const.Path.trackInboxSession)
//        let impressions = dict[keyPath: KeyPath(keys: JsonKey.impressions)] as! [[String: Any]]
//        XCTAssertEqual(impressions.count, 3)
//
//        // remove the showing message
//        gotoTab(.customInbox)
//        app.navButton(withText: "Custom Inbox").waitToAppear().tap()
//    }
//
//    func test_back_to_viewing_message_starts_new_session() {
//        gotoTab(.home)
//        app.button(withText: "Load Dataset 1").tap()
//        
//        gotoTab(.customInbox)
//        // view first message
//        app.tableCell(withText: "title1").waitToAppear().tap()
//        gotoTab(.network)
//        app.swipeUp()
//        app.swipeUp()
//        XCTAssertEqual(count(forEvent: Const.Path.trackInboxSession), 1)
//
//        // back to inbox
//        gotoTab(.customInbox)
//        gotoTab(.network)
//        XCTAssertEqual(count(forEvent: Const.Path.trackInboxSession), 2)
//
//        // remove the showing message
//        gotoTab(.customInbox)
//        app.navButton(withText: "Custom Inbox").waitToAppear().tap()
//    }
}
