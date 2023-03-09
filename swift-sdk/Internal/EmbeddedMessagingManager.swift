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
        
    }
    
    private func deinitObservers() {
        
    }
    
    private func initAutoFetchTimer() {
        
    }
    
    private var messages: [IterableEmbeddedMessage] = []
    private var listeners: [String] = [] //change to protocol
}
