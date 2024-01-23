//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

class EmptyEmbeddedManager: IterableInternalEmbeddedManagerProtocol {
    func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        
    }
    
    func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        
    }
    
    func getMessages() -> [IterableEmbeddedMessage] {
        return []
    }
    
    func getMessages(for placementId: Int) -> [IterableEmbeddedMessage] {
        return []
    }

    func syncMessages(completion: @escaping () -> Void) {
        
    }
    
    public func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {

    }
    
    func reset() {
        
    }
    
    func track(click message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {
            
    }
    
    func track(impression message: IterableEmbeddedMessage) {
        
    }
    
    func track(embeddedSession: IterableEmbeddedSession) {
        
    }
}
