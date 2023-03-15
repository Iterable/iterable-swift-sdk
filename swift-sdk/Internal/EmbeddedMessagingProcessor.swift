//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

struct EmbeddedMessagingProcessor {
    init(currentMessages: [IterableEmbeddedMessage], fetchedMessages: [IterableEmbeddedMessage]) {
        self.currentMessages = currentMessages
        self.fetchedMessages = fetchedMessages
    }
    
    func processedMessagesList() -> [IterableEmbeddedMessage] {
        return fetchedMessages
    }

    func newlyDeliveredMessageIds() -> [String] {
        let currentMessageIds = currentMessages.map { $0.metadata.id }
        let fetchedMessageIds = fetchedMessages.map { $0.metadata.id }
        
        return fetchedMessageIds.filter { !currentMessageIds.contains($0) }
    }

    func placementIdsToNotify() -> [String] {
        return getNewMessages()
            .map { $0.metadata.placementId }
    }
    
    private let currentMessages: [IterableEmbeddedMessage]
    private let fetchedMessages: [IterableEmbeddedMessage]
    
    private func getNewMessages() -> [IterableEmbeddedMessage] {
        let currentMessageIds = currentMessages.map { $0.metadata.id }
        
        return fetchedMessages
            .filter { message in
                !currentMessageIds.contains(where: { $0 == message.metadata.id })
            }
    }
}
