//
//
//  Created by Tapash Majumder on 5/31/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

class EmptyInAppManager : IterableInAppManagerProtocolInternal {
    func start() {
    }
    
    func createInboxMessageViewController(for message: IterableInAppMessage) -> UIViewController? {
        ITBError("Can't create VC")
        return nil
    }
    
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func show(message: IterableInAppMessage) {
    }
    
    func show(message: IterableInAppMessage, consume: Bool, callback: ITBURLCallback?) {
    }
    
    func remove(message: IterableInAppMessage) {
    }
    
    func set(read: Bool, forMessage message: IterableInAppMessage) {
    }
    
    func getUnreadInboxMessagesCount() -> Int {
        return 0
    }
    
    func onInAppSyncNeeded() -> Future<Bool, Error> {
        return Promise<Bool, Error>(value: true)
    }
    
    func onInAppRemoved(messageId: String) {
    }
    
    func isOkToShowNow(message: IterableInAppMessage) -> Bool {
        return true
    }
}

