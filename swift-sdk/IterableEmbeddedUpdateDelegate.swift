//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableEmbeddedUpdateDelegate {
    func onMessagesUpdated()
    func onEmbeddedMessagingDisabled()
}
