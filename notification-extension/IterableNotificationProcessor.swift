//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UserNotifications
//import IterableSDK

class IterableNotificationProcessor {
    func processRequestForDuplicateMessageIds(_ request: UNNotificationRequest) -> Bool {
        print("jay processRequestForDuplicateMessageIds ENTRY")
        
        guard hasDuplicateMessageIds(request) else {
            print("jay didReceive added messageId: " + getMessageId(from: request))
            trackAntiDuplicateMessageId(request)
            
            // return false to tell the NSE that there are no dupes in this payload
            return false
        }
        
//        guard let duplicateInAppMessage = IterableAPI.inAppManager.getMessage(withId: getMessageId(from: request)) else {
//            return false
//        }
        
        // remove from in-app queue
//        IterableAPI.inAppConsume(message: duplicateInAppMessage)
        
        // call de-dupe endpoint
//        IterableAPI.trackDupSend(message: duplicateInAppMessage, eventType: "pushSend")
        
        // return true to tell the NSE to suppress the notification per https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering
        return true
    }
    
    
    // MARK: - Private/Internal
    
    private func hasDuplicateMessageIds(_ request: UNNotificationRequest) -> Bool {
        print("jay isDuplicateMessageId messageId: \(getMessageId(from: request))")
        print("jay isDuplicateMessageId tracking: \(duplicateMessageIdQueue)")
        
        
        
        return true
    }
    
    private static func getDuplicateMessageIdQueue() -> NSMutableOrderedSet {
        // serialize FROM storage here, return if existing
        
        return NSMutableOrderedSet()
    }
    
    private func trackAntiDuplicateMessageId(_ request: UNNotificationRequest) {
        duplicateMessageIdQueue.add(getMessageId(from: request))
        
        if duplicateMessageIdQueue.count > IterableNotificationProcessor.duplicateMessageIdQueueSize {
            _ = duplicateMessageIdQueue.dropFirst()
        }
        
        print("jay trackAntiDuplicateMessageId: \(duplicateMessageIdQueue)")
        
        // serialize TO storage here
    }
    
    private func getMessageId(from request: UNNotificationRequest) -> String {
        if let messageId = NotificationContentParser.getIterableMessageId(from: request.content) {
            print("jay getMessageId: \(messageId)")
            return messageId
        }
        
        return ""
    }
    
    private static let duplicateMessageIdQueueSize = 10
    private var duplicateMessageIdQueue = IterableNotificationProcessor.getDuplicateMessageIdQueue()
}
