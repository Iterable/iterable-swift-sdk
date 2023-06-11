//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedMessagingProcessorTests: XCTestCase {
    func testMessageListProcessing() {
        let currentMessages = makeBlankMessagesList(with: [1, 2, 3])
        let fetchedMessages = makeBlankMessagesList(with: [1, 3, 4, 5])
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.processedMessagesList().map { $0.metadata.messageId },
                       [1, 3, 4, 5])
    }
    
    func testMessageListRemovedMessages() {
        let currentMessages = makeBlankMessagesList(with: [1, 2, 3])
        let fetchedMessages = makeBlankMessagesList(with: [1, 3, 4, 5])
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.newlyRemovedMessageIds(), [2])
    }
    
    func testMessageIdsToTrackDelivery() {
        let currentMessages = makeBlankMessagesList(with: [1, 2, 3])
        let fetchedMessages = makeBlankMessagesList(with: [1, 2, 3, 4])
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.newlyDeliveredMessageIds(), [4])
    }
    
//    func testPlacementIdsToNotify() {
//        let currentMessages = makeBlankMessagesListWithMessageAndPlacementIds(
//            [("a", "1"), ("d", "3")]
//        )
//
//        let fetchedMessages = makeBlankMessagesListWithMessageAndPlacementIds(
//            [("a", "1"), ("b", "1"), ("c", "2")]
//        )
//
//        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
//                                                   fetchedMessages: fetchedMessages)
//
//        // TODO: when removals are accounted for, add `"3"` into the assert
//        XCTAssertEqual(processor.placementIdsToNotify(), ["1", "2"])
//    }
    
    private func makeBlankMessagesList(with ids: [Int]) -> [IterableEmbeddedMessage] {
        return ids.map { IterableEmbeddedMessage(messageId: $0) }
    }
    
//    private func makeBlankMessagesListWithMessageAndPlacementIds(_ messageAndPlacementIds: [(String, String)]) -> [IterableEmbeddedMessage] {
//        return messageAndPlacementIds.map { IterableEmbeddedMessage(id: $0.0, placementId: $0.1) }
//    }
}

