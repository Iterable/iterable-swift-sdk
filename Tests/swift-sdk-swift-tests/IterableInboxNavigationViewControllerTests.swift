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
        
        XCTAssertNotNil(inboxNavigationVC.viewControllers[0] as? IterableInboxViewController)
    }
    
    func testCustomCellNibName() {
        let inboxNavigationVC = IterableInboxNavigationViewController()
        
        let cellNibName = "TestTableViewCell"
        
        inboxNavigationVC.cellNibName = cellNibName
        
        XCTAssertEqual((inboxNavigationVC.viewControllers[0] as? IterableInboxViewController)?.cellNibName, cellNibName)
    }
    
    func testDoneButtonPressed() {
//        let inboxNavigationVC = IterableInboxNavigationViewController()
//        
//        if let doneAction = inboxNavigationVC.navigationItem.rightBarButtonItem?.action {
//            perform(doneAction)
//        }
    }
}
