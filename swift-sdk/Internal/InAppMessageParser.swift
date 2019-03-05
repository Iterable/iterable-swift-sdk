//
//
//  Created by Tapash Majumder on 3/5/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

struct InAppMessageParser {
    /// Given json payload, It will construct array of IterableInAppMessage
    /// This will also make sure to consume any invalid inAppMessage.
    static func inAppMessages(fromPayload payload: [AnyHashable : Any], internalApi: IterableAPIInternal) -> [IterableMessageProtocol] {
        return parseInApps(fromPayload: payload).map { toMessage(fromInAppParseResult: $0, internalApi: internalApi) }.compactMap { $0 }
    }
    
    private enum InAppParseResult {
        case success(InAppDetails)
        case failure(reason: String, messageId: String?)
    }
    
    /// This is a struct equivalent of IterableInAppMessage class
    private struct InAppDetails {
        let inAppType: IterableInAppType
        let content: IterableContent
        let messageId: String
        let campaignId: String
        let trigger: IterableInAppTrigger
        let expiresAt: Date?
        let customPayload: [AnyHashable : Any]?
    }
    
    private struct InAppParseDetails {
        let inAppType: IterableInAppType
        let content: IterableContent
        let messageId: String
        let campaignId: String
        let expiresAt: Date?
        let customPayload: [AnyHashable : Any]?
    }
    
    /// Returns an array of Dictionaries holding inApp messages.
    private static func getInAppDicts(fromPayload payload: [AnyHashable : Any]) -> [[AnyHashable : Any]] {
        return payload[.ITBL_IN_APP_MESSAGE] as? [[AnyHashable : Any]] ?? []
    }
    
    private static func parseInApps(fromPayload payload: [AnyHashable : Any]) -> [InAppParseResult] {
        return getInAppDicts(fromPayload: payload).map {
            parseInApp(fromDict: preProcess(dict: $0))
        }
    }
    
    // Change the in-app payload coming from the server to one that we expect it to be like
    // This is temporary until we fix the backend to do the right thing.
    // 1. Move 'inAppType', to top level from 'customPayload'
    // 2. Move 'contentType' to 'content' element.
    //!! Remove when we have backend support
    private static func preProcess(dict: [AnyHashable : Any]) -> [AnyHashable : Any] {
        var result = dict
        guard var customPayloadDict = dict[.ITBL_IN_APP_CUSTOM_PAYLOAD] as? [AnyHashable : Any] else {
            return result
        }
        
        moveValue(withKey: AnyHashable.ITBL_IN_APP_INAPP_TYPE, from: &customPayloadDict, to: &result)
        
        if var contentDict = dict[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] {
            moveValue(withKey: AnyHashable.ITBL_IN_APP_CONTENT_TYPE, from: &customPayloadDict, to: &contentDict)
            moveValue(withKey: JsonKey.inboxTitle.rawValue, from: &customPayloadDict, to: &contentDict)
            moveValue(withKey: JsonKey.inboxSubtitle.rawValue, from: &customPayloadDict, to: &contentDict)
            moveValue(withKey: JsonKey.inboxIcon.rawValue, from: &customPayloadDict, to: &contentDict)
            result[.ITBL_IN_APP_CONTENT] = contentDict
        }
        
        result[.ITBL_IN_APP_CUSTOM_PAYLOAD] = customPayloadDict
        
        return result
    }
    
    private static func moveValue(withKey key: String, from source: inout [AnyHashable : Any], to destination: inout [AnyHashable : Any]) {
        guard destination[key] == nil else {
            // value exists in destination, so don't override
            return
        }
        
        if let value = source[key] {
            destination[key] = value
            source[key] = nil
        }
    }

