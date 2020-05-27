//
//  Created by Tapash Majumder on 3/5/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

struct InAppMessageParser {
    enum ParseError: Error {
        case parseFailed(reason: String, messageId: String?)
    }
    
    /// Given json payload, It will construct array of IterableInAppMessage or ParseError
    /// The caller needs to make sure to consume errored out messages
    static func parse(payload: [AnyHashable: Any]) -> [Result<IterableInAppMessage, ParseError>] {
        return getInAppDicts(fromPayload: payload).map {
            let oneJson = preProcessOneJson(fromJson: $0)
            
            return parseOneMessage(fromJson: oneJson)
        }
    }
    
    /// Returns an array of Dictionaries holding in-app messages.
    private static func getInAppDicts(fromPayload payload: [AnyHashable: Any]) -> [[AnyHashable: Any]] {
        return payload[JsonKey.InApp.inAppMessages] as? [[AnyHashable: Any]] ?? []
    }
    
    // Change the in-app payload coming from the server to one that we expect it to be like
    // This is temporary until we fix the backend to do the right thing.
    // 1. Move 'saveToInbox', to top level from 'customPayload'
    // 2. Move 'type' to 'content' element.
    //! ! Remove when we have backend support
    private static func preProcessOneJson(fromJson json: [AnyHashable: Any]) -> [AnyHashable: Any] {
        var result = json
        
        guard var customPayloadDict = json[JsonKey.InApp.customPayload] as? [AnyHashable: Any] else {
            return result
        }
        
        moveValue(withSourceKey: JsonKey.saveToInbox.jsonKey,
                  andDestinationKey: JsonKey.saveToInbox.jsonKey,
                  from: &customPayloadDict,
                  to: &result)
        
        if let triggerDict = customPayloadDict[JsonKey.InApp.trigger] as? [AnyHashable: Any] {
            result[JsonKey.InApp.trigger] = triggerDict
            customPayloadDict[JsonKey.InApp.trigger] = nil
        }
        
        if let inboxMetadataDict = customPayloadDict[JsonKey.inboxMetadata.jsonKey] as? [AnyHashable: Any] {
            result[JsonKey.inboxMetadata.jsonKey] = inboxMetadataDict
            customPayloadDict[JsonKey.inboxMetadata.jsonKey] = nil
        }
        
        if var contentDict = json[JsonKey.InApp.content] as? [AnyHashable: Any] {
            moveValue(withSourceKey: JsonKey.InApp.contentType, andDestinationKey: JsonKey.InApp.type, from: &customPayloadDict, to: &contentDict)
            result[JsonKey.InApp.content] = contentDict
        }
        
        result[JsonKey.InApp.customPayload] = customPayloadDict
        
        return result
    }
    
    private static func moveValue(withSourceKey sourceKey: String,
                                  andDestinationKey destinationKey: String,
                                  from source: inout [AnyHashable: Any],
                                  to destination: inout [AnyHashable: Any]) {
        guard destination[destinationKey] == nil else {
            // value exists in destination, so don't override
            return
        }
        
        if let value = source[sourceKey] {
            destination[destinationKey] = value
            source[sourceKey] = nil
        }
    }
    
    private static func parseOneMessage(fromJson json: [AnyHashable: Any]) -> Result<IterableInAppMessage, ParseError> {
        guard let messageId = json[JsonKey.messageId.jsonKey] as? String else {
            return .failure(.parseFailed(reason: "no messageId", messageId: nil))
        }
        
        guard let contentDict = json[JsonKey.InApp.content] as? [AnyHashable: Any] else {
            return .failure(.parseFailed(reason: "no content in json payload", messageId: messageId))
        }
        
        let content: IterableInAppContent
        
        switch InAppContentParser.parse(contentDict: contentDict) {
        case let .success(parsedContent):
            content = parsedContent
        case let .failure(reason):
            return .failure(.parseFailed(reason: reason, messageId: messageId))
        }
        
        let campaignId = json[JsonKey.campaignId.jsonKey] as? NSNumber
        
        let saveToInbox = json[JsonKey.saveToInbox.jsonKey] as? Bool ?? false
        let inboxMetadata = parseInboxMetadata(fromPayload: json)
        let trigger = parseTrigger(fromTriggerElement: json[JsonKey.InApp.trigger] as? [AnyHashable: Any])
        let customPayload = parseCustomPayload(fromPayload: json)
        let createdAt = parseTime(withKey: .inboxCreatedAt, fromJson: json)
        let expiresAt = parseTime(withKey: .inboxExpiresAt, fromJson: json)
        let read = json[JsonKey.read.jsonKey] as? Bool ?? false
        
        return .success(IterableInAppMessage(messageId: messageId,
                                             campaignId: campaignId,
                                             trigger: trigger,
                                             createdAt: createdAt,
                                             expiresAt: expiresAt,
                                             content: content,
                                             saveToInbox: saveToInbox,
                                             inboxMetadata: inboxMetadata,
                                             customPayload: customPayload,
                                             read: read))
    }
    
    private static func parseTime(withKey key: JsonKey, fromJson json: [AnyHashable: Any]) -> Date? {
        return json.getIntValue(for: key).map(IterableUtil.date(fromInt:))
    }
    
    private static func parseTrigger(fromTriggerElement element: [AnyHashable: Any]?) -> IterableInAppTrigger {
        guard let element = element else {
            return .defaultTrigger
        }
        
        return IterableInAppTrigger(dict: element)
    }
    
    private static func parseCustomPayload(fromPayload payload: [AnyHashable: Any]) -> [AnyHashable: Any]? {
        return payload[JsonKey.InApp.customPayload] as? [AnyHashable: Any]
    }
    
    private static func parseInboxMetadata(fromPayload payload: [AnyHashable: Any]) -> IterableInboxMetadata? {
        guard let inboxMetadataDict = payload[JsonKey.inboxMetadata.jsonKey] as? [AnyHashable: Any] else {
            return nil
        }
        
        let title = inboxMetadataDict.getStringValue(for: .inboxTitle)
        let subtitle = inboxMetadataDict.getStringValue(for: .inboxSubtitle)
        let icon = inboxMetadataDict.getStringValue(for: .inboxIcon)
        
        return IterableInboxMetadata(title: title, subtitle: subtitle, icon: icon)
    }
}
