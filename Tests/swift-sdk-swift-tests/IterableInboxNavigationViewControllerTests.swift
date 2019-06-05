//
//  IterableInboxNavigationViewControllerTests.swift
//  swift-sdk-swift-tests
//
//  Created by Jay Kim on 6/4/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableInboxNavigationViewControllerTests: XCTestCase {
    func testInitWithNoRootViewController() {
        let inboxNavigationVC = IterableInboxNavigationViewController()
        
        XCTAssertTrue(inboxNavigationVC.viewControllers.count > 0)
    }
    
    func testCustomCellNibName() {
        let inboxNavigationVC = IterableInboxNavigationViewController()
        
        let cellNibName = "TestTableViewCell"
        
        inboxNavigationVC.cellNibName = cellNibName
        
        XCTAssertEqual((inboxNavigationVC.viewControllers[0] as? IterableInboxViewController)?.cellNibName, cellNibName)
    }
}
