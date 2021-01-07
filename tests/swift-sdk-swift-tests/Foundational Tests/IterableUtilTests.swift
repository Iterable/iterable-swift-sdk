//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableUtilTests: XCTestCase {
    func testEmptyDescribe() {
        XCTAssertEqual(IterableUtil.describe(), "")
    }
    
    func testSingleElementDescribe() {
        XCTAssertEqual(IterableUtil.describe("asdf"), "asdf: nil")
    }
    
    func testDifferentPairSeparator() {
        XCTAssertEqual(IterableUtil.describe("123", "321", pairSeparator: "#"), "123#321")
    }
    
    func testDifferentGeneralSeparator() {
        XCTAssertEqual(IterableUtil.describe("1", "2", "3", "4", separator: "|"), "1: 2|3: 4")
    }
}
