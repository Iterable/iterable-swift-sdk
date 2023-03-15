//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedMessagingProcessorTests: XCTestCase {
    func testDeliveryIds() {
        let currentMessages = makeBlankMessagesList(with: ["a", "b", "c"])
        let fetchedMessages = makeBlankMessagesList(with: ["a", "b", "c", "d"])
        
        let processor = EmbeddedMessagingProcessor(currentMessages: currentMessages,
                                                   fetchedMessages: fetchedMessages)
        
        XCTAssertEqual(processor.newlyDeliveredMessageIds(), ["d"])
    }
    
    private func makeBlankMessagesList(with ids: [String]) -> [IterableEmbeddedMessage] {
        return ids.map { IterableEmbeddedMessage(id: $0, placementId: "") }
    }
}

