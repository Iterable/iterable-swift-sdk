//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedMessagingProcessorTests: XCTestCase {
    func testMessageListProcessingDedupe() {
        let currentMessages = makeBlankMessagesList(with: ["a", "b", "c"])
        let fetchedMessages = makeBlankMessagesList(with: ["a", "c", "d", "e"])
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.processedMessagesList().map { $0.metadata.id },
                       ["a", "b", "c", "d", "e"])
    }
    
    func testMessageIdsToTrackDelivery() {
        let currentMessages = makeBlankMessagesList(with: ["a", "b", "c"])
        let fetchedMessages = makeBlankMessagesList(with: ["a", "b", "c", "d"])
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.newlyDeliveredMessageIds(), ["d"])
    }
    
    func testPlacementIdsToNotify() {
        let currentMessages = makeBlankMessagesListWithMessageAndPlacementIds(
            [("a", "1"), ("d", "3")]
        )
        
        let fetchedMessages = makeBlankMessagesListWithMessageAndPlacementIds(
            [("a", "1"), ("b", "1"), ("c", "2")]
        )
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        // TODO: when removals are accounted for, add `"3"` into the assert
        XCTAssertEqual(processor.placementIdsToNotify(), ["1", "2"])
    }
    
    private func makeBlankMessagesList(with ids: [String]) -> [IterableEmbeddedMessage] {
        return ids.map { IterableEmbeddedMessage(id: $0, placementId: "") }
    }
    
    private func makeBlankMessagesListWithMessageAndPlacementIds(_ messageAndPlacementIds: [(String, String)]) -> [IterableEmbeddedMessage] {
        return messageAndPlacementIds.map { IterableEmbeddedMessage(id: $0.0, placementId: $0.1) }
    }
}

