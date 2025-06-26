//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxCustomizationTests: XCTestCase, IterableInboxUITestsProtocol {
    internal var app: XCUIApplication!
    
    // Skipping these tests until we have the time to update them.
    // https://iterable.atlassian.net/browse/MOB-10461
    
//    override func setUp() {
//        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
//        app = XCUIApplication()
//        app.launch()
//        
//        clearNetwork()
//    }
//    
//    func testCustomInboxCell() {
//        gotoTab(.home)
//        app.button(withText: "Load Dataset 2").tap()
//        app.button(withText: "Show Custom Inbox 1").tap()
//        
//        app.tableCell(withText: "Buy Now").waitToAppear()
//        
//        app.button(withText: "Done").tap()
//    }
//    
//    func testCustomInboxCellWithViewDelegateClassName() {
//        gotoTab(.home)
//        app.button(withText: "Load Dataset 2").tap()
//        
//        gotoTab(.customInbox)
//        
//        app.tableCell(withText: "Buy Now").waitToAppear()
//    }
//    
//    func testImageLoading() {
//        gotoTab(.home)
//        app.button(withText: "Load Dataset 3").tap()
//        
//        gotoTab(.inbox)
//        XCTAssertTrue(app.images["icon-image-message3-1"].exists)
//    }
}
