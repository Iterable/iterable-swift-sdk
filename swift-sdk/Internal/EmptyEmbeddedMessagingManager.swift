//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

class EmptyEmbeddedMessagingManager: IterableEmbeddedMessagingManagerProtocol {
    func getMessages() -> [IterableEmbeddedMessage] {
        return []
    }
    
    func addUpdateListener() {
        
    }
    
    func removeUpdateListener() {
        
    }
    
    func start() {
        
    }
}
