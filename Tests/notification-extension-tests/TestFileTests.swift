//
//  TestFileTests.swift
//  notification-extension-tests
//
// We need this file due to a codecov.io bug where no coverage is generated if
// we have just one swift file. We add this file to generate coverage.
// TODO: in future remove this file when the codecov bug is fixed.

//  Created by Tapash Majumder on 7/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableAppExtensions

class TestFileTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // This is just a test so that
    func testSayHello() {
        let testFile = TestFile()
        testFile.sayHello()
    }
}
