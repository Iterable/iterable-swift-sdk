//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

class IterablePushNotificationMetadata: IterableNotificationMetadata {
    var isGhostPush: Bool = false
    
    /**
     Creates an `IterableNotificationMetadata` from a push payload
     
     - parameter userInfo:  The notification payload
     - returns:    an instance of `IterableNotificationMetadata` with the specified properties; `nil` if this isn't an Iterable notification
     - warning:   `metadataFromLaunchOptions` will return `nil` if `userInfo` isn't an Iterable notification
     */
    public static func metadata(fromLaunchOptions userInfo: [AnyHashable: Any]) -> IterablePushNotificationMetadata? {
        guard NotificationHelper.isValidIterableNotification(userInfo: userInfo) else {
            return nil
        }
        
        return IterablePushNotificationMetadata(fromLaunchOptions: userInfo)
    }
    
    private init(fromLaunchOptions userInfo: [AnyHashable: Any]) {
        super.init()
        
        let notificationInfo = NotificationHelper.inspect(notification: userInfo)
        
        switch notificationInfo {
        case let .iterable(iterableNotification):
            campaignId = iterableNotification.campaignId
            templateId = iterableNotification.templateId
            messageId = iterableNotification.messageId
            isGhostPush = iterableNotification.isGhostPush
        case .nonIterable:
            break
        case .silentPush:
            isGhostPush = true
        }
    }
    
    public func isRealCampaignNotification() -> Bool {
        return !(isGhostPush || isProof() || isTestPush())
    }
}

class IterableNotificationMetadata: NSObject {
    var campaignId: NSNumber = NSNumber(value: 0)
    var templateId: NSNumber?
    var messageId: String?
    
    public func isProof() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue != 0
    }
    
    public func isTestPush() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue == 0
    }
}
