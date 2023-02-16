//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class FlexMessagingManager: IterableFlexMessagingManagerProtocol {
    init() {
        ITBInfo()
        
        
    }
    
    deinit {
        ITBInfo()
    }
    
    func getMessages(placementId: String) -> [IterableFlexMessage] {
        return messages.filter({ $0.metadata.placementId == placementId })
    }
    
    private var messages: [IterableFlexMessage] = []
}
