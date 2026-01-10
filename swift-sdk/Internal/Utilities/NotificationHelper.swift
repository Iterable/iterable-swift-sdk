//
//  Copyright © 2019 Iterable. All rights reserved.
//

/// This file helps with parsing push notification information coming from the server

import Foundation

enum NotificationInfo {
    case silentPush(ITBLSilentPushNotificationInfo)
    case iterable(IterablePushNotificationMetadata)
    case liveActivity(IterableLiveActivityMetadata)
    case other
}

struct IterableLiveActivityMetadata {
    let vital: String
    let duration: TimeInterval
    let title: String
    
    static func parse(info: [String: Any]) -> IterableLiveActivityMetadata? {
        guard let vital = info["vital"] as? String,
              let duration = info["duration"] as? TimeInterval,
              let title = info["title"] as? String else {
            return nil
        }
        return IterableLiveActivityMetadata(vital: vital, duration: duration, title: title)
    }
}

struct ITBLSilentPushNotificationInfo {
    let notificationType: ITBLSilentPushNotificationType
    let messageId: String?
    
    enum ITBLSilentPushNotificationType: String, Codable {
        case remove = "InAppRemove"
        case update = "InAppUpdate"
        case updateEmbedded = "UpdateEmbedded"
    }
    
    static func parse(notification: [AnyHashable: Any]) -> ITBLSilentPushNotificationInfo? {
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
    static func inspect(notification: [AnyHashable: Any]) -> NotificationInfo {
        guard let itblElement = notification[Keys.itbl.rawValue] as? [AnyHashable: Any], let isGhostPush = itblElement[Keys.isGhostPush.rawValue] as? Bool else {
            return .other
        }
        
        if let liveActivityInfo = itblElement[Keys.liveActivity.rawValue] as? [String: Any],
           let metadata = IterableLiveActivityMetadata.parse(info: liveActivityInfo) {
            return .liveActivity(metadata)
        }
        
        if isGhostPush {
            if let silentPush = ITBLSilentPushNotificationInfo.parse(notification: notification) {
                return .silentPush(silentPush)
            } else {
                return tryCreateIterablePushNotificationMetadata(itblElement: itblElement, isGhostPush: true)
            }
        } else {
            return tryCreateIterablePushNotificationMetadata(itblElement: itblElement, isGhostPush: false)
        }
    }
    
    fileprivate static func tryCreateIterablePushNotificationMetadata(itblElement: [AnyHashable: Any], isGhostPush: Bool) -> NotificationInfo {
        if let iterablePushNotificationMetadata = IterablePushNotificationMetadata.parse(itblElement: itblElement, isGhostPush: isGhostPush) {
            return .iterable(iterablePushNotificationMetadata)
        } else {
            return .other
        }
    }
    
    private enum Keys: String {
        case itbl
        case isGhostPush
        case liveActivity
    }
}

extension IterablePushNotificationMetadata {
    init?(fromLaunchOptions userInfo: [AnyHashable: Any]) {
        if case let NotificationInfo.iterable(iterablePushNotificationMetadata) = NotificationHelper.inspect(notification: userInfo) {
            self = iterablePushNotificationMetadata
        } else {
            return nil
        }
    }
}

private extension IterablePushNotificationMetadata {
    static func parse(itblElement: [AnyHashable: Any],
                                  isGhostPush: Bool) -> IterablePushNotificationMetadata? {
        guard isValidCampaignId(itblElement[Keys.campaignId.rawValue]) else {
            return nil
        }
        
        guard let templateId = itblElement[Keys.templateId.rawValue] as? NSNumber else {
            return nil
        }
        
        guard let messageId = itblElement[Keys.messageId.rawValue] as? String else {
            return nil
        }
        
        let campaignId = itblElement[Keys.campaignId.rawValue] as? NSNumber ?? NSNumber(value: 0)
        
        return IterablePushNotificationMetadata(campaignId: campaignId,
                                                templateId: templateId,
                                                messageId: messageId,
                                                isGhostPush: isGhostPush)
    }
    
    static func isValidCampaignId(_ campaignId: Any?) -> Bool {
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

    enum Keys: String {
        case messageId
        case templateId
        case campaignId
    }
}
