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
    
    func testDiffMessageListProcessing() {
        let currentMessages = [0: makeCurrentMessagesList()]
        let fetchedMessages = [0: makeFetchedMessagesList()]
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.processedMessagesList()[0]?.map { $0.elements?.title },
                       ["message1", "message3", "message4", "message5"])
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
    
    private func makeCurrentMessagesList() -> [IterableEmbeddedMessage] {
        return [
            IterableEmbeddedMessage(
                metadata: IterableEmbeddedMessage.EmbeddedMessageMetadata(messageId: "1"),
                elements: IterableEmbeddedMessage.EmbeddedMessageElements(title: "message1")
            ),
            IterableEmbeddedMessage(
                metadata: IterableEmbeddedMessage.EmbeddedMessageMetadata(messageId: "2"),
                elements: IterableEmbeddedMessage.EmbeddedMessageElements(title: "message2")
            ),
            IterableEmbeddedMessage(
                metadata: IterableEmbeddedMessage.EmbeddedMessageMetadata(messageId: "3"),
                elements: IterableEmbeddedMessage.EmbeddedMessageElements(title: "message3")
            )
        ]
    }
    
    private func makeFetchedMessagesList() -> [IterableEmbeddedMessage] {
        return [
            IterableEmbeddedMessage(
                metadata: IterableEmbeddedMessage.EmbeddedMessageMetadata(messageId: "1"),
                elements: nil
            ),
            IterableEmbeddedMessage(
                metadata: IterableEmbeddedMessage.EmbeddedMessageMetadata(messageId: "3"),
                elements: nil
            ),
            IterableEmbeddedMessage(
                metadata: IterableEmbeddedMessage.EmbeddedMessageMetadata(messageId: "4"),
                elements: IterableEmbeddedMessage.EmbeddedMessageElements(title: "message4")
            ),
            IterableEmbeddedMessage(
                metadata: IterableEmbeddedMessage.EmbeddedMessageMetadata(messageId: "5"),
                elements: IterableEmbeddedMessage.EmbeddedMessageElements(title: "message5")
            )
        ]
    }
}

