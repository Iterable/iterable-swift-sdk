//
//  ClassExtensionsTests.swift
//  swift-sdk-swift-tests
//
//  Created by Jay Kim on 6/6/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class ClassExtensionsTests: XCTestCase {
    func testUIColorInit() {
        let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        guard let hexColor = UIColor(hex: "000000") else {
            XCTFail("ERROR: UIColor init by hex failed")
            return
        }
        
        XCTAssertEqual(hexColor, blackColor)
    }
}
