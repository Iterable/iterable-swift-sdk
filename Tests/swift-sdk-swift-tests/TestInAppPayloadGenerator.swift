//
//
//  Created by Tapash Majumder on 11/20/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

struct TestInAppPayloadGenerator {
    static func createPayloadWithUrl(numMessages: Int, trigger: IterableInAppTriggerType = .immediate) -> [AnyHashable : Any] {
        return createPayloadWithUrl(indices: 1...numMessages, trigger: trigger)
    }
    
    static func createPayloadWithUrl<T: Sequence>(indices: T, trigger: IterableInAppTriggerType = .immediate) -> [AnyHashable : Any] where T.Element == Int {
        return [
            "inAppMessages" : indices.reduce(into: [[AnyHashable : Any]]()) { (result, index) in
                result.append(createOneInAppDictWithUrl(index: index, trigger: trigger))
            }
        ]
    }

    static func createPayloadWithCustomAction(numMessages: Int, trigger: IterableInAppTriggerType = .immediate) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : (1...numMessages).reduce(into: [[AnyHashable : Any]]()) { (result, index) in
                result.append(createOneInAppDictWithCustomAction(index: index, trigger: trigger))
            }
        ]
    }

    static func getMessageId(index: Int) -> String {
        return "message\(index)"
    }
    
    static func getCampaignId(index: Int) -> String {
        return "campaign\(index)"
    }
    
    static func getClickUrl(index: Int) -> String {
        return "https://www.site\(index).com"
    }

    static func getCustomActionUrl(index: Int) -> String {
        return "itbl://\(getCustomActionName(index: index))"
    }
    
    static func getCustomActionName(index: Int) -> String {
        return "action\(index)"
    }
    
    static func index(fromCampaignId campaignId: String) -> Int {
        return Int(String(campaignId.suffix(1)))!
    }

    static func createOneInAppDictWithUrl(index: Int, trigger: IterableInAppTriggerType) -> [AnyHashable : Any] {
        return createOneInAppDict(withHref: getClickUrl(index: index), index: index, trigger: trigger)
    }

    static func createOneInAppDictWithCustomAction(index: Int, trigger: IterableInAppTriggerType) -> [AnyHashable : Any] {
        return createOneInAppDict(withHref: getCustomActionUrl(index: index), index: index, trigger: trigger)
    }

    private static func createOneInAppDict(withHref href: String, index: Int, trigger: IterableInAppTriggerType) -> [AnyHashable : Any] {
        return [
            "content" : [
                "html" : "<a href='\(href)'>Click Here</a>",
                "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]],
                "payload" : ["channelName" : "inBox", "title" : "Product 1 Available", "date" : "2018-11-14T14:00:00:00.32Z"]
            ],
            "messageId" : getMessageId(index: index),
            "campaignId" : getCampaignId(index: index),
            "trigger" : String(describing: trigger)
        ]
    }
    
}
