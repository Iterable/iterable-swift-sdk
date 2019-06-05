//
//  IterableInboxViewControllerUITests.swift
//  swift-sdk-swift-tests
//
//  Created by Jay Kim on 6/5/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

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
    
    
}
