//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class EmbeddedMessagingManager: NSObject, IterableEmbeddedMessagingManagerProtocol {
    init(autoFetchInterval: TimeInterval,
         apiClient: ApiClientProtocol,
         dateProvider: DateProviderProtocol) {
        ITBInfo()
        
        self.autoFetchInterval = autoFetchInterval
        self.apiClient = apiClient
        
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
    
    public func addUpdateListener() {
        listeners.append("")
    }
    
    public func removeUpdateListener() {
        listeners.remove(at: 0)
    }
    
    func start() {
        ITBInfo()
    }
    
    // MARK: - PRIVATE/INTERNAL
    
    private func initObservers() {
        // TODO: add app foreground/background switching notification registration here
        
        
    }
    
    private func deinitObservers() {
        // TODO: add app foreground/background switching notification removal here
        
        
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
    
    private var listeners: [String] = [] //change to protocol
}
