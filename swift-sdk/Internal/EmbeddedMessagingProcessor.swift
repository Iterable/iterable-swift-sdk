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

    func newlyDeliveredMessageIds() -> [String] {
        return getFetchedMessageIds().filter { !getCurrentMessageIds().contains($0) }
    }
    
    func newlyRemovedMessageIds() -> [String] {
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
    
    private func getCurrentMessageIds() -> [String] {
        return currentMessages.map { $0.metadata.id }
    }
    
    private func getFetchedMessageIds() -> [String] {
        return fetchedMessages.map { $0.metadata.id }
    }
}
