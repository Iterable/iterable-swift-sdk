//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableEmbeddedMessagingManagerProtocol {
    func start()
    func stop()
    
    func getMessages() -> [IterableEmbeddedMessage]
    
    func addUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate)
    func removeUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate)
    
    func temp_manualOverrideRefresh()
    
    func track(click message: IterableEmbeddedMessage, clickType: String)
    func track(impression message: IterableEmbeddedMessage)
    func track(embeddedSession: IterableEmbeddedSession)

}
