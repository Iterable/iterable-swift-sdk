//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UserNotifications
//import IterableSDK

class IterableNotificationProcessor {
    func processRequestForDuplicateMessageIds(_ request: UNNotificationRequest) -> Bool {
        print("jay processRequestForDuplicateMessageIds ENTRY")
        restoreDupSendQueueFromStorage()
        
        guard hasDuplicateMessageId(request) else {
            print("jay didReceive added messageId: \(getMessageId(from: request) ?? "nil")")
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
    
    private func hasDuplicateMessageId(_ request: UNNotificationRequest) -> Bool {
        print("jay isDuplicateMessageId tracking: \(dupSendQueue)")
        
        guard let messageId = NotificationContentParser.getIterableMessageId(from: request.content) else {
            return false
        }
        
        return dupSendQueue.contains(messageId)
    }
    
    private func trackAntiDuplicateMessageId(_ request: UNNotificationRequest) {
        guard let messageId = getMessageId(from: request) else {
            return
        }
        
        dupSendQueue.add(messageId)
        
        if dupSendQueue.count > IterableNotificationProcessor.dupSendQueueSize {
            dupSendQueue.removeObjects(in: NSRange(0...(dupSendQueue.count - IterableNotificationProcessor.dupSendQueueSize - 1)))
        }
        
        saveDupSendQueueToStorage()
    }
    
    private func getMessageId(from request: UNNotificationRequest) -> String? {
        return NotificationContentParser.getIterableMessageId(from: request.content)
    }
    
    private func restoreDupSendQueueFromStorage() {
        dupSendQueue = NSMutableOrderedSet(array: UserDefaults.standard.array(forKey: "itbl_dup_send_queue") ?? [])
    }
    
    private func saveDupSendQueueToStorage() {
        UserDefaults.standard.set(dupSendQueue.array, forKey: "itbl_dup_send_queue")
    }
    
    private static let dupSendQueueSize = 10
    private var dupSendQueue = NSMutableOrderedSet()
}
