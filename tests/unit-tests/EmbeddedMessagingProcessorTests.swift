//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedMessagingProcessorTests: XCTestCase {
    func testMessageListProcessing() {
        let currentMessages = [0: makeBlankMessagesList(with: ["1", "2", "3"])]
        let fetchedMessages = [0: makeBlankMessagesList(with: ["1", "3", "4", "5"])]
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.processedMessagesList()[0]?.map { $0.metadata.messageId },
                       ["1", "3", "4", "5"])
    }
    
    func testMessageListRemovedMessages() {
        let currentMessages = [0: makeBlankMessagesList(with: ["1", "2", "3"])]
        let fetchedMessages = [0: makeBlankMessagesList(with: ["1", "3", "4", "5"])]
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.newlyRemovedMessageIds()[0], ["2"])
    }
    
    func testMessageIdsToTrackDelivery() {
        let currentMessages = [0: makeBlankMessagesList(with: ["1", "2", "3"])]
        let fetchedMessages = [0: makeBlankMessagesList(with: ["1", "2", "3", "4"])]
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.newlyRetrievedMessages()[0]?.map { $0.metadata.messageId }, ["4"])
    }

    private func makeBlankMessagesList(with ids: [String]) -> [IterableEmbeddedMessage] {
        return ids.map { IterableEmbeddedMessage(messageId: $0) }
    }
}

