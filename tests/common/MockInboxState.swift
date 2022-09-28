//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockInboxState: InboxStateProtocol {
    var clickCallback: ((URL?, IterableInAppMessage, String?) -> Void)?
    
    var isReady = true
    
    var messages = [InboxMessageViewModel]()
    
    var totalMessagesCount: Int {
        messages.count
    }
    
    var unreadMessagesCount: Int {
        messages.reduce(0) {
            $1.read ? $0 + 1 : $0
        }
    }
    
    func sync() -> Pending<Bool, Error> {
        Fulfill(value: true)
    }
    
    func track(inboxSession: IterableInboxSession) {
    }
    
    func loadImage(forMessageId messageId: String, fromUrl url: URL) -> Pending<Data, Error> {
        Fulfill(value: Data())
    }
    
    func handleClick(clickedUrl url: URL?, forMessage message: IterableInAppMessage, inboxSessionId: String?) {
        clickCallback?(url, message, inboxSessionId)
    }
    
    func set(read: Bool, forMessage message: InboxMessageViewModel) {
    }
    
    func remove(message: InboxMessageViewModel, inboxSessionId: String?) {
    }
}
