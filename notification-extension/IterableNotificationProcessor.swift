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
            trackAntiDuplicateMessageId(request)
            
            print("jay processRequestForDuplicateMessageIds EXIT false")
            // return false to tell the NSE that there are no dupes in this payload
            return false
        }
        
        print("jay processRequestForDuplicateMessageIds FOUND DUPLICATE!!! \(getMessageId(from: request) ?? "nil")")
        print("jay processRequestForDuplicateMessageIds queue: \(dupSendQueue)")
        
//        guard let duplicateInAppMessage = IterableAPI.inAppManager.getMessage(withId: getMessageId(from: request)) else {
//            return false
//        }
        
        // call de-dupe endpoint
//        IterableAPI.trackDupSend(message: duplicateInAppMessage, eventType: "pushSend")
        
        print("jay processRequestForDuplicateMessageIds EXIT true")
        // return true to tell the NSE to suppress the notification per https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering
        return true
    }
    
    // MARK: - Private/Internal
    
    private func hasDuplicateMessageId(_ request: UNNotificationRequest) -> Bool {
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
        
        if dupSendQueue.count > IterableNotificationProcessor.DupSendQueueSize {
            dupSendQueue.removeObjects(in: NSRange(0...(dupSendQueue.count - IterableNotificationProcessor.DupSendQueueSize - 1)))
        }
        
        saveDupSendQueueToStorage()
    }
    
    private func getMessageId(from request: UNNotificationRequest) -> String? {
        return NotificationContentParser.getIterableMessageId(from: request.content)
    }
    
    private func restoreDupSendQueueFromStorage() {
        if let arrayFromStorage = UserDefaults.standard.array(forKey: IterableNotificationProcessor.DupSendQueueUserDefaultsKey) {
            dupSendQueue = NSMutableOrderedSet(array: arrayFromStorage)
        }
    }
    
    private func saveDupSendQueueToStorage() {
        if dupSendQueue.array.isEmpty {
            UserDefaults.standard.removeObject(forKey: IterableNotificationProcessor.DupSendQueueUserDefaultsKey)
            return
        }
        
        UserDefaults.standard.set(dupSendQueue.array, forKey: IterableNotificationProcessor.DupSendQueueUserDefaultsKey)
    }
    
    private static let DupSendQueueUserDefaultsKey = "itbl_dup_send_queue"
    private static let DupSendQueueSize = 10
    private var dupSendQueue = NSMutableOrderedSet()
}
