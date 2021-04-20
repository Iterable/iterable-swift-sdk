//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppMessageProcessorTests: XCTestCase {
    func testMessagesObtainedShouldOverwriteForReadState() {
        let messageId = "1"
        
        let localMessage = Self.makeEmptyInboxMessage(messageId)
        
        let serverMessage = Self.makeEmptyInboxMessage(messageId)
        serverMessage.read = true
        
        let messagesMap: OrderedDictionary<String, IterableInAppMessage> = [messageId: localMessage]
        let newMessages = [serverMessage]
        
        let result = MessagesObtainedHandler(messagesMap: messagesMap,
                                             messages: newMessages).handle()
        
        XCTAssertTrue(result.inboxChanged)
    }
    
    private static let emptyInAppContent = IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    
    private static func makeEmptyMessage() -> IterableInAppMessage {
        IterableInAppMessage(messageId: "", campaignId: nil, content: emptyInAppContent)
    }
    
    private static func makeEmptyInboxMessage(_ messageId: String = "") -> IterableInAppMessage {
        IterableInAppMessage(messageId: messageId, campaignId: nil, content: emptyInAppContent, saveToInbox: true, read: false)
    }
}
