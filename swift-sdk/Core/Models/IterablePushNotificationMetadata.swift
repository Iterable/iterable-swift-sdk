//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

public struct IterablePushNotificationMetadata {
    public let campaignId: NSNumber
    public let templateId: NSNumber?
    public let messageId: String
    public let isGhostPush: Bool
    
    public static func metadata(fromLaunchOptions userInfo: [AnyHashable: Any]) -> IterablePushNotificationMetadata? {
        IterablePushNotificationMetadata(fromLaunchOptions: userInfo)
    }
    
    public func isRealCampaignNotification() -> Bool {
        !(isGhostPush || isProof() || isTestPush())
    }
    
    public func isProof() -> Bool {
        campaignId.intValue == 0 && templateId?.intValue != 0
    }
    
    public func isTestPush() -> Bool {
        campaignId.intValue == 0 && templateId?.intValue == 0
    }
}
