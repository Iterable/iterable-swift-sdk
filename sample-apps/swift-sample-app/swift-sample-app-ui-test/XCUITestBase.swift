//
//  XCUITestBase.swift
//  SwiftSampleAppUITest
//
//  Created by Justin Yu on 12/4/23.
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

class XCUITestBase: XCTestCase {
    var app =  XCUIApplication()
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }
        
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
}
