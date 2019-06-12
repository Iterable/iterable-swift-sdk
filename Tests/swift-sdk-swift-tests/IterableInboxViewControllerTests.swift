//
//  IterableInboxViewControllerTests.swift
//  swift-sdk-swift-tests
//
//  Created by Jay Kim on 6/4/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableInboxViewControllerTests: XCTestCase {
    func testInitializers() {
        XCTAssertNotNil(IterableInboxViewController())
        
        XCTAssertNotNil(IterableInboxViewController(nibName: nil, bundle: nil))
        
        XCTAssertNotNil(IterableInboxViewController(style: .plain))
        
        XCTAssertNotNil(IterableInboxViewController(coder: NSKeyedUnarchiver(forReadingWith: Data())))
    }
}
