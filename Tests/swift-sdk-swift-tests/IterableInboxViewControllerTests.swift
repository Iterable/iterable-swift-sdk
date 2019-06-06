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
        XCTAssertNil(inboxViewController1.navigationController?.tabBarItem.badgeValue)
        
        let inboxViewController2 = IterableInboxViewController(nibName: nil, bundle: nil)
        XCTAssertNil(inboxViewController2.navigationController?.tabBarItem.badgeValue)
        
        let inboxViewController3 = IterableInboxViewController(style: .plain)
        XCTAssertNil(inboxViewController3.navigationController?.tabBarItem.badgeValue)
        
        guard let inboxViewController4 = IterableInboxViewController(coder: NSKeyedUnarchiver(forReadingWith: Data())) else {
            XCTFail()
            return
        }
        
        XCTAssertNil(inboxViewController4.navigationController?.tabBarItem.badgeValue)
    }
    
//    private func createDefaultContent() -> IterableInAppContent {
//        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
//    }
}
