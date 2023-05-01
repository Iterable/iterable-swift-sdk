//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UIKit

class EmbeddedMessagingManager: NSObject, IterableEmbeddedMessagingManagerProtocol {
    init(autoFetchInterval: TimeInterval,
         apiClient: ApiClientProtocol,
         dateProvider: DateProviderProtocol) {
        ITBInfo()
        
        self.autoFetchInterval = autoFetchInterval
        self.apiClient = apiClient
        self.dateProvider = dateProvider
        
        super.init()
    }
    
    deinit {
        ITBInfo()
        
        stop()
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
    
    public func temp_manualOverrideRefresh() {
        retrieveEmbeddedMessages()
    }
    
    public func track(click message: IterableEmbeddedMessage) {
//        apiClient.track(embeddedMessageClick: message)
        IterableAPI.track(event: "embedded-messaging", dataFields: ["name": "click",
                                                                    "messageId": message.metadata.id])
    }
    
    public func track(dismiss message: IterableEmbeddedMessage) {
//        apiClient.track(embeddedMessageDismiss: message)
        IterableAPI.track(event: "embedded-messaging", dataFields: ["name": "dismiss",
                                                                    "messageId": message.metadata.id])
    }
    
    func start() {
        ITBInfo()
        
        addForegroundObservers()
        startAutoFetchTimer()
    }
    
    func stop() {
        ITBInfo()
        
        removeForegroundObservers()
        stopAutoFetchTimer()
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
    
    private func startAutoFetchTimer() {
        guard autoFetchInterval > 0 else {
            ITBInfo("embedded messaging automatic fetching not started since autoFetchInterval is <= 0")
            return
        }
        
        autoFetchTimer = Timer.scheduledTimer(withTimeInterval: autoFetchInterval,
                                              repeats: true,
                                              block: { [weak self] _ in
            self?.retrieveAndSyncEmbeddedMessages()
        })
    }
    
    private func stopAutoFetchTimer() {
        autoFetchTimer?.invalidate()
        autoFetchTimer = nil
    }
    
    @objc private func onAppDidBecomeActiveNotification(notification: Notification) {
        ITBInfo()
        
        retrieveAndSyncEmbeddedMessages()
    }
    
    private func retrieveAndSyncEmbeddedMessages() {
        if let lastMessagesFetchDate = lastMessagesFetchDate {
            if lastMessagesFetchDate + autoFetchInterval < dateProvider.currentDate {
                return
            }
        }
        
        retrieveEmbeddedMessages()
    }
    
    private func retrieveEmbeddedMessages() {
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
                    self.lastMessagesFetchDate = self.dateProvider.currentDate
                },
                
                receiveError: { sendRequestError in
                    ITBError()
                }
            )
    }
    
    private func setMessages(_ processor: EmbeddedMessagingProcessor) {
        messages = processor.processedMessagesList()
    }
    
    private func trackNewlyRetrieved(_ processor: EmbeddedMessagingProcessor) {
        for message in processor.newlyRetrievedMessages() {
//            apiClient.track(embeddedMessagingReceived: message)
            IterableAPI.track(event: "embedded-messaging",
                              dataFields: ["name": "received",
                                           "messageId": message.metadata.id]
            )
        }
    }
    
    private func notifyUpdateDelegates(_ processor: EmbeddedMessagingProcessor) {
        // TODO: filter `messages` by `placementId` and notify objects in `listeners` that have that placement ID
        
//        let placementIdsToUpdate = processor.placementIdsToNotify()
        
        for listener in listeners.allObjects {
            listener.onMessagesUpdated()
        }
    }
    
    private var apiClient: ApiClientProtocol
    private var dateProvider: DateProviderProtocol
    
    private var autoFetchInterval: TimeInterval
    private var autoFetchTimer: Timer?
    
    private var lastMessagesFetchDate: Date?
    
    private var messages: [IterableEmbeddedMessage] = []
    
    private var listeners: NSHashTable<IterableEmbeddedMessagingUpdateDelegate> = NSHashTable(options: [.weakMemory])
}
