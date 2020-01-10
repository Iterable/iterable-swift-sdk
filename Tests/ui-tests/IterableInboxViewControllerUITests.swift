//
//  Created by Jay Kim on 6/5/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableInboxViewControllerUITests: XCTestCase {
    private static var timeout = 15.0
    private var app: XCUIApplication!
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    override func setUp() {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
    }
    
    func testMessageDeleteButton() {
        app.buttons["Show Inbox"].tap()
        
        let firstCell = app.tables.cells.firstMatch
        
        firstCell.swipeLeft()
        
        app.tables.buttons["Delete"].tap()
        
        XCTAssertFalse(firstCell.exists)
    }
    
    func testMesageDeleteSwipe() {
        app.buttons["Show Inbox"].tap()
        
        let firstCell = app.tables.cells.firstMatch
        
        let startPoint = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.0))
        let endPoint = firstCell.coordinate(withNormalizedOffset: .zero)
        
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
        
        XCTAssertFalse(firstCell.exists)
    }
}
