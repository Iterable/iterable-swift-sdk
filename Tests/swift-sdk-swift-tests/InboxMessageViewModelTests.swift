//
//  InboxMessageViewModelTests.swift
//  swift-sdk-swift-tests
//
//  Created by Jay Kim on 5/23/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxMessageViewModelTests: XCTestCase {
    func testModel() {
        let testCreationDate = Date()
        
        let title = "TITLE!!!!!"
        let subtitle = "a prelude of the journey to the road to the goal"
        let icon = "https://imageurl.com/thingy"
        
        let metadata = IterableInboxMetadata(title: title,
                                             subtitle: subtitle,
                                             icon: icon)
        
        let msg = IterableInAppMessage(messageId: "939fi9kj92kd",
                                       campaignId: "45820",
                                       createdAt: testCreationDate,
                                       content: createDefaultContent(),
                                       inboxMetadata: metadata)
        msg.read = true
        
        let inboxMsg = InboxMessageViewModel(message: msg)
        
        XCTAssertEqual(inboxMsg.title, title)
        XCTAssertEqual(inboxMsg.subtitle, subtitle)
        XCTAssertEqual(inboxMsg.imageUrl, icon)
        XCTAssertEqual(inboxMsg.createdAt, testCreationDate)
        XCTAssertTrue(inboxMsg.read)
    }
    
    func testHasher() {
        let msg1 = IterableInAppMessage(messageId: "939fi9kj92kd",
                                        campaignId: "45820",
                                        content: createDefaultContent())
        
        let msg2 = IterableInAppMessage(messageId: "89rjg839g24h",
                                        campaignId: "29486",
                                        content: createDefaultContent())
        
        let inboxMsg1 = InboxMessageViewModel(message: msg1)
        let inboxMsg1Dupe = InboxMessageViewModel(message: msg1)
        let inboxMsg2 = InboxMessageViewModel(message: msg2)
        
        let dict = [inboxMsg1: "value"]
        
        XCTAssertEqual(dict[inboxMsg1Dupe], "value")
        
        msg1.read = true
        let inboxMsg1Read = InboxMessageViewModel(message: msg1)
        XCTAssertNil(dict[inboxMsg1Read])
        
        XCTAssertNil(dict[inboxMsg2])
    }
    
    func testEquatable() {
        let msg1 = IterableInAppMessage(messageId: "939fi9kj92kd",
                                        campaignId: "45820",
                                        content: createDefaultContent())
        
        let msg2 = IterableInAppMessage(messageId: "89rjg839g24h",
                                        campaignId: "29486",
                                        content: createDefaultContent())
        
        let inboxMsg1 = InboxMessageViewModel(message: msg1)
        let inboxMsg1Dupe = InboxMessageViewModel(message: msg1)
        let inboxMsg2 = InboxMessageViewModel(message: msg2)
        
        XCTAssertTrue(inboxMsg1 == inboxMsg1Dupe)
        
        msg1.read = true
        let inboxMsg1Read = InboxMessageViewModel(message: msg1)
        XCTAssertFalse(inboxMsg1 == inboxMsg1Read)
        
        XCTAssertFalse(inboxMsg1 == inboxMsg2)
    }
    
    private func createDefaultContent() -> IterableInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
}
