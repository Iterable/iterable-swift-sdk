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
    static func parse(payload: [AnyHashable : Any]) -> [IterableResult<IterableInAppMessage, ParseError>] {
        return getInAppDicts(fromPayload: payload).map {
            let oneJson = preProcessOneJson(fromJson: $0)
            return parseOneMessage(fromJson: oneJson)
        }
    }
    
    /// Returns an array of Dictionaries holding inApp messages.
    private static func getInAppDicts(fromPayload payload: [AnyHashable : Any]) -> [[AnyHashable : Any]] {
        return payload[.ITBL_IN_APP_MESSAGE] as? [[AnyHashable : Any]] ?? []
    }
    
    // Change the in-app payload coming from the server to one that we expect it to be like
    // This is temporary until we fix the backend to do the right thing.
    // 1. Move 'saveToInbox', to top level from 'customPayload'
    // 2. Move 'type' to 'content' element.
    //!! Remove when we have backend support
    private static func preProcessOneJson(fromJson json: [AnyHashable : Any]) -> [AnyHashable : Any] {
        var result = json
        guard var customPayloadDict = json[.ITBL_IN_APP_CUSTOM_PAYLOAD] as? [AnyHashable : Any] else {
            return result
        }
        
        moveValue(withSourceKey: AnyHashable.ITBL_IN_APP_SAVE_TO_INBOX, andDestinationKey: AnyHashable.ITBL_IN_APP_SAVE_TO_INBOX, from: &customPayloadDict, to: &result)
        
        if let triggerDict = customPayloadDict[.ITBL_IN_APP_TRIGGER] as? [AnyHashable : Any] {
            result[.ITBL_IN_APP_TRIGGER] = triggerDict
            customPayloadDict[.ITBL_IN_APP_TRIGGER] = nil
        }
        
        if let inboxMetadataDict = customPayloadDict[.ITBL_IN_APP_INBOX_METADATA] as? [AnyHashable : Any] {
            result[.ITBL_IN_APP_INBOX_METADATA] = inboxMetadataDict
            customPayloadDict[.ITBL_IN_APP_INBOX_METADATA] = nil
        }
        
        if var contentDict = json[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] {
            moveValue(withSourceKey: "contentType", andDestinationKey: AnyHashable.ITBL_IN_APP_CONTENT_TYPE, from: &customPayloadDict, to: &contentDict)
            result[.ITBL_IN_APP_CONTENT] = contentDict
        }
        
        result[.ITBL_IN_APP_CUSTOM_PAYLOAD] = customPayloadDict
        
        return result
    }
    
    private static func moveValue(withSourceKey sourceKey: String, andDestinationKey destinationKey: String, from source: inout [AnyHashable : Any], to destination: inout [AnyHashable : Any]) {
        guard destination[destinationKey] == nil else {
            // value exists in destination, so don't override
            return
        }
        
        if let value = source[sourceKey] {
            destination[destinationKey] = value
            source[sourceKey] = nil
        }
    }

    private static func parseOneMessage(fromJson json: [AnyHashable : Any]) -> IterableResult<IterableInAppMessage, ParseError> {
        guard let messageId = json[.ITBL_KEY_MESSAGE_ID] as? String else {
            return .failure(.parseFailed(reason: "no messageId", messageId: nil))
        }
        
        guard let contentDict = json[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(.parseFailed(reason: "no content in json payload", messageId: messageId))
        }
        
        let content: IterableInAppContent
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

        let saveToInbox = json[.ITBL_IN_APP_SAVE_TO_INBOX] as? Bool ?? false
        let inboxMetadata = parseInboxMetadata(fromPayload: json)
        let trigger = parseTrigger(fromTriggerElement: json[.ITBL_IN_APP_TRIGGER] as? [AnyHashable : Any])
        let customPayload = parseCustomPayload(fromPayload: json)
        let expiresAt = parseExpiresAt(dict: json)
        
        return .success(IterableInAppMessage(messageId: messageId,
                             campaignId: campaignId,
                             trigger: trigger,
                             expiresAt: expiresAt,
                             content: content,
                             saveToInbox: saveToInbox,
                             inboxMetadata: inboxMetadata,
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
    
    private static func parseInboxMetadata(fromPayload payload: [AnyHashable : Any]) -> IterableInboxMetadata? {
        guard let inboxMetadataDict = payload[.ITBL_IN_APP_INBOX_METADATA] as? [AnyHashable : Any] else {
            return nil
        }
        
        let title = inboxMetadataDict.getStringValue(key: .inboxTitle)
        let subTitle = inboxMetadataDict.getStringValue(key: .inboxSubtitle)
        let icon = inboxMetadataDict.getStringValue(key: .inboxIcon)
        
        return IterableInboxMetadata(title: title, subTitle: subTitle, icon: icon)
    }
}
