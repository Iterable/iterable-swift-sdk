//
//  SwiftSampleAppUITest.swift
//  SwiftSampleAppUITest
//
//  Created by Justin Yu on 12/4/23.
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

final class SwiftSampleAppUITest: XCUITestBase {    
    func testElementsVisible() {
        let app = XCUIApplication()

        XCTAssertTrue(app.staticTexts["Coffees"].exists)
    }
}
