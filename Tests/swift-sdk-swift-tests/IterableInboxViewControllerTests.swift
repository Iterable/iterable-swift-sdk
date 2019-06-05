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
    
//    func testOnInboxChangedNotification() {
//        let mockInAppFetcher = MockInAppFetcher()
//
//        IterableAPI.initializeForTesting(inAppFetcher: mockInAppFetcher)
//
//        let inboxViewController = IterableInboxViewController()
//
//        var messages: [IterableInAppMessage] = []
//
//        let message1 = IterableInAppMessage(messageId: "34g87hg982", campaignId: "23g8jer2ia42d", content: createDefaultContent())
//        messages.append(message1)
//
//        mockInAppFetcher.mockMessagesAvailableFromServer(messages: messages) {
//            XCTAssertNil(inboxViewController.navigationController?.tabBarItem.badgeValue)
//
//            // on Travis CI, this notification post does not complete fast enough before the condition checker
//            NotificationCenter.default.post(name: .iterableInboxChanged, object: nil)
//
//            XCTAssertEqual(inboxViewController.navigationController?.tabBarItem.badgeValue, "\(messages.count)")
//        }
//
//        // either: "remove" message1 and test for nil again
//        // or add a couple more messages to test for what the count is
//    }
    
    func testInboxCellConfiguration() {
        let mockInAppFetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(inAppFetcher: mockInAppFetcher)
        
        var messages: [IterableInAppMessage] = []
        
        let message1Date = Date()
        let message1Title = "title test!"
        let message1Subtitle = "subtitle thing"
        let message1 = IterableInAppMessage(messageId: "34g87hg982",
                                            campaignId: "23g8jer2ia42d",
                                            trigger: .defaultTrigger,
                                            createdAt: message1Date,
                                            expiresAt: nil,
                                            content: createDefaultContent(),
                                            saveToInbox: true,
                                            inboxMetadata: IterableInboxMetadata(title: message1Title,
                                                                                 subtitle: message1Subtitle,
                                                                                 icon: nil),
                                            customPayload: nil)
        messages.append(message1)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(messages: messages) {
            let inboxViewController = IterableInboxViewController(style: .plain)
            _ = inboxViewController.view
            
            XCTAssertEqual(inboxViewController.navigationController?.tabBarItem.badgeValue, "\(messages.count)")
            
            guard let cell = inboxViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? IterableInboxCell else {
                XCTFail("ERROR: Could not find first IterableInboxCell that should be there")
                return
            }
            
            XCTAssertEqual(cell.titleLbl?.text, message1Title)
            XCTAssertEqual(cell.subtitleLbl?.text, message1Subtitle)
            XCTAssertFalse(cell.unreadCircleView?.isHidden ?? true)
            XCTAssertEqual(cell.createdAtLbl?.text, DateFormatter.localizedString(from: message1Date, dateStyle: .medium, timeStyle: .short))
        }
    }
    
    private func createDefaultContent() -> IterableInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
}
