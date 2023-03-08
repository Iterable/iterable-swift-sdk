//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

class EmptyEmbeddedMessagingManager: IterableEmbeddedMessagingManagerProtocol {
    func getMessages() -> [IterableEmbeddedMessage] {
        return []
    }
    
    func addListener() {
        
    }
    
    func removeListener() {
        
    }
    
    func start() {
        
    }
}
