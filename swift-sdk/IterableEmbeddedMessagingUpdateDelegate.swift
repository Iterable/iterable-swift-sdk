//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableEmbeddedMessagingUpdateDelegate {
    func onMessagesUpdated()
    func onInvalidApiKeyOrSyncStop()
}
