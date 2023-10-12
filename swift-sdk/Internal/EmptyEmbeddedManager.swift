//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

class EmptyEmbeddedManager: IterableEmbeddedManagerProtocol {
    func resolveMessages(_ messages: [IterableEmbeddedMessage], completion: @escaping ([ResolvedMessage]) -> Void) {
        
    }
    
   
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

    func syncMessages(completion: @escaping (Error?) -> Void) {
        
    }
    
    func embeddedMessageClicked(message: IterableEmbeddedMessage?, buttonIdentifier: String?, clickedUrl: String) {
        
    }
    
    func track(click message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {
            
    }
    
    func track(impression message: IterableEmbeddedMessage) {
        
    }
    
    func track(embeddedSession: IterableEmbeddedSession) {
        
    }
}
