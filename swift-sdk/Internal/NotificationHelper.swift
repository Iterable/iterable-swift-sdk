//
//
//  Created by Tapash Majumder on 1/9/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum NotificationInfo {
    case silentPush(ITBLSilentPushNotificationInfo)
    case iterable(ITBLNotificationInfo)
    case nonIterable
}

struct ITBLNotificationInfo {
    let campaignId: NSNumber
    let templateId: NSNumber?
    let messageId: String?
    let isGhostPush: Bool
    
    init(campaignId: NSNumber, templateId: NSNumber?, messageId: String?, isGhostPush: Bool) {
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
        self.isGhostPush = isGhostPush
    }
    
    static func parse(itblElement : [AnyHashable : Any], isGhostPush: Bool) -> ITBLNotificationInfo {
        let campaignId = itblElement[Keys.campaignId.rawValue] as? NSNumber ?? NSNumber(value: 0)
        let templateId = itblElement[Keys.templateId.rawValue] as? NSNumber
        let messageId = itblElement[Keys.messageId.rawValue] as? String

        return ITBLNotificationInfo(campaignId: campaignId, templateId: templateId, messageId: messageId, isGhostPush: isGhostPush)
    }

    enum Keys : String {
        case messageId
        case templateId
        case campaignId
        case isGhostPush
    }
}

struct ITBLSilentPushNotificationInfo {
    let notificationType: ITBLSilentPushNotificationType
    let messageId: String?

    enum ITBLSilentPushNotificationType : String, Codable {
        case remove = "InAppRemove"
        case update = "InAppUpdate"
    }
    
    static func parse(notification: [AnyHashable : Any]) -> ITBLSilentPushNotificationInfo? {
        guard let notificationType = notification[Keys.notificationType.rawValue] as? String, let silentPushNotificationType = ITBLSilentPushNotificationType(rawValue: notificationType) else {
            return nil
        }
        
        let silentPushNotificationInfo = ITBLSilentPushNotificationInfo(notificationType: silentPushNotificationType, messageId: notification[Keys.messageId.rawValue] as? String)
        return silentPushNotificationInfo
    }

    private enum Keys: String {
        case notificationType
        case messageId
    }
}

struct NotificationHelper {
    static func inspect(notification: [AnyHashable : Any]) -> NotificationInfo {
        guard let itblElement = notification[Keys.itbl.rawValue] as? [AnyHashable : Any] else {
            return NotificationInfo.nonIterable
        }

        if let isGhostPush = itblElement[ITBLNotificationInfo.Keys.isGhostPush.rawValue] as? Bool {
            if isGhostPush == true {
                if let silentPush = ITBLSilentPushNotificationInfo.parse(notification: notification) {
                    return .silentPush(silentPush)
                } else {
                    return .iterable(ITBLNotificationInfo.parse(itblElement: itblElement, isGhostPush: isGhostPush))
                }
            } else {
                return .iterable(ITBLNotificationInfo.parse(itblElement: itblElement, isGhostPush: isGhostPush))
            }
            
        } else {
            return .iterable(ITBLNotificationInfo.parse(itblElement: itblElement, isGhostPush: false))
        }
    }
  
    static func isValidIterableNotification(userInfo: [AnyHashable : Any]) -> Bool {
        guard let itblElement = userInfo[Keys.itbl.rawValue] as? [AnyHashable : Any] else {
            return false
        }
        guard isValidCampaignId(itblElement[ITBLNotificationInfo.Keys.campaignId.rawValue]) else {
            return false
        }
        guard let _ = itblElement[ITBLNotificationInfo.Keys.templateId.rawValue] as? NSNumber else {
            return false
        }
        guard let _ = itblElement[ITBLNotificationInfo.Keys.messageId.rawValue] as? NSString else {
            return false
        }
        guard let _ = itblElement[ITBLNotificationInfo.Keys.isGhostPush.rawValue] as? NSNumber else {
            return false
        }
        
        return true
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

    private enum Keys: String {
        case itbl
        case notificationType
        case messageId
    }
}




