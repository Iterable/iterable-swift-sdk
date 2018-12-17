//
//
//  Created by Tapash Majumder on 11/20/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct TestInAppPayloadGenerator {
    static func createPayloadWithUrl(numMessages: Int) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : (1...numMessages).reduce(into: [[AnyHashable : Any]]()) { (result, index) in
                result.append(createOneInAppDictWithUrl(index: index))
            }
        ]
    }

    static func createPayloadWithCustomAction(numMessages: Int) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : (1...numMessages).reduce(into: [[AnyHashable : Any]]()) { (result, index) in
                result.append(createOneInAppDictWithCustomAction(index: index))
            }
        ]
    }

    static func createPayloadWithUrlWithOneMessage(messageNumber: Int) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : [createOneInAppDictWithUrl(index: messageNumber)]
        ]
    }

    static func createPayloadWithCustomActionWithOneMessage(messageNumber: Int) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : [createOneInAppDictWithCustomAction(index: messageNumber)]
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

    private static func createOneInAppDictWithUrl(index: Int) -> [AnyHashable : Any] {
        return createOneInAppDict(withHref: getClickUrl(index: index), index: index)
    }

    private static func createOneInAppDictWithCustomAction(index: Int) -> [AnyHashable : Any] {
        return createOneInAppDict(withHref: getCustomActionUrl(index: index), index: index)
    }

    private static func createOneInAppDict(withHref href: String, index: Int) -> [AnyHashable : Any] {
        return [
            "content" : [
                "html" : "<a href='\(href)'>Click Here</a>",
                "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]],
                "payload" : ["channelName" : "inBox", "title" : "Product 1 Available", "date" : "2018-11-14T14:00:00:00.32Z"]
            ],
            "messageId" : getMessageId(index: index),
            "campaignId" : getCampaignId(index: index),
        ]
    }
    
}
