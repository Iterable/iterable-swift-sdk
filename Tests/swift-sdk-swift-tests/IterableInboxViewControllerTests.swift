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
        let inboxViewController1 = IterableInboxViewController()
        XCTAssertEqual(inboxViewController1.tableView.numberOfSections, 1)
        
        let inboxViewController2 = IterableInboxViewController(nibName: nil, bundle: nil)
        XCTAssertEqual(inboxViewController2.tableView.numberOfSections, 1)
        
        let inboxViewController3 = IterableInboxViewController(style: .plain)
        XCTAssertEqual(inboxViewController3.tableView.numberOfSections, 1)
        
        guard let inboxViewController4 = IterableInboxViewController(coder: NSKeyedUnarchiver(forReadingWith: Data())) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(inboxViewController4.tableView.numberOfSections, 1)
    }
    
//    private func createDefaultContent() -> IterableInAppContent {
//        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
//    }
}
