//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct IterablePushNotificationMetadata {
    let campaignId: NSNumber
    let templateId: NSNumber?
    let messageId: String?
    let isGhostPush: Bool
    
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
        let notificationInfo = NotificationHelper.inspect(notification: userInfo)
        
        switch notificationInfo {
        case let .iterable(iterableNotification):
            campaignId = iterableNotification.campaignId
            templateId = iterableNotification.templateId
            messageId = iterableNotification.messageId
            isGhostPush = iterableNotification.isGhostPush
        case .nonIterable:
            campaignId = NSNumber(0)
            templateId = nil
            messageId = nil
            isGhostPush = false
        case .silentPush:
            campaignId = NSNumber(0)
            templateId = nil
            messageId = nil
            isGhostPush = true
        }
    }
    
    func isRealCampaignNotification() -> Bool {
        return !(isGhostPush || isProof() || isTestPush())
    }
    
    func isProof() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue != 0
    }
    
    func isTestPush() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue == 0
    }
}
