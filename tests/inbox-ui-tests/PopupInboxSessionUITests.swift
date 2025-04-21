//
//  Copyright © 2022 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class PopupInboxSessionUITests: XCTestCase, IterableInboxUITestsProtocol {
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
//        gotoTab(.inbox)
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
//        gotoTab(.inbox)
//        // view first message
//        app.tableCell(withText: "title1").waitToAppear().tap()
//        app.link(withText: "Click Here1").waitToAppear().tap()
//        // view second message
//        app.tableCell(withText: "title2").waitToAppear().tap()
//        app.link(withText: "Click Here2").waitToAppear().tap()
//        
//        gotoTab(.network)
//        app.swipeUp()
//        app.swipeUp()
//        XCTAssertEqual(count(forEvent: Const.Path.trackInboxSession), 1)
//
//        let dict = body(forEvent: Const.Path.trackInboxSession)
//        let impressions = dict[keyPath: KeyPath(keys: JsonKey.impressions)] as! [[String: Any]]
//        XCTAssertEqual(impressions.count, 3)
//    }
}
