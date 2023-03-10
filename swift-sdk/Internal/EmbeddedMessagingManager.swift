//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class EmbeddedMessagingManager: NSObject, IterableEmbeddedMessagingManagerProtocol {
    init(autoFetchInterval: TimeInterval,
         apiClient: ApiClientProtocol) {
        ITBInfo()
        
        self.autoFetchInterval = autoFetchInterval
        self.apiClient = apiClient
        
        super.init()
        
        initMessages()
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
    
    private func initMessages() {
        // TODO: retrieve from persistent storage and set it to `messages`
        
        
    }
    
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
        // Pending<[IterableEmbeddedMessage], SendRequestError>
        apiClient.getEmbeddedMessages()
            .map { fetchedMessages in
                // TODO: decide if parsing errors should be accounted for here
                
                // TODO: diff merge comparison with local messages variable
                // TODO: persist, if desired, or add placeholder for future
                // TODO: notify message update delegates
            }
    }
    
    private var apiClient: ApiClientProtocol
    
    private var autoFetchInterval: TimeInterval
    private var autoFetchTimer: Timer?
    
    private var messages: [IterableEmbeddedMessage] = []
    
    private var listeners: [String] = [] //change to protocol
}
