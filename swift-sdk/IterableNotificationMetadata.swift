//
//  IterableNotificationMetadata.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/**
 `IterableNotificationMetadata` represents the metadata in an Iterable push notification
 */
@objc public class IterableNotificationMetadata: NSObject {
    /**
     The campaignId of this notification
     */
    @objc public var campaignId: NSNumber = NSNumber(value: 0)
    /**
     The templateId of this notification
     */
    @objc public var templateId: NSNumber? = nil
    /**
     The messageId of this notification
     */
    @objc public var messageId: String? = nil
    /**
     Whether this notification is a ghost push
     */
    @objc public var isGhostPush: Bool = false

    /**
     Creates an `IterableNotificationMetadata` from a push payload
     
     - parameter userInfo:  The notification payload
     
     - returns:    an instance of `IterableNotificationMetadata` with the specified properties; `nil` if this isn't an Iterable notification
     
     - warning:   `metadataFromLaunchOptions` will return `nil` if `userInfo` isn't an Iterable notification
     */
    @objc public static func metadata(fromLaunchOptions userInfo: [AnyHashable: Any]) -> IterableNotificationMetadata? {
        guard NotificationHelper.isValidIterableNotification(userInfo: userInfo) else {
            return nil
        }
        
        return IterableNotificationMetadata(fromLaunchOptions: userInfo)
    }
    
    /**
     Creates an `IterableNotificationMetadata` from a inApp notification
     
     - parameter messageId:    The notification messageId
     
     - returns:    an instance of `IterableNotificationMetadata` with the messageId set
     */
    @objc public static func metadata(fromInAppOptions messageId: String) -> IterableNotificationMetadata {
        return IterableNotificationMetadata(fromInAppOptions: messageId)
    }

    
    //MARK: Utility functions
    /**
     - returns: `true` if this push is a proof push. `false` otherwise.
     */
    @objc public func isProof() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue != 0
    }
    
    /**
     - returns: `true` if this is a test push, `false` otherwise.
     */
    @objc public func isTestPush() -> Bool {
        return campaignId.intValue == 0 && templateId?.intValue == 0
    }
    
    /**
     - returns: `true` if this is a non-ghost, non-proof, non-test real send. `false` otherwisel
     */
    @objc public func isRealCampaignNotification() -> Bool {
        return !(isGhostPush || isProof() || isTestPush())
    }

    // MARK: Internal and Private
    
    private init(fromLaunchOptions userInfo: [AnyHashable: Any]) {
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
    
    private init(fromInAppOptions messageId: String) {
        self.messageId = messageId
    }
}
