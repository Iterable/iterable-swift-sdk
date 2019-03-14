//
//
//  Created by Tapash Majumder on 3/5/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

struct InAppMessageParser {
    enum ParseError : Error {
        case parseFailed(reason: String, messageId: String?)
    }
    
    /// Given json payload, It will construct array of IterableInAppMessage or ParseError
    /// The caller needs to make sure to consume errored out messages
    static func parse(payload: [AnyHashable : Any]) -> [IterableResult<IterableMessageProtocol, ParseError>] {
        return getInAppDicts(fromPayload: payload).map {
            let json = preProcess(payload: $0)
            return createMessageOrError(fromParseResult: parseInAppDetails(fromJson: json), andJson: json)
        }
    }
    
    /// Returns an array of Dictionaries holding inApp messages.
    private static func getInAppDicts(fromPayload payload: [AnyHashable : Any]) -> [[AnyHashable : Any]] {
        return payload[.ITBL_IN_APP_MESSAGE] as? [[AnyHashable : Any]] ?? []
    }
    
    // Change the in-app payload coming from the server to one that we expect it to be like
    // This is temporary until we fix the backend to do the right thing.
    // 1. Move 'inAppType', to top level from 'customPayload'
    // 2. Move 'type' to 'content' element.
    //!! Remove when we have backend support
    private static func preProcess(payload: [AnyHashable : Any]) -> [AnyHashable : Any] {
        var result = payload
        guard var customPayloadDict = payload[.ITBL_IN_APP_CUSTOM_PAYLOAD] as? [AnyHashable : Any] else {
            return result
        }
        
        moveValue(withKey: AnyHashable.ITBL_IN_APP_INAPP_TYPE, from: &customPayloadDict, to: &result)
        
        if var contentDict = payload[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] {
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

    /// Holds information about 'base' IterableMessage
    private struct InAppParseDetails {
        let inAppType: IterableInAppType
        let content: IterableContent
        let messageId: String
        let campaignId: String
        let expiresAt: Date?
        let customPayload: [AnyHashable : Any]?
    }
    
    private static func parseInAppDetails(fromJson json: [AnyHashable : Any]) -> IterableResult<InAppParseDetails, ParseError> {
        guard let messageId = json[.ITBL_KEY_MESSAGE_ID] as? String else {
            return .failure(.parseFailed(reason: "no messageId", messageId: nil))
        }
        
        let inAppType: IterableInAppType
        if let inAppTypeStr = json[.ITBL_IN_APP_INAPP_TYPE] as? String {
            inAppType = IterableInAppType.from(string: inAppTypeStr)
        } else {
            inAppType = .default
        }
        
        guard let contentDict = json[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(.parseFailed(reason: "no content in json payload", messageId: messageId))
        }
        
        let content: IterableContent
        switch (InAppContentParser.parse(contentDict: contentDict)) {
        case .success(let parsedContent):
            content = parsedContent
        case .failure(let reason):
            return .failure(.parseFailed(reason: reason, messageId: messageId))
        }
        
        let campaignId: String
        if let theCampaignId = json[.ITBL_KEY_CAMPAIGN_ID] as? String {
            campaignId = theCampaignId
        } else {
            ITBDebug("Could not find campaignId") // This is debug level because this happens a lot with proof inApps
            campaignId = ""
        }
        
        let customPayload = parseCustomPayload(fromPayload: json)
        
        let expiresAt = parseExpiresAt(dict: json)
        
        return .success(InAppParseDetails(
            inAppType: inAppType,
            content: content,
            messageId: messageId,
            campaignId: campaignId,
            expiresAt: expiresAt,
            customPayload: customPayload))
    }
    
    private static func createMessageOrError(fromParseResult parseResult: IterableResult<InAppParseDetails, ParseError>, andJson json: [AnyHashable : Any]) -> IterableResult<IterableMessageProtocol, ParseError> {
        switch parseResult{
        case .failure(let parseError):
            return .failure(parseError)
        case .success(let parseDetails):
            return .success(createMessage(fromParseDetails: parseDetails, AndJson: json))
        }
    }
    
    private static func createMessage(fromParseDetails details: InAppParseDetails, AndJson json: [AnyHashable : Any]) -> IterableMessageProtocol {
        switch details.inAppType {
        case .default:
            let trigger = parseTrigger(fromTriggerElement: json[.ITBL_IN_APP_TRIGGER] as? [AnyHashable : Any])
            return IterableInAppMessage(messageId: details.messageId,
                                        campaignId: details.campaignId,
                                        trigger: trigger,
                                        expiresAt: details.expiresAt,
                                        content: details.content,
                                        customPayload: details.customPayload)

        case .inbox:
            return IterableInboxMessage(messageId: details.messageId,
                                        campaignId: details.campaignId,
                                        expiresAt: details.expiresAt,
                                        content: details.content,
                                        customPayload: details.customPayload)
        }
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
}
