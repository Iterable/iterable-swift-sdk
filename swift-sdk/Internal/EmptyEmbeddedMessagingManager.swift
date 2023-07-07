//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

class EmptyEmbeddedMessagingManager: IterableEmbeddedMessagingManagerProtocol {
   
    func addUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
        
    }
    
    func removeUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
        
    }
    
    func getMessages() -> [IterableEmbeddedMessage] {
        return []
    }

    func syncMessages(completion: @escaping () -> Void) {
        
    }
    
    func track(click message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {
            
    }
    
    func track(impression message: IterableEmbeddedMessage) {
        
    }
    
    func track(embeddedSession: IterableEmbeddedSession) {
        
    }
}
