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
        
        let message = IterableInAppMessage(messageId: "939fi9kj92kd",
                                           campaignId: 45820,
                                           createdAt: testCreationDate,
                                           content: createDefaultContent(),
                                           inboxMetadata: metadata)
        message.read = true
        
        let inboxMessageViewModel = InboxMessageViewModel(message: message)
        
        XCTAssertEqual(inboxMessageViewModel.title, title)
        XCTAssertEqual(inboxMessageViewModel.subtitle, subtitle)
        XCTAssertEqual(inboxMessageViewModel.imageUrl, icon)
        XCTAssertEqual(inboxMessageViewModel.createdAt, testCreationDate)
        XCTAssertTrue(inboxMessageViewModel.read)
    }
    
    func testHasValidImageUrl() {
        let messageWithNoIcon = generateMessage(with: IterableInboxMetadata(title: "title", subtitle: "subtitle", icon: nil))
        let inboxMessageViewModelNoIcon = InboxMessageViewModel(message: messageWithNoIcon)
        XCTAssertFalse(inboxMessageViewModelNoIcon.hasValidImageUrl())
        
        let messageWithInvalidUrl = generateMessage(with: IterableInboxMetadata(title: "title", subtitle: "subtitle", icon: ""))
        let inboxMessageViewModelWithInvalidUrl = InboxMessageViewModel(message: messageWithInvalidUrl)
        XCTAssertFalse(inboxMessageViewModelWithInvalidUrl.hasValidImageUrl())
        
        let messageWithIcon = generateMessage(with: IterableInboxMetadata(title: "title", subtitle: "subtitle", icon: "https://image.com"))
        let inboxMessageViewModelWithIcon = InboxMessageViewModel(message: messageWithIcon)
        XCTAssertTrue(inboxMessageViewModelWithIcon.hasValidImageUrl())
    }
    
    func testHasher() {
        let message1 = IterableInAppMessage(messageId: "939fi9kj92kd",
                                            campaignId: 45820,
                                            content: createDefaultContent())
        
        let message2 = IterableInAppMessage(messageId: "89rjg839g24h",
                                            campaignId: 29486,
                                            content: createDefaultContent())
        
        let inboxMessageViewModel1 = InboxMessageViewModel(message: message1)
        let inboxMessageViewModel1Dupe = InboxMessageViewModel(message: message1)
        let inboxMessageViewModel2 = InboxMessageViewModel(message: message2)
        
        let dict = [inboxMessageViewModel1: "value"]
        
        XCTAssertEqual(dict[inboxMessageViewModel1Dupe], "value")
        
        message1.read = true
        let inboxMessageViewModel1Read = InboxMessageViewModel(message: message1)
        XCTAssertNil(dict[inboxMessageViewModel1Read])
        
        XCTAssertNil(dict[inboxMessageViewModel2])
    }
    
    func testEquatable() {
        let message1 = IterableInAppMessage(messageId: "939fi9kj92kd",
                                            campaignId: 45820,
                                            content: createDefaultContent())
        
        let message2 = IterableInAppMessage(messageId: "89rjg839g24h",
                                            campaignId: 29486,
                                            content: createDefaultContent())
        
        let inboxMessageViewModel1 = InboxMessageViewModel(message: message1)
        let inboxMessageViewModel1Dupe = InboxMessageViewModel(message: message1)
        let inboxMessageViewModel2 = InboxMessageViewModel(message: message2)
        
        XCTAssertTrue(inboxMessageViewModel1 == inboxMessageViewModel1Dupe)
        
        message1.read = true
        let inboxMessageViewModel1Read = InboxMessageViewModel(message: message1)
        XCTAssertFalse(inboxMessageViewModel1 == inboxMessageViewModel1Read)
        
        XCTAssertFalse(inboxMessageViewModel1 == inboxMessageViewModel2)
    }
    
    private func generateMessage(with metadata: IterableInboxMetadata) -> IterableInAppMessage {
        let id = TestHelper.generateIntGuid()
        return IterableInAppMessage(messageId: "message-\(id)",
                                    campaignId: id as NSNumber,
                                    content: createDefaultContent(),
                                    inboxMetadata: metadata)
    }
    
    private func createDefaultContent() -> IterableInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
}
