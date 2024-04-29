//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

struct EmbeddedMessagingProcessor {
    init(currentMessages: [Int: [IterableEmbeddedMessage]], fetchedMessages: [Int: [IterableEmbeddedMessage]]) {
        self.currentMessages = currentMessages
        self.fetchedMessages = fetchedMessages
    }

    func processedMessagesList() -> [Int: [IterableEmbeddedMessage]] {
        //TODO: Merge the currentMessages with fetchedMessages.
        //TODO: Also to remove the messages from currentMessges which are no more present in fetchedMessages
        var processedMessages: [Int: [IterableEmbeddedMessage]] = [:]
        
        // create a dictionary mapping message ids to current messages
        var currentMessagesMap: [String: IterableEmbeddedMessage] = [:]
        for (placementId, messages) in currentMessages {
            for message in messages {
                currentMessagesMap[message.metadata.messageId] = message
            }
        }
        
        for (placementId, fetchedMessagesList) in fetchedMessages {
            if let currentMessagesForPlacement = currentMessages[placementId] {
                var updatedMessagesForPlacement: [IterableEmbeddedMessage] = []
                
                for fetchedMessage in fetchedMessagesList {
                    if let existingMessage = currentMessagesMap[fetchedMessage.metadata.messageId] {
                        updatedMessagesForPlacement.append(existingMessage)
                    } else {
                        updatedMessagesForPlacement.append(fetchedMessage)
                    }
                }
                
                processedMessages[placementId] = updatedMessagesForPlacement
                
            } else {
                processedMessages[placementId] = fetchedMessagesList
            }
            
        }
        
        return processedMessages
    }

    func newlyRetrievedMessages() -> [Int: [IterableEmbeddedMessage]] {
        var newMessages: [Int: [IterableEmbeddedMessage]] = [:]
        
        for (placementId, fetchedMessagesList) in fetchedMessages {
            let currentMessageIds = currentMessages[placementId]?.map { $0.metadata.messageId } ?? []
            let newFetchedMessages = fetchedMessagesList.filter { !currentMessageIds.contains($0.metadata.messageId) }
            
            if !newFetchedMessages.isEmpty {
                newMessages[placementId] = newFetchedMessages
            }
        }
        
        return newMessages
    }

    func newlyRemovedMessageIds() -> [Int: [String]] {
        var removedMessageIds: [Int: [String]] = [:]

        for (placementId, messages) in currentMessages {
            let currentMessageIds = messages.map { $0.metadata.messageId }
            let fetchedMessageIds = fetchedMessages[placementId]?.map { $0.metadata.messageId } ?? []
            
            let removedIds = currentMessageIds.filter { !fetchedMessageIds.contains($0) }
            if !removedIds.isEmpty {
                removedMessageIds[placementId] = removedIds
            }
        }

        return removedMessageIds
    }

    // MARK: - PRIVATE/INTERNAL

    private let currentMessages: [Int: [IterableEmbeddedMessage]]
    private let fetchedMessages: [Int: [IterableEmbeddedMessage]]
}
