//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

class EmptyInAppManager: IterableInternalInAppManagerProtocol {
    
    func start() -> Pending<Bool, Error> {
        Fulfill<Bool, Error>(value: true)
    }
    
    func handleClick(clickedUrl _: URL?, forMessage _: IterableInAppMessage, location _: InAppLocation, inboxSessionId _: String?) {}
    
    var isAutoDisplayPaused: Bool {
        get {
            false
        }
        
        set {}
    }
    
    func getMessages() -> [IterableInAppMessage] {
        []
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        []
    }
    
    func show(message _: IterableInAppMessage) {}
    
    func show(message _: IterableInAppMessage, consume _: Bool, callback _: ITBURLCallback?) {}
    
    func remove(message _: IterableInAppMessage) {}
    
    func remove(message _: IterableInAppMessage, successHandler _: OnSuccessHandler?, failureHandler _: OnFailureHandler?) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation, successHandler _: OnSuccessHandler?, failureHandler _: OnFailureHandler?) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation, source _: InAppDeleteSource) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation, source _: InAppDeleteSource, successHandler _: OnSuccessHandler?, failureHandler _: OnFailureHandler?) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation, source _: InAppDeleteSource, inboxSessionId _: String?) {}
    
    func remove(message _: IterableInAppMessage, location _: InAppLocation, source _: InAppDeleteSource, inboxSessionId _: String?, successHandler _: OnSuccessHandler?, failureHandler _: OnFailureHandler?) {}
    
    func set(read _: Bool, forMessage _: IterableInAppMessage) {}
    
    func set(read _: Bool, forMessage _: IterableInAppMessage, successHandler _: OnSuccessHandler?, failureHandler _: OnFailureHandler?) {}
    
    func getMessage(withId _: String) -> IterableInAppMessage? {
        nil
    }
    
    func getUnreadInboxMessagesCount() -> Int {
        0
    }
    
    func scheduleSync() -> Pending<Bool, Error> {
        Fulfill<Bool, Error>(value: true)
    }
    
    func onInAppRemoved(messageId _: String) {}
    
    func isOkToShowNow(message _: IterableInAppMessage) -> Bool {
        true
    }
    
    func reset() -> Pending<Bool, Error> {
        Fulfill<Bool, Error>(value: true)
    }
}
