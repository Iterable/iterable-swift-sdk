//
//  SwiftSampleAppUITest.swift
//  SwiftSampleAppUITest
//
//  Created by Justin Yu on 12/4/23.
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

class SwiftSampleAppUITest: XCUITestBase {
    func testElementsVisible() {
        XCTAssertTrue(app.staticTexts["Coffees"].exists)
    }
}
