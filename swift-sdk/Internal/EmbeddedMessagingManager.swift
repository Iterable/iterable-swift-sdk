//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UIKit

class EmbeddedMessagingManager: NSObject, IterableEmbeddedMessagingManagerProtocol {
    init(apiClient: ApiClientProtocol) {
        ITBInfo()
        
        self.apiClient = apiClient
        super.init()
    }
    
    deinit {
        ITBInfo()
    }
    
    public func getMessages() -> [IterableEmbeddedMessage] {
        ITBInfo()
        
        return messages
    }
    
    public func addUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
        listeners.add(listener)
    }
    
    public func removeUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
        listeners.remove(listener)
    }

    public func syncMessages(completion: @escaping () -> Void) {
        retrieveEmbeddedMessages(completion: completion)
    }

    // MARK: - PRIVATE/INTERNAL
    
    private func addForegroundObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onAppDidBecomeActiveNotification(notification:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func removeForegroundObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }
    
    
    @objc private func onAppDidBecomeActiveNotification(notification: Notification) {
        ITBInfo()
        syncMessages { }
    }

    
    private func retrieveEmbeddedMessages(completion: @escaping () -> Void) {
        apiClient.getEmbeddedMessages()
            .onCompletion(
                receiveValue: { embeddedMessagesPayload in
                    let fetchedMessages = embeddedMessagesPayload.embeddedMessages
                    
                    // TODO: decide if parsing errors should be accounted for here
                    
                    let processor = EmbeddedMessagingProcessor(currentMessages: self.messages,
                                                               fetchedMessages: fetchedMessages)
                    
                    self.setMessages(processor)
                    self.trackNewlyRetrieved(processor)
                    self.notifyUpdateDelegates(processor)
                    completion()
                },
                
                receiveError: { sendRequestError in
                    //TODO: This check can go away once eligibility based retrieval comes in place.
                    if sendRequestError.reason == "SUBSCRIPTION_INACTIVE" ||
                        sendRequestError.reason == "Invalid API Key" {
                        self.notifyDelegatesOfInvalidApiKeyOrSyncStop()
                        ITBInfo("Subscription inactive. Stopping embedded message sync")
                    } else {
                        ITBError()
                    }
                    completion()
                }
            )
    }
    
    private func setMessages(_ processor: EmbeddedMessagingProcessor) {
        messages = processor.processedMessagesList()
    }
    
    private func trackNewlyRetrieved(_ processor: EmbeddedMessagingProcessor) {
        for message in processor.newlyRetrievedMessages() {
            IterableAPI.track(embeddedMessageReceived: message)
        }
    }
    
    private func notifyUpdateDelegates(_ processor: EmbeddedMessagingProcessor) {
        // TODO: filter `messages` by `placementId` and notify objects in `listeners` that have that placement ID
        
//        let placementIdsToUpdate = processor.placementIdsToNotify()
        
        for listener in listeners.allObjects {
            listener.onMessagesUpdated()
        }
    }
    
    private func notifyDelegatesOfInvalidApiKeyOrSyncStop() {
        for listener in listeners.allObjects {
            listener.onInvalidApiKeyOrSyncStop()
        }
    }
    private var apiClient: ApiClientProtocol
    
    private var messages: [IterableEmbeddedMessage] = []
    
    private var listeners: NSHashTable<IterableEmbeddedMessagingUpdateDelegate> = NSHashTable(options: [.weakMemory])
}
