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
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    func testRowSelect() {
        app.buttons["Show Inbox"].tap()
        
        sleep(1)
        
//        let inboxTableView = app.tables.element(boundBy: 0)
        
        
        
//        XCTAssertFalse()
    }
    
    
    
    private func createDefaultContent() -> IterableInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
}
