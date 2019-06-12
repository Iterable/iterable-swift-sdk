//
//  IterableInboxViewControllerUITests.swift
//  swift-sdk-swift-tests
//
//  Created by Jay Kim on 6/5/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableInboxViewControllerUITests: XCTestCase {
    private static var timeout = 15.0
    
    static var application: XCUIApplication = {
        let app = XCUIApplication()
        app.launch()
        return app
    }()
    
    // shortcut calculated property
    private var app: XCUIApplication {
        return IterableInboxViewControllerUITests.application
    }
    
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    override func tearDown() {
        app.launch()
    }
    
    func testMessageDeleteButton() {
        app.buttons["Show Inbox"].tap()
        
        sleep(2)
        
        let firstCell = app.tables.cells.firstMatch
        
        firstCell.swipeLeft()
        
        app.tables.buttons["Delete"].tap()
        
        XCTAssertFalse(firstCell.exists)
    }
    
    func testMesageDeleteSwipe() {
        app.buttons["Show Inbox"].tap()
        
        sleep(2)
        
        let firstCell = app.tables.cells.firstMatch
        
        let startPoint = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.0))
        let endPoint = firstCell.coordinate(withNormalizedOffset: .zero)
        
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
        
        XCTAssertFalse(firstCell.exists)
    }
}
