//
//  NotificationExtensionTests.swift
//  notification-extension-tests
//
//  Created by Tapash Majumder on 7/6/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableAppExtensions

class NotificationExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDummy() {
        let dummy = TestFile()
        dummy.sayHello()
    }
    
}
