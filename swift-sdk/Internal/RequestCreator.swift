//
//  Created by Tapash Majumder on 5/16/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

// These are Iterable specific Request items.
// They don't have Api endpoint and request endpoint defined yet.
enum IterableRequest {
    case get(GetRequest)
    case post(PostRequest)
}

struct GetRequest {
    let path: String
    let args: [String: String]?
}

struct PostRequest {
    let path: String
    let args: [String: String]?
    let body: [AnyHashable: Any]?
}

// This is a stateless pure functional class
// This will create IterableRequest
// The API Endpoint and request endpoint is not defined yet
struct RequestCreator {
    let apiKey: String
    let auth: Auth
    let deviceMetadata: DeviceMetadata
    
    func createUpdateEmailRequest(newEmail: String) -> Result<IterableRequest, IterableError> {
        var body: [String: Any] = [JsonKey.newEmail.jsonKey: newEmail]
        
        if let email = auth.email {
            body[JsonKey.currentEmail.jsonKey] = email
        } else if let userId = auth.userId {
            body[JsonKey.currentUserId.jsonKey] = userId
        } else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        return .success(.post(createPostRequest(path: Const.Path.updateEmail, body: body)))
    }
    
    func createRegisterTokenRequest(hexToken: String,
                                    appName: String,
                                    deviceId: String,
                                    sdkVersion: String?,
                                    deviceAttributes: [String: String],
                                    pushServicePlatform: String,
                                    notificationsEnabled: Bool) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        let dataFields = DataFieldsHelper.createDataFields(sdkVersion: sdkVersion,
                                                           deviceId: deviceId,
                                                           device: UIDevice.current,
                                                           bundle: Bundle.main,
                                                           notificationsEnabled: notificationsEnabled,
                                                           deviceAttributes: deviceAttributes)
        
        let deviceDictionary: [String: Any] = [
            JsonKey.token.jsonKey: hexToken,
            JsonKey.platform.jsonKey: pushServicePlatform,
            JsonKey.applicationName.jsonKey: appName,
            JsonKey.dataFields.jsonKey: dataFields,
        ]
        
        var body = [AnyHashable: Any]()
        
        body[JsonKey.device.jsonKey] = deviceDictionary
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        if auth.email == nil, auth.userId != nil {
            body[JsonKey.preferUserId.jsonKey] = true
        }
        
