//
//  Created by Tapash Majumder on 5/31/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

class EmptyInAppManager: IterableInternalInAppManagerProtocol {
    func start() -> Future<Bool, Error> {
        return Promise<Bool, Error>(value: true)
    }
    
    func createInboxMessageViewController(for _: IterableInAppMessage, withInboxMode _: IterableInboxViewController.InboxMode, inboxSessionId: String? = nil) -> UIViewController? {
        ITBError("Can't create VC")
        return nil
    }
    
    var isAutoDisplayPaused: Bool {
        get {
            false
        }
        
        set {}
    }
    
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func show(message _: IterableInAppMessage) {}
    
    func show(message _: IterableInAppMessage, consume _: Bool, callback _: ITBURLCallback?) {}
    
    func remove(message _: IterableInAppMessage) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation, source _: InAppDeleteSource) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation, source _: InAppDeleteSource, inboxSessionId _: String?) {}
    
    func set(read _: Bool, forMessage _: IterableInAppMessage) {}
    
    func getMessage(withId _: String) -> IterableInAppMessage? {
        return nil
    }
    
    func getUnreadInboxMessagesCount() -> Int {
        return 0
    }
    
    func scheduleSync() -> Future<Bool, Error> {
        return Promise<Bool, Error>(value: true)
    }
    
    func onInAppRemoved(messageId _: String) {}
    
    func isOkToShowNow(message _: IterableInAppMessage) -> Bool {
        return true
    }
    
    func reset() -> Future<Bool, Error> {
        return Promise<Bool, Error>(value: true)
    }
}
