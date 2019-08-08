//
//
//  Created by Tapash Majumder on 11/20/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

struct TestInAppPayloadGenerator {
    static func createPayloadWithUrl(numMessages: Int, triggerType: IterableInAppTriggerType = .immediate, expiresAt: Date? = nil) -> [AnyHashable: Any] {
        return createPayloadWithUrl(indices: 1 ... numMessages, triggerType: triggerType, expiresAt: expiresAt)
    }
    
    static func createPayloadWithUrl<T: Sequence>(indices: T, triggerType: IterableInAppTriggerType = .immediate, expiresAt: Date? = nil) -> [AnyHashable: Any] where T.Element == Int {
        return [
            "inAppMessages": indices.reduce(into: [[AnyHashable: Any]]()) { result, index in
                result.append(createOneInAppDictWithUrl(index: index, triggerType: triggerType, expiresAt: expiresAt))
            },
        ]
    }
    
    static func createPayloadWithCustomAction(numMessages: Int, triggerType: IterableInAppTriggerType = .immediate) -> [AnyHashable: Any] {
        return [
            "inAppMessages": (1 ... numMessages).reduce(into: [[AnyHashable: Any]]()) { result, index in
                result.append(createOneInAppDictWithCustomAction(index: index, triggerType: triggerType))
            },
        ]
    }
    
    static func getMessageId(index: Int) -> String {
        return "message\(index)"
    }
    
    static func getCampaignId(index: Int) -> String {
        return "campaign\(index)"
    }
    
    static func getClickedUrl(index: Int) -> URL {
        return URL(string: getClickedLink(index: index))!
    }
    
    static func getCustomActionUrl(index: Int) -> URL {
        return URL(string: "action://\(getCustomActionName(index: index))")!
    }
    
    static func getCustomActionName(index: Int) -> String {
        return "action\(index)"
    }
    
    static func index(fromCampaignId campaignId: String) -> Int {
        return Int(String(campaignId.suffix(1)))!
    }
    
    static func createOneInAppDictWithUrl(index: Int, trigger: IterableInAppTrigger?, expiresAt: Date? = nil) -> [AnyHashable: Any] {
        return createOneInAppDict(withHref: getClickedLink(index: index), index: index, trigger: trigger, expiresAt: expiresAt)
    }
    
    static func createOneInAppDictWithUrl(index: Int, triggerType: IterableInAppTriggerType, expiresAt: Date? = nil) -> [AnyHashable: Any] {
        return createOneInAppDict(withHref: getClickedLink(index: index), index: index, trigger: trigger(fromTriggerType: triggerType), expiresAt: expiresAt)
    }
    
    static func createOneInAppDictWithCustomAction(index: Int, triggerType: IterableInAppTriggerType) -> [AnyHashable: Any] {
        return createOneInAppDict(withHref: getCustomActionUrl(index: index).absoluteString, index: index, trigger: trigger(fromTriggerType: triggerType), expiresAt: nil)
    }
    
    private static func createOneInAppDict(withHref href: String, index: Int, trigger: IterableInAppTrigger?, expiresAt: Date?) -> [AnyHashable: Any] {
        var dict = createOneInAppDict(withHref: href, index: index)
        if let expiresAt = expiresAt {
            dict["expiresAt"] = IterableUtil.int(fromDate: expiresAt)
        }
        if let trigger = trigger {
            dict["trigger"] = trigger.dict
        }
        return dict
    }
    
    private static func createOneInAppDict(withHref href: String, index: Int) -> [AnyHashable: Any] {
        return [
            "content": [
                "html": "<a href='\(href)'>Click Here</a>",
                "inAppDisplaySettings": ["backgroundAlpha": 0.5, "left": ["percentage": 60], "right": ["percentage": 60], "bottom": ["displayOption": "AutoExpand"], "top": ["displayOption": "AutoExpand"]],
            ],
            "messageId": getMessageId(index: index),
            "campaignId": getCampaignId(index: index),
            "customPayload": ["title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"],
        ]
    }
    
    private static func trigger(fromTriggerType triggerType: IterableInAppTriggerType) -> IterableInAppTrigger {
        return IterableInAppTrigger(dict: ["type": String(describing: triggerType)])
    }
    
    private static func getClickedLink(index: Int) -> String {
        return "https://www.site\(index).com"
    }
}