    private static func parseInApp_New(fromDict dict: [AnyHashable : Any]) -> InAppParseResult {
        guard let messageId = dict[.ITBL_KEY_MESSAGE_ID] as? String else {
            return .failure(reason: "no message id", messageId: nil)
        }
        
        let inAppType: IterableInAppType
        if let inAppTypeStr = dict[.ITBL_IN_APP_INAPP_TYPE] as? String {
            inAppType = IterableInAppType.from(string: inAppTypeStr)
        } else {
            inAppType = .default
        }
        
        guard let contentDict = dict[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(reason: "no content in json payload", messageId: messageId)
        }
        
        let content: IterableContent
        switch (InAppContentParser.parse(contentDict: contentDict)) {
        case .success(let parsedContent):
            content = parsedContent
        case .failure(let reason):
            return .failure(reason: reason, messageId: messageId)
        }
        
        let campaignId: String
        if let theCampaignId = dict[.ITBL_KEY_CAMPAIGN_ID] as? String {
            campaignId = theCampaignId
        } else {
            ITBDebug("Could not find campaignId") // This is debug level because this happens a lot with proof inApps
            campaignId = ""
        }
        
        let customPayload = parseCustomPayload(fromPayload: dict)
        
        let trigger = parseTrigger(fromTriggerElement: dict[.ITBL_IN_APP_TRIGGER] as? [AnyHashable : Any])
        let expiresAt = parseExpiresAt(dict: dict)
        
        return .success(InAppDetails(
            inAppType: inAppType,
            content: content,
            messageId: messageId,
            campaignId: campaignId,
            trigger: trigger,
            expiresAt: expiresAt,
            customPayload: customPayload))
    }

    
    private static func parseInApp(fromDict dict: [AnyHashable : Any]) -> InAppParseResult {
        guard let messageId = dict[.ITBL_KEY_MESSAGE_ID] as? String else {
            return .failure(reason: "no message id", messageId: nil)
        }
        
        let inAppType: IterableInAppType
        if let inAppTypeStr = dict[.ITBL_IN_APP_INAPP_TYPE] as? String {
            inAppType = IterableInAppType.from(string: inAppTypeStr)
        } else {
            inAppType = .default
        }
        
        guard let contentDict = dict[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(reason: "no content in json payload", messageId: messageId)
        }
        
        let content: IterableContent
        switch (InAppContentParser.parse(contentDict: contentDict)) {
        case .success(let parsedContent):
            content = parsedContent
        case .failure(let reason):
            return .failure(reason: reason, messageId: messageId)
        }
        
        let campaignId: String
        if let theCampaignId = dict[.ITBL_KEY_CAMPAIGN_ID] as? String {
            campaignId = theCampaignId
        } else {
            ITBDebug("Could not find campaignId") // This is debug level because this happens a lot with proof inApps
            campaignId = ""
        }
        
        let customPayload = parseCustomPayload(fromPayload: dict)
        
        let trigger = parseTrigger(fromTriggerElement: dict[.ITBL_IN_APP_TRIGGER] as? [AnyHashable : Any])
        let expiresAt = parseExpiresAt(dict: dict)
        
        return .success(InAppDetails(
            inAppType: inAppType,
            content: content,
            messageId: messageId,
            campaignId: campaignId,
            trigger: trigger,
            expiresAt: expiresAt,
            customPayload: customPayload))
    }
    
    private static func parseExpiresAt(dict: [AnyHashable : Any]) -> Date? {
        guard let intValue = dict[.ITBL_IN_APP_EXPIRES_AT] as? Int else {
            return nil
        }
        
        let seconds = Double(intValue) / 1000.0
        return Date(timeIntervalSince1970: seconds)
    }
    
    private static func parseTrigger(fromTriggerElement element: [AnyHashable : Any]?) -> IterableInAppTrigger {
        guard let element = element else {
            return .defaultTrigger // if element is missing return default which is immediate
        }
        
        return IterableInAppTrigger(dict: element)
    }
    
    private static func parseCustomPayload(fromPayload payload: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        return payload[.ITBL_IN_APP_CUSTOM_PAYLOAD] as? [AnyHashable : Any]
    }
    
    private static func toMessage(fromInAppParseResult inAppParseResult: InAppParseResult, internalApi: IterableAPIInternal) -> IterableMessageProtocol? {
        switch inAppParseResult {
        case .success(let inAppDetails):
            switch inAppDetails.inAppType {
            case .default:
                return IterableInAppMessage(messageId: inAppDetails.messageId,
                                            campaignId: inAppDetails.campaignId,
                                            trigger: inAppDetails.trigger,
                                            expiresAt: inAppDetails.expiresAt,
                                            content: inAppDetails.content,
                                            customPayload: inAppDetails.customPayload)
            case .inbox:
                return IterableInboxMessage(messageId: inAppDetails.messageId,
                                            campaignId: inAppDetails.campaignId,
                                            expiresAt: inAppDetails.expiresAt,
                                            content: inAppDetails.content,
                                            customPayload: inAppDetails.customPayload)
            }
        case .failure(reason: let reason, messageId: let messageId):
            ITBError(reason)
            if let messageId = messageId {
                internalApi.inAppConsume(messageId)
            }
            return nil
        }
    }

}
