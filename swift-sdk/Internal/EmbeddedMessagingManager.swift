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
        
        initObservers()
        initAutoFetchTimer()
    }
    
    deinit {
        ITBInfo()
        
        deinitAutoFetchTimer()
        deinitObservers()
    }
    
    public func getMessages() -> [IterableEmbeddedMessage] {
        ITBInfo()
        
        return messages
    }
    
    public func addUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
//        listeners.append(listener)
    }
    
    public func removeUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
//        listeners.
    }
    
    func start() {
        ITBInfo()
    }
    
    // MARK: - PRIVATE/INTERNAL
    
    private func initObservers() {
        NotificationCenter().addObserver(self,
                                         selector: #selector(onAppDidBecomeActiveNotification(notification:)),
                                         name: UIApplication.didBecomeActiveNotification,
                                         object: nil)
    }
    
    private func deinitObservers() {
        NotificationCenter().removeObserver(self,
                                            name: UIApplication.didBecomeActiveNotification,
                                            object: nil)
    }
    
    private func initAutoFetchTimer() {
        startAutoFetchTimer()
    }
    
    private func deinitAutoFetchTimer() {
        stopAutoFetchTimer()
    }
    
    private func resetAutoFetchTimer() {
        stopAutoFetchTimer()
        
        startAutoFetchTimer()
    }
    
    private func stopAutoFetchTimer() {
        autoFetchTimer?.invalidate()
        autoFetchTimer = nil
    }
    
    private func startAutoFetchTimer() {
        autoFetchTimer = Timer.scheduledTimer(withTimeInterval: autoFetchInterval,
                                              repeats: true,
                                              block: { [weak self] _ in
            self?.retrieveAndSyncEmbeddedMessages()
        })
    }
    
    @objc private func onAppDidBecomeActiveNotification(notification: Notification) {
        ITBInfo()
        
        retrieveAndSyncEmbeddedMessages()
    }
    
    private func retrieveAndSyncEmbeddedMessages() {
        if let lastMessagesFetchDate = lastMessagesFetchDate {
            if lastMessagesFetchDate + autoFetchInterval <= dateProvider.currentDate {
                return
            }
        }
        
        apiClient.getEmbeddedMessages()
            .onCompletion(
                receiveValue: { fetchedMessages in
                    // TODO: decide if parsing errors should be accounted for here
                    self.messages = fetchedMessages
                    self.trackDeliveries(messages: fetchedMessages)
                    self.notifyUpdateDelegates(messages: fetchedMessages)
                    self.lastMessagesFetchDate = self.dateProvider.currentDate
                },
                
                receiveError: { sendRequestError in
                    ITBError()
                })
    }
    
    private func trackDeliveries(messages: [IterableEmbeddedMessage]) {
        // TODO: track deliveries
    }
    
    private func notifyUpdateDelegates(messages: [IterableEmbeddedMessage]) {
        // TODO: filter `messages` by `placementId` and notify objects in `listeners` that have that placement ID
    }
    
    private var apiClient: ApiClientProtocol
    private var dateProvider: DateProviderProtocol
    
    private var autoFetchInterval: TimeInterval
    private var autoFetchTimer: Timer?
    
    private var lastMessagesFetchDate: Date?
    
    private var messages: [IterableEmbeddedMessage] = []
    
    private var listeners: [IterableEmbeddedMessagingUpdateDelegate] = []
}
