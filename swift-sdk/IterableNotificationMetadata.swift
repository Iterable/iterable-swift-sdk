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
@objc public class IterableNotificationMetadata : NSObject {
    private enum Keys : String {
        case metaData = "itbl"
        case campaignId = "campaignId"
        case templateId = "templateId"
        case messageId = "messageId"
        case ghostPush = "isGhostPush"
    }
    
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
    @objc public static func metadata(fromLaunchOptions userInfo: [AnyHashable : Any]) -> IterableNotificationMetadata? {
        guard isIterableNotification(userInfo: userInfo) else {
            return nil
        }
        
        return IterableNotificationMetadata(fromLaunchOptions: userInfo)
    }
    
    /**
     Creates an `IterableNotificationMetadata` from a inApp notification
     
     - parameter messageId:    The notification messageId
     
     - returns:    an instance of `IterableNotificationMetadata` with the messageId set
     */
    @objc public static func metadata(fromInAppOptions messageId:String) -> IterableNotificationMetadata {
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

    //MARK: Internal and Private
    static func isIterableNotification(userInfo: [AnyHashable : Any]) -> Bool {
        guard let pushData = userInfo[Keys.metaData.rawValue] as? [AnyHashable : Any] else {
            return false
        }
        guard isValidCampaignId(pushData[Keys.campaignId.rawValue]) else {
            return false
        }
        guard let _ = pushData[Keys.templateId.rawValue] as? NSNumber else {
            return false
        }
        guard let _ = pushData[Keys.messageId.rawValue] as? NSString else {
            return false
        }
        guard let _ = pushData[Keys.ghostPush.rawValue] as? NSNumber else {
            return false
        }
        
        return true
    }
    
    private init(fromLaunchOptions userInfo: [AnyHashable : Any]) {
        guard let pushData = userInfo[Keys.metaData.rawValue] as? [AnyHashable : Any] else {
            return
        }
        campaignId = pushData[Keys.campaignId.rawValue] as? NSNumber ?? NSNumber(value: 0)
        templateId = pushData[Keys.templateId.rawValue] as? NSNumber
        messageId = pushData[Keys.messageId.rawValue] as? String
        if let numberValue = pushData[Keys.ghostPush.rawValue] as? NSNumber {
            isGhostPush = numberValue.boolValue
        }
    }
    
    private init(fromInAppOptions messageId: String) {
        self.messageId = messageId
    }
    
    private static func isValidCampaignId(_ campaignId: Any?) -> Bool {
        // campaignId doesn't have to be there (because of proofs)
        guard let campaignId = campaignId else {
            return true
        }
        if let _ = campaignId as? NSNumber {
            return true
        } else {
            return false
        }
    }
}
