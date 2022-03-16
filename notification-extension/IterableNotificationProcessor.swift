//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class IterableNotificationProcessor {
    func checkForDuplicateMessageIds(_ request: UNNotificationRequest) -> Bool {
        guard hasDuplicateMessageIds(request) else {
            print("jay didReceive added messageId: " + getMessageId(from: request))
            trackAntiDuplicateMessageId(request)
            
            // return false to tell the NSE that there are no dupes in this payload
            return false
        }
        
        // remove from in-app queue
        if let duplicateInAppMessage = IterableAPI.inAppManager.getMessage(withId: getMessageId(from: request)) {
            IterableAPI.inAppConsume(message: duplicateInAppMessage)
        }
        
        // call de-dupe endpoint
        
        
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
        // get the MESSAGE ID which is NOT `request.identifier`, but this is temporary
        return request.identifier
    }
    
    private static let duplicateMessageIdQueueSize = 10
    private var duplicateMessageIdQueue = IterableNotificationProcessor.getDuplicateMessageIdQueue()
}
