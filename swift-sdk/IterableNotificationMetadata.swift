//
//  IterableNotificationMetadata.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc class IterableInAppMessageMetadata: IterableNotificationMetadata {
    @objc var saveToInbox: Bool = false
    @objc var silentInbox: Bool = false
    @objc var location: String? = nil
    
    @objc public static func metadata(from inAppMessage: IterableInAppMessage, location: String? = nil) -> IterableInAppMessageMetadata {
        return IterableInAppMessageMetadata(from: inAppMessage, location: location)
    }
    
    private init(from message: IterableInAppMessage, location: String? = nil) {
        super.init()
        
        self.campaignId = NSNumber(value: (Int(message.campaignId) ?? 0))
        self.messageId = message.messageId
        
        self.saveToInbox = message.saveToInbox
        self.silentInbox = message.saveToInbox && message.trigger.type == .never
        self.location = location
    }
}

@objc class IterablePushNotificationMetadata: IterableNotificationMetadata {
    @objc var isGhostPush: Bool = false
    
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
    
    @objc public func isRealCampaignNotification() -> Bool {
        return !(isGhostPush || isProof() || isTestPush())
    }
}

@objc class IterableNotificationMetadata: NSObject {
    @objc var campaignId: NSNumber = NSNumber(value: 0)
    @objc var templateId: NSNumber? = nil
    @objc var messageId: String? = nil
    
    @objc public func isProof() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue != 0
    }
    
    @objc public func isTestPush() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue == 0
    }
}
