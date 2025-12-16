//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableEmbeddedUpdateDelegate {
    func onMessagesUpdated()
    func onEmbeddedMessagingDisabled()
    
    /// Called when an embedded messaging sync completes successfully.
    @objc optional func onEmbeddedMessagingSyncSucceeded()
    
    /// Called when an embedded messaging sync fails.
    /// - Parameter error: Failure reason string, if available.
    @objc optional func onEmbeddedMessagingSyncFailed(_ error: String?)
}