        return .success(.post(createPostRequest(path: Const.Path.registerDeviceToken, body: body)))
    }
    
    func createUpdateUserRequest(dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body[JsonKey.dataFields.jsonKey] = dataFields
        body[JsonKey.mergeNestedObjects.jsonKey] = NSNumber(value: mergeNestedObjects)
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        if auth.email == nil, auth.userId != nil {
            body[JsonKey.preferUserId.jsonKey] = true
        }
        
        return .success(.post(createPostRequest(path: Const.Path.updateUser, body: body)))
    }
    
    func createTrackPurchaseRequest(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var itemsToSerialize = [[AnyHashable: Any]]()
        
        for item in items {
            itemsToSerialize.append(item.toDictionary())
        }
        
        var apiUserDict = [AnyHashable: Any]()
        
        apiUserDict.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        var body: [String: Any] = [JsonKey.Commerce.user: apiUserDict,
                                   JsonKey.Commerce.items: itemsToSerialize,
                                   JsonKey.Commerce.total: total]
        
        if let dataFields = dataFields {
            body[JsonKey.dataFields.jsonKey] = dataFields
        }
        
        return .success(.post(createPostRequest(path: Const.Path.trackPurchase, body: body)))
    }
    
    func createTrackPushOpenRequest(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        var reqDataFields = [AnyHashable: Any]()
        
        if let dataFields = dataFields {
            reqDataFields = dataFields
        }
        
        reqDataFields[JsonKey.appAlreadyRunning.jsonKey] = appAlreadyRunning
        body[JsonKey.dataFields.jsonKey] = reqDataFields
        
        if let keyValueForCurrentUser = keyValueForCurrentUser {
            body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        }
        
        body[JsonKey.campaignId.jsonKey] = campaignId
        
        if let templateId = templateId {
            body[JsonKey.templateId.jsonKey] = templateId
        }
        
        if let messageId = messageId {
            body.setValue(for: .messageId, value: messageId)
        }
        
        return .success(.post(createPostRequest(path: Const.Path.trackPushOpen, body: body)))
    }
    
    func createTrackEventRequest(_ eventName: String, dataFields: [AnyHashable: Any]?) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        body.setValue(for: .eventName, value: eventName)
        
        if let dataFields = dataFields {
            body[JsonKey.dataFields.jsonKey] = dataFields
        }
        
        return .success(.post(createPostRequest(path: Const.Path.trackEvent, body: body)))
    }
    
    func createUpdateSubscriptionsRequest(_ emailListIds: [NSNumber]? = nil,
                                          unsubscribedChannelIds: [NSNumber]? = nil,
                                          unsubscribedMessageTypeIds: [NSNumber]? = nil,
                                          subscribedMessageTypeIds: [NSNumber]? = nil,
                                          campaignId: NSNumber? = nil,
                                          templateId: NSNumber? = nil) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        if let emailListIds = emailListIds {
            body[JsonKey.emailListIds.jsonKey] = emailListIds
        }
        
        if let unsubscribedChannelIds = unsubscribedChannelIds {
            body[JsonKey.unsubscribedChannelIds.jsonKey] = unsubscribedChannelIds
        }
        
        if let unsubscribedMessageTypeIds = unsubscribedMessageTypeIds {
            body[JsonKey.unsubscribedMessageTypeIds.jsonKey] = unsubscribedMessageTypeIds
        }
        
        if let subscribedMessageTypeIds = subscribedMessageTypeIds {
            body[JsonKey.subscribedMessageTypeIds.jsonKey] = subscribedMessageTypeIds
        }
        
        if let campaignId = campaignId?.intValue {
            body[JsonKey.campaignId.jsonKey] = campaignId
        }
        
        if let templateId = templateId?.intValue {
            body[JsonKey.templateId.jsonKey] = templateId
        }
        
        return .success(.post(createPostRequest(path: Const.Path.updateSubscriptions, body: body)))
    }
    
    func createGetInAppMessagesRequest(_ count: NSNumber) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var args: [AnyHashable: Any] = [JsonKey.InApp.count: count.description,
                                        JsonKey.platform.jsonKey: JsonValue.iOS.jsonStringValue,
                                        JsonKey.InApp.sdkVersion: IterableAPI.sdkVersion]
        
        if let packageName = Bundle.main.appPackageName {
            args[JsonKey.InApp.packageName] = packageName
        }
        
        args.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        return .success(.get(createGetRequest(forPath: Const.Path.getInAppMessages, withArgs: args as! [String: String])))
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func createTrackInAppOpenRequest(_ messageId: String) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: messageId)
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        let inAppMessageContext = InAppMessageContext.from(messageId: messageId, deviceMetadata: deviceMetadata)
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: Const.Path.trackInAppOpen, body: body)))
    }
    
    func createTrackInAppOpenRequest(inAppMessageContext: InAppMessageContext) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: inAppMessageContext.messageId)
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        if let inboxSessionId = inAppMessageContext.inboxSessionId {
            body.setValue(for: .inboxSessionId, value: inboxSessionId)
        }
        
        return .success(.post(createPostRequest(path: Const.Path.trackInAppOpen, body: body)))
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func createTrackInAppClickRequest(_ messageId: String, clickedUrl: String) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: messageId)
        body.setValue(for: .clickedUrl, value: clickedUrl)
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        let inAppMessageContext = InAppMessageContext.from(messageId: messageId, deviceMetadata: deviceMetadata)
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: Const.Path.trackInAppClick, body: body)))
    }
    
    func createTrackInAppClickRequest(inAppMessageContext: InAppMessageContext, clickedUrl: String) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: inAppMessageContext.messageId)
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        body.setValue(for: .clickedUrl, value: clickedUrl)
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        if let inboxSessionId = inAppMessageContext.inboxSessionId {
            body.setValue(for: .inboxSessionId, value: inboxSessionId)
        }
        
        return .success(.post(createPostRequest(path: Const.Path.trackInAppClick, body: body)))
    }
    
    func createTrackInAppCloseRequest(inAppMessageContext: InAppMessageContext, source: InAppCloseSource?, clickedUrl: String?) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: inAppMessageContext.messageId)
        
        if let source = source {
            body.setValue(for: .closeAction, value: source)
        }
        
        if let clickedUrl = clickedUrl {
            body.setValue(for: .clickedUrl, value: clickedUrl)
        }
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        if let inboxSessionId = inAppMessageContext.inboxSessionId {
            body.setValue(for: .inboxSessionId, value: inboxSessionId)
        }
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        return .success(.post(createPostRequest(path: Const.Path.trackInAppClose, body: body)))
    }
    
    func createTrackInAppDeliveryRequest(inAppMessageContext: InAppMessageContext) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: inAppMessageContext.messageId)
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: Const.Path.trackInAppDelivery, body: body)))
    }
    
    func createInAppConsumeRequest(_ messageId: String) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: messageId)
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        return .success(.post(createPostRequest(path: Const.Path.inAppConsume, body: body)))
    }
    
    func createTrackInAppConsumeRequest(inAppMessageContext: InAppMessageContext, source: InAppDeleteSource?) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .messageId, value: inAppMessageContext.messageId)
        
        if let source = source {
            body.setValue(for: .deleteAction, value: source)
        }
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        if let inboxSessionId = inAppMessageContext.inboxSessionId {
            body.setValue(for: .inboxSessionId, value: inboxSessionId)
        }
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        return .success(.post(createPostRequest(path: Const.Path.inAppConsume, body: body)))
    }
    
    func createTrackInboxSessionRequest(inboxSession: IterableInboxSession) -> Result<IterableRequest, IterableError> {
        guard let keyValueForCurrentUser = keyValueForCurrentUser else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        guard let inboxSessionId = inboxSession.id else {
            return .failure(IterableError.general(description: "expecting session UUID"))
        }
        
        guard let sessionStartTime = inboxSession.sessionStartTime else {
            return .failure(IterableError.general(description: "expecting session start time"))
        }
        
        guard let sessionEndTime = inboxSession.sessionEndTime else {
            return .failure(IterableError.general(description: "expecting session end time"))
        }
        
        var body = [AnyHashable: Any]()
        
        body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
        
        body.setValue(for: .inboxSessionId, value: inboxSessionId)
        body.setValue(for: .inboxSessionStart, value: IterableUtil.int(fromDate: sessionStartTime))
        body.setValue(for: .inboxSessionEnd, value: IterableUtil.int(fromDate: sessionEndTime))
        body.setValue(for: .startTotalMessageCount, value: inboxSession.startTotalMessageCount)
        body.setValue(for: .endTotalMessageCount, value: inboxSession.endTotalMessageCount)
        body.setValue(for: .startUnreadMessageCount, value: inboxSession.startUnreadMessageCount)
        body.setValue(for: .endUnreadMessageCount, value: inboxSession.endUnreadMessageCount)
        body.setValue(for: .impressions, value: inboxSession.impressions.compactMap { $0.asDictionary() })
        
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: Const.Path.trackInboxSession, body: body)))
    }
    
    func createDisableDeviceRequest(forAllUsers allUsers: Bool, hexToken: String) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        
        body.setValue(for: .token, value: hexToken)
        
        if !allUsers {
            if let keyValueForCurrentUser = keyValueForCurrentUser {
                body.setValue(for: keyValueForCurrentUser.key, value: keyValueForCurrentUser.value)
            }
        }
        
        return .success(.post(createPostRequest(path: Const.Path.disableDevice, body: body)))
    }
    
    private func createPostRequest(path: String, body: [AnyHashable: Any]? = nil) -> PostRequest {
        return PostRequest(path: path,
                           args: [JsonKey.Header.apiKey: apiKey],
                           body: body)
    }
    
    private func createGetRequest(forPath path: String, withArgs args: [String: String]) -> GetRequest {
        return GetRequest(path: path,
                          args: args)
    }
    
    private var keyValueForCurrentUser: JsonKeyValueRepresentable? {
        switch auth.emailOrUserId {
        case let .email(email):
            return JsonKeyValue(key: JsonKey.email, value: email)
        case let .userId(userId):
            return JsonKeyValue(key: JsonKey.userId, value: userId)
        case .none:
            return nil
        }
    }
    
    private static func userInterfaceIdiomEnumToString(_ idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone:
            return JsonValue.DeviceIdiom.phone
        case .pad:
            return JsonValue.DeviceIdiom.pad
        case .tv:
            return JsonValue.DeviceIdiom.tv
        case .carPlay:
            return JsonValue.DeviceIdiom.carPlay
        default:
            return JsonValue.DeviceIdiom.unspecified
        }
    }
}
