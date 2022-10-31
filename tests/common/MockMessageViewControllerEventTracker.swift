//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockMessageViewControllerEventTracker: MessageViewControllerEventTrackerProtocol {
    var trackInAppOpenCallback: ((IterableInAppMessage, InAppLocation, String?) -> Void)?
    var trackInAppCloseCallback: ((IterableInAppMessage, InAppLocation, String?, InAppCloseSource?, String?) -> Void)?
    var trackInAppClickCallback: ((IterableInAppMessage, InAppLocation, String?, String?) -> Void)?
    
    func trackInAppOpen(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?) {
        trackInAppOpenCallback?(message, location, inboxSessionId)
    }
    
    func trackInAppClose(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?, source: InAppCloseSource?, clickedUrl: String?) {
        trackInAppCloseCallback?(message, location, inboxSessionId, source, clickedUrl)
    }
    
    func trackInAppClick(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?, clickedUrl: String) {
        trackInAppClickCallback?(message, location, inboxSessionId, clickedUrl)
    }
}
