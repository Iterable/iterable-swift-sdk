//
//  IterableNotificationMetadata.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class IterableInAppMessageMetadata: IterableNotificationMetadata {
    //add RequestCreator fields here
    //trigger
    //saveToInbox
    //location (?)
    
    @objc public static func metadata(fromLaunchOptions userInfo: [AnyHashable: Any]) -> IterableInAppMessageMetadata? {
        guard NotificationHelper.isValidIterableNotification(userInfo: userInfo) else {
            return nil
        }
        
        return IterableInAppMessageMetadata(fromLaunchOptions: userInfo)
    }
    
    @objc public static func metadata(fromInAppOptions messageId: String) -> IterableInAppMessageMetadata {
        return IterableInAppMessageMetadata(fromInAppOptions: messageId)
    }
    
    //
    
    private init(fromLaunchOptions userInfo: [AnyHashable: Any]) {
        super.init()
        
        let notificationInfo = NotificationHelper.inspect(notification: userInfo)
        
        switch notificationInfo {
        case .iterable(let iterableNotification):
            self.campaignId = iterableNotification.campaignId
            self.templateId = iterableNotification.templateId
            self.messageId = iterableNotification.messageId
            break
        case .nonIterable:
            break
        case .silentPush:
            break
        }
    }
    
    private init(fromInAppOptions messageId: String) {
        super.init()
        
        self.messageId = messageId
    }
}

@objc public class IterablePushNotificationMetadata: IterableNotificationMetadata {
    @objc public var isGhostPush: Bool = false
    
    /**
     Creates an `IterableNotificationMetadata` from a push payload
     
     - parameter userInfo:  The notification payload
     
     - returns:    an instance of `IterableNotificationMetadata` with the specified properties; `nil` if this isn't an Iterable notification
     
     - warning:   `metadataFromLaunchOptions` will return `nil` if `userInfo` isn't an Iterable notification
     */
    @objc public static func metadata(fromLaunchOptions userInfo: [AnyHashable: Any]) -> IterablePushNotificationMetadata? {
        guard NotificationHelper.isValidIterableNotification(userInfo: userInfo) else {
            return nil
        }
        
        return IterablePushNotificationMetadata(fromLaunchOptions: userInfo)
    }
    
    private init(fromLaunchOptions userInfo: [AnyHashable: Any]) {
        super.init()
        
        let notificationInfo = NotificationHelper.inspect(notification: userInfo)
        
        switch notificationInfo {
        case .iterable(let iterableNotification):
            self.campaignId = iterableNotification.campaignId
            self.templateId = iterableNotification.templateId
            self.messageId = iterableNotification.messageId
            self.isGhostPush = iterableNotification.isGhostPush
            break
        case .nonIterable:
            break
        case .silentPush:
            self.isGhostPush = true
            break
        }
    }
    
    /**
     - returns: `true` if this is a non-ghost, non-proof, non-test real send. `false` otherwise
     */
    @objc public func isRealCampaignNotification() -> Bool {
        return !(isGhostPush || isProof() || isTestPush())
    }
}

/**
 `IterableNotificationMetadata` represents the metadata in an Iterable push notification
 */
@objc public class IterableNotificationMetadata: NSObject {
    @objc public var campaignId: NSNumber = NSNumber(value: 0)
    @objc public var templateId: NSNumber? = nil
    @objc public var messageId: String? = nil
    
    @objc public func isProof() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue != 0
    }
    
    @objc public func isTestPush() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue == 0
    }
}
