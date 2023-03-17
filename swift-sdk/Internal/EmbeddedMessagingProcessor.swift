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
        let currentMessageIds = currentMessages.map { $0.metadata.id }
        let fetchedMessageIds = fetchedMessages.map { $0.metadata.id }
        
        return fetchedMessageIds.filter { !currentMessageIds.contains($0) }
    }
    
    func newlyRemovedMessageIds() -> [String] {
        let currentMessageIds = currentMessages.map { $0.metadata.id }
        let fetchedMessageIds = fetchedMessages.map { $0.metadata.id }
        
        return currentMessageIds.filter { !fetchedMessageIds.contains($0) }
    }

    func placementIdsToNotify() -> [String] {
        // TODO: account for removed placement IDs, this only counts new ones for now
        
        return getNewMessages()
            .map { $0.metadata.placementId }
    }
    
    // TODO: track message removals
    
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
