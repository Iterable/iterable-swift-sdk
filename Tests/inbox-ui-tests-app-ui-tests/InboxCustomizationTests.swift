//
//
//  Created by Tapash Majumder on 1/7/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxCustomizationTests: XCTestCase, IterableInboxUITestsProtocol {
    lazy var app: XCUIApplication! = UITestsGlobal.application
    
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        clearNetwork()
    }
    
    func testCustomInboxCell() {
        gotoTab(.home)
        app.button(withText: "Load Dataset 2").tap()
        app.button(withText: "Show Custom Inbox 1").tap()
        
        app.tableCell(withText: "Buy Now").waitToAppear()
        
        app.button(withText: "Done").tap()
    }
    
    func testCustomInboxCellWithViewDelegateClassName() {
        gotoTab(.home)
        app.button(withText: "Load Dataset 2").tap()
        
        gotoTab(.customInbox)
        
        app.tableCell(withText: "Buy Now").waitToAppear()
    }
    
    func testImageLoading() {
        gotoTab(.home)
        app.button(withText: "Load Dataset 3").tap()
        
        gotoTab(.inbox)
        XCTAssertTrue(app.images["icon-image-message3-1"].exists)
    }
}
