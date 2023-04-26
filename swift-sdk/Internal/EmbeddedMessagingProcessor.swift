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
        // TODO: understand/handle case of message with same message ID but different contents
        
        return fetchedMessages
    }

    func newlyDeliveredMessages() -> [IterableEmbeddedMessage] {
        return getNewMessages()
    }
    
    func newlyRemovedMessageIds() -> [Int] {
        return getCurrentMessageIds().filter { !getFetchedMessageIds().contains($0) }
    }

//    func placementIdsToNotify() -> [String] {
//        // TODO: account for removed placement IDs, this only counts new ones for now
//        
//        return getNewMessages()
//            .map { $0.metadata.placementId }
//    }
    
    // MARK: - PRIVATE/INTERNAL
    
    private let currentMessages: [IterableEmbeddedMessage]
    private let fetchedMessages: [IterableEmbeddedMessage]
    
    private func getNewMessages() -> [IterableEmbeddedMessage] {
        let currentMessageIds = currentMessages.map { $0.metadata.id }
        
        return fetchedMessages
            .filter { message in
                !currentMessageIds.contains(where: { $0 == message.metadata.id })
            }
    }
    
    private func getCurrentMessageIds() -> [Int] {
        return currentMessages.map { $0.metadata.id }
    }
    
    private func getFetchedMessageIds() -> [Int] {
        return fetchedMessages.map { $0.metadata.id }
    }
}
