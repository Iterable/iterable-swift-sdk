//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class EmbeddedMessagingManager: IterableEmbeddedMessagingManagerProtocol {
    init() {
        ITBInfo()
        
        initializeMessages()
    }
    
    deinit {
        ITBInfo()
    }
    
    public func getMessages() -> [IterableEmbeddedMessage] {
        return messages
    }
    
//    func getMessages(placementId: String) -> [IterableFlexMessage] {
//        return messages.filter({ $0.metadata.placementId == placementId })
//    }
    
    func start() {
        ITBInfo()
        
        
    }
    
    private func initializeMessages() {
        // retrieve from persistent storage and set it to `messages`
    }
    
    private var messages: [IterableEmbeddedMessage] = []
}
