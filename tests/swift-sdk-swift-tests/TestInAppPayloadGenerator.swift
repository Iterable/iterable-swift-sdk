//
//  Created by Tapash Majumder on 11/20/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

struct TestInAppPayloadGenerator {
    static func createPayloadWithUrl(numMessages: Int, triggerType: IterableInAppTriggerType = .immediate, expiresAt: Date? = nil, saveToInbox: Bool = false) -> [AnyHashable: Any] {
        createPayloadWithUrl(indices: 1 ... numMessages, triggerType: triggerType, expiresAt: expiresAt, saveToInbox: saveToInbox)
    }
    
    static func createPayloadWithUrl<T: Sequence>(indices: T, triggerType: IterableInAppTriggerType = .immediate, expiresAt: Date? = nil, saveToInbox: Bool = false) -> [AnyHashable: Any] where T.Element == Int {
        [
            "inAppMessages": indices.reduce(into: [[AnyHashable: Any]]()) { result, index in
                result.append(createOneInAppDictWithUrl(index: index, triggerType: triggerType, expiresAt: expiresAt, saveToInbox: saveToInbox))
            },
        ]
    }
    
    static func createPayloadWithCustomAction(numMessages: Int, triggerType: IterableInAppTriggerType = .immediate, saveToInbox: Bool = false) -> [AnyHashable: Any] {
        [
            "inAppMessages": (1 ... numMessages).reduce(into: [[AnyHashable: Any]]()) { result, index in
                result.append(createOneInAppDictWithCustomAction(index: index, triggerType: triggerType, saveToInbox: saveToInbox))
            },
        ]
    }
    
    static func getMessageId(index: Int) -> String {
        "message\(index)"
    }
    
    static func getCampaignId(index: Int) -> Int {
        index
    }
    
    static func getClickedUrl(index: Int) -> URL {
        URL(string: getClickedLink(index: index))!
    }
    
    static func getCustomActionUrl(index: Int) -> URL {
        URL(string: "action://\(getCustomActionName(index: index))")!
    }
    
    static func getCustomActionName(index: Int) -> String {
        "action\(index)"
    }
    
    static func index(fromCampaignId campaignId: NSNumber?) -> Int {
        (campaignId as? Int) ?? -1
    }
    
    static func createOneInAppDictWithUrl(index: Int, trigger: IterableInAppTrigger?, expiresAt: Date? = nil, saveToInbox: Bool = false) -> [AnyHashable: Any] {
        createOneInAppDict(withHref: getClickedLink(index: index), index: index, trigger: trigger, expiresAt: expiresAt, saveToInbox: saveToInbox)
    }
    
    static func createOneInAppDictWithUrl(index: Int, triggerType: IterableInAppTriggerType, expiresAt: Date? = nil, saveToInbox: Bool = false) -> [AnyHashable: Any] {
        createOneInAppDict(withHref: getClickedLink(index: index), index: index, trigger: trigger(fromTriggerType: triggerType), expiresAt: expiresAt, saveToInbox: saveToInbox)
    }
    
    static func createOneInAppDictWithCustomAction(index: Int, triggerType: IterableInAppTriggerType, saveToInbox: Bool = false) -> [AnyHashable: Any] {
        createOneInAppDict(withHref: getCustomActionUrl(index: index).absoluteString, index: index, trigger: trigger(fromTriggerType: triggerType), expiresAt: nil, saveToInbox: saveToInbox)
    }
    
    private static func createOneInAppDict(withHref href: String, index: Int, trigger: IterableInAppTrigger?, expiresAt: Date?, saveToInbox: Bool = false) -> [AnyHashable: Any] {
        var dict = createOneInAppDict(withHref: href, index: index)
        if let expiresAt = expiresAt {
            dict["expiresAt"] = IterableUtil.int(fromDate: expiresAt)
        }
        if let trigger = trigger {
            dict["trigger"] = trigger.dict
        }
        if saveToInbox {
            dict[JsonKey.saveToInbox.jsonKey] = true
            dict[JsonKey.inboxMetadata.jsonKey] = [
                JsonKey.inboxTitle.jsonKey: "title\(index)",
                JsonKey.inboxSubtitle.jsonKey: "subTitle\(index)",
            ]
        }
        return dict
    }
    
    private static func createOneInAppDict(withHref href: String, index: Int) -> [AnyHashable: Any] {
        let html = """
        <body bgColor="#FFF">
            <div style="width:100px;height:100px;position:absolute;margin:auto;top:0;bottom:0;left:0;right:0;"><a href="\(href)">Click Here\(index)</a></div>
        </body>
        """
        return [
            "content": [
                "html": html,
            ],
            "messageId": getMessageId(index: index),
            "campaignId": getCampaignId(index: index),
            "customPayload": ["title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"],
        ]
    }
    
    private static func trigger(fromTriggerType triggerType: IterableInAppTriggerType) -> IterableInAppTrigger {
        IterableInAppTrigger(dict: ["type": String(describing: triggerType)])
    }
    
    private static func getClickedLink(index: Int) -> String {
        "https://www.site\(index).com"
    }
}
