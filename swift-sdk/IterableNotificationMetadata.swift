//
//  IterableNotificationMetadata.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class IterableInAppMessageMetadata: IterableNotificationMetadata {
    @objc public var saveToInbox: Bool = false
    @objc public var silentInbox: Bool = false
    @objc public var location: String? = nil
    
    @objc public static func metadata(fromInAppOptions messageId: String, saveToInbox: Bool = false, silentInbox: Bool = false, location: String? = nil) -> IterableInAppMessageMetadata {
        return IterableInAppMessageMetadata(fromInAppOptions: messageId)
    }
    
    @objc public static func metadata(from inAppMessage: IterableInAppMessage, location: String? = nil) -> IterableInAppMessageMetadata {
        return IterableInAppMessageMetadata(from: inAppMessage, location: location)
    }
    
    private init(from message: IterableInAppMessage, location: String? = nil) {
        super.init()
        
        self.messageId = message.messageId
        self.saveToInbox = message.saveToInbox
        self.silentInbox = message.saveToInbox && message.trigger.type == .never
        self.location = location
    }
    
    private init(fromInAppOptions messageId: String, saveToInbox: Bool = false, silentInbox: Bool = false, location: String? = nil) {
        super.init()
        
        self.messageId = messageId
        self.saveToInbox = saveToInbox
        self.silentInbox = silentInbox
        self.location = location
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
    
    @objc public func isRealCampaignNotification() -> Bool {
        return !(isGhostPush || isProof() || isTestPush())
    }
}

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
