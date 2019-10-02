//
//
//  Created by Tapash Majumder on 5/16/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

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
        var body: [String: Any] = [AnyHashable.ITBL_KEY_NEW_EMAIL: newEmail]
        
        if let email = auth.email {
            body[AnyHashable.ITBL_KEY_CURRENT_EMAIL] = email
        } else if let userId = auth.userId {
            body[AnyHashable.ITBL_KEY_CURRENT_USER_ID] = userId
        } else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_UPDATE_EMAIL, body: body)))
    }
    
    func createRegisterTokenRequest(hexToken: String,
                                    appName: String,
                                    deviceId: String,
                                    sdkVersion: String?,
                                    pushServicePlatform: PushServicePlatform,
                                    notificationsEnabled: Bool) -> Result<IterableRequest, IterableError> {
        guard auth.email != nil || auth.userId != nil else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        let device = UIDevice.current
        let pushServicePlatformString = RequestCreator.pushServicePlatformToString(pushServicePlatform)
        
        var dataFields: [String: Any] = [
            .ITBL_DEVICE_LOCALIZED_MODEL: device.localizedModel,
            .ITBL_DEVICE_USER_INTERFACE: RequestCreator.userInterfaceIdiomEnumToString(device.userInterfaceIdiom),
            .ITBL_DEVICE_SYSTEM_NAME: device.systemName,
            .ITBL_DEVICE_SYSTEM_VERSION: device.systemVersion,
            .ITBL_DEVICE_MODEL: device.model,
        ]
        
        if let identifierForVendor = device.identifierForVendor?.uuidString {
            dataFields[.ITBL_DEVICE_ID_VENDOR] = identifierForVendor
        }
        
        dataFields[.ITBL_DEVICE_DEVICE_ID] = deviceId
        
        if let sdkVersion = sdkVersion {
            dataFields[.ITBL_DEVICE_ITERABLE_SDK_VERSION] = sdkVersion
        }
        
        if let appPackageName = Bundle.main.appPackageName {
            dataFields[.ITBL_DEVICE_APP_PACKAGE_NAME] = appPackageName
        }
        
        if let appVersion = Bundle.main.appVersion {
            dataFields[.ITBL_DEVICE_APP_VERSION] = appVersion
        }
        
        if let appBuild = Bundle.main.appBuild {
            dataFields[.ITBL_DEVICE_APP_BUILD] = appBuild
        }
        
        dataFields[.ITBL_DEVICE_NOTIFICATIONS_ENABLED] = notificationsEnabled
        
        let deviceDictionary: [String: Any] = [
            AnyHashable.ITBL_KEY_TOKEN: hexToken,
            AnyHashable.ITBL_KEY_PLATFORM: pushServicePlatformString,
            AnyHashable.ITBL_KEY_APPLICATION_NAME: appName,
            AnyHashable.ITBL_KEY_DATA_FIELDS: dataFields,
        ]
        
        var body = [AnyHashable: Any]()
        body[.ITBL_KEY_DEVICE] = deviceDictionary
        addEmailOrUserId(dict: &body)
        
        if auth.email == nil, auth.userId != nil {
            body[.ITBL_KEY_PREFER_USER_ID] = true
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_REGISTER_DEVICE_TOKEN, body: body)))
    }
    
    func createUpdateUserRequest(dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        body[.ITBL_KEY_DATA_FIELDS] = dataFields
        body[.ITBL_KEY_MERGE_NESTED] = NSNumber(value: mergeNestedObjects)
        addEmailOrUserId(dict: &body)
        
        if auth.email == nil, auth.userId != nil {
            body[.ITBL_KEY_PREFER_USER_ID] = true
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_UPDATE_USER, body: body)))
    }
    
    func createTrackPurchaseRequest(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) -> Result<IterableRequest, IterableError> {
        guard auth.email != nil || auth.userId != nil else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var itemsToSerialize = [[AnyHashable: Any]]()
        for item in items {
            itemsToSerialize.append(item.toDictionary())
        }
        
        var apiUserDict = [AnyHashable: Any]()
        addEmailOrUserId(dict: &apiUserDict)
        
        let body: [String: Any]
        if let dataFields = dataFields {
            body = [AnyHashable.ITBL_KEY_USER: apiUserDict,
                    AnyHashable.ITBL_KEY_ITEMS: itemsToSerialize,
                    AnyHashable.ITBL_KEY_TOTAL: total,
                    AnyHashable.ITBL_KEY_DATA_FIELDS: dataFields]
        } else {
            body = [AnyHashable.ITBL_KEY_USER: apiUserDict,
                    AnyHashable.ITBL_KEY_ITEMS: itemsToSerialize,
                    AnyHashable.ITBL_KEY_TOTAL: total]
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_COMMERCE_TRACK_PURCHASE, body: body)))
    }
    
    func createTrackPushOpenRequest(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        
        var reqDataFields: [AnyHashable: Any]
        if let dataFields = dataFields {
            reqDataFields = dataFields
        } else {
            reqDataFields = [:]
        }
        
        reqDataFields["appAlreadyRunning"] = appAlreadyRunning
        body[.ITBL_KEY_DATA_FIELDS] = reqDataFields
        
        addEmailOrUserId(dict: &body, mustExist: false)
        
        body[.ITBL_KEY_CAMPAIGN_ID] = campaignId
        
        if let templateId = templateId {
            body[.ITBL_KEY_TEMPLATE_ID] = templateId
        }
        
        if let messageId = messageId {
            body[.ITBL_KEY_MESSAGE_ID] = messageId
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_PUSH_OPEN, body: body)))
    }
    
    func createTrackEventRequest(_ eventName: String, dataFields: [AnyHashable: Any]?) -> Result<IterableRequest, IterableError> {
        guard auth.email != nil || auth.userId != nil else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable: Any]()
        addEmailOrUserId(dict: &body)
        body[.ITBL_KEY_EVENT_NAME] = eventName
        
        if let dataFields = dataFields {
            body[.ITBL_KEY_DATA_FIELDS] = dataFields
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK, body: body)))
    }
    
    func createUpdateSubscriptionsRequest(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        addEmailOrUserId(dict: &body)
        
        if let emailListIds = emailListIds {
            body[.ITBL_KEY_EMAIL_LIST_IDS] = emailListIds
        }
        
        if let unsubscribedChannelIds = unsubscribedChannelIds {
            body[.ITBL_KEY_UNSUB_CHANNEL] = unsubscribedChannelIds
        }
        
        if let unsubscribedMessageTypeIds = unsubscribedMessageTypeIds {
            body[.ITBL_KEY_UNSUB_MESSAGE] = unsubscribedMessageTypeIds
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_UPDATE_SUBSCRIPTIONS, body: body)))
    }
    
    func createGetInAppMessagesRequest(_ count: NSNumber) -> Result<IterableRequest, IterableError> {
        guard auth.email != nil || auth.userId != nil else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var args: [AnyHashable: Any] = [AnyHashable.ITBL_KEY_COUNT: count.description,
                                        AnyHashable.ITBL_KEY_PLATFORM: String.ITBL_PLATFORM_IOS,
                                        AnyHashable.ITBL_KEY_SDK_VERSION: IterableAPI.sdkVersion]
        
        if let packageName = Bundle.main.appPackageName {
            args[AnyHashable.ITBL_KEY_PACKAGE_NAME] = packageName
        }
        
        addEmailOrUserId(dict: &args)
        
        return .success(.get(createGetRequest(forPath: .ITBL_PATH_GET_INAPP_MESSAGES, withArgs: args as! [String: String])))
    }
    
    func createTrackInAppOpenRequest(_ messageId: String) -> Result<IterableRequest, IterableError> {
        var body: [AnyHashable: Any] = [:]
        
        body[.ITBL_KEY_MESSAGE_ID] = messageId
        
        addEmailOrUserId(dict: &body)
        
        let inAppMessageContext = InAppMessageContext.from(messageId: messageId, deviceMetadata: deviceMetadata)
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_INAPP_OPEN, body: body)))
    }
    
    func createTrackInAppOpenRequest(inAppMessageContext: InAppMessageContext) -> Result<IterableRequest, IterableError> {
        var body: [AnyHashable: Any] = [:]
        
        body[.ITBL_KEY_MESSAGE_ID] = inAppMessageContext.messageId
        
        addEmailOrUserId(dict: &body)
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_INAPP_OPEN, body: body)))
    }
    
    func createTrackInAppClickRequest(_ messageId: String, clickedUrl: String) -> Result<IterableRequest, IterableError> {
        var body: [AnyHashable: Any] = [:]
        
        body[.ITBL_KEY_MESSAGE_ID] = messageId
        body[.ITBL_IN_APP_CLICKED_URL] = clickedUrl
        
        addEmailOrUserId(dict: &body)
        
        let inAppMessageContext = InAppMessageContext.from(messageId: messageId, deviceMetadata: deviceMetadata)
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_INAPP_CLICK, body: body)))
    }
    
    func createTrackInAppClickRequest(inAppMessageContext: InAppMessageContext, clickedUrl: String) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        
        body[.ITBL_KEY_MESSAGE_ID] = inAppMessageContext.messageId
        
        body.setValue(for: .clickedUrl, value: clickedUrl)
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        addEmailOrUserId(dict: &body)
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_INAPP_CLICK, body: body)))
    }
    
    func createTrackInAppCloseRequest(inAppMessageContext: InAppMessageContext, source: InAppCloseSource, clickedUrl: String?) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        
        body[.ITBL_KEY_MESSAGE_ID] = inAppMessageContext.messageId
        
        body.setValue(for: .closeAction, value: source)
        
        if let clickedUrl = clickedUrl {
            body.setValue(for: .clickedUrl, value: clickedUrl)
        }
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        addEmailOrUserId(dict: &body)
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_INAPP_CLOSE, body: body)))
    }
    
    func createTrackInAppDeliveryRequest(inAppMessageContext: InAppMessageContext) -> Result<IterableRequest, IterableError> {
        var body: [AnyHashable: Any] = [:]
        
        body[.ITBL_KEY_MESSAGE_ID] = inAppMessageContext.messageId
        
        addEmailOrUserId(dict: &body)
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_INAPP_DELIVERY, body: body)))
    }
    
    func createInAppConsumeRequest(_ messageId: String) -> Result<IterableRequest, IterableError> {
        var body: [AnyHashable: Any] = [.ITBL_KEY_MESSAGE_ID: messageId]
        
        addEmailOrUserId(dict: &body)
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_INAPP_CONSUME, body: body)))
    }
    
    func createTrackInAppConsumeRequest(inAppMessageContext: InAppMessageContext, source: InAppDeleteSource) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        
        body[.ITBL_KEY_MESSAGE_ID] = inAppMessageContext.messageId
        
        body.setValue(for: .deleteAction, value: source)
        
        body.setValue(for: .inAppMessageContext, value: inAppMessageContext.toMessageContextDictionary())
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        addEmailOrUserId(dict: &body)
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_INAPP_CONSUME, body: body)))
    }
    
    func createTrackInboxSessionRequest(inboxSession: IterableInboxSession) -> Result<IterableRequest, IterableError> {
        guard let sessionStartTime = inboxSession.sessionStartTime else {
            return .failure(IterableError.general(description: "expecting session start time"))
        }
        guard let sessionEndTime = inboxSession.sessionEndTime else {
            return .failure(IterableError.general(description: "expecting session end time"))
        }
        
        var body = [AnyHashable: Any]()
        
        addEmailOrUserId(dict: &body)
        
        body.setValue(for: .inboxSessionStart, value: IterableUtil.int(fromDate: sessionStartTime))
        body.setValue(for: .inboxSessionEnd, value: IterableUtil.int(fromDate: sessionEndTime))
        body.setValue(for: .startTotalMessageCount, value: inboxSession.startTotalMessageCount)
        body.setValue(for: .endTotalMessageCount, value: inboxSession.endTotalMessageCount)
        body.setValue(for: .startUnreadMessageCount, value: inboxSession.startUnreadMessageCount)
        body.setValue(for: .endUnreadMessageCount, value: inboxSession.endUnreadMessageCount)
        body.setValue(for: .impressions, value: inboxSession.impressions.compactMap { $0.asDictionary() })
        
        body.setValue(for: .deviceInfo, value: deviceMetadata.asDictionary())
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK_INBOX_SESSION, body: body)))
    }
    
    func createDisableDeviceRequest(forAllUsers allUsers: Bool, hexToken: String) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        body[.ITBL_KEY_TOKEN] = hexToken
        
        if !allUsers {
            addEmailOrUserId(dict: &body, mustExist: false)
        }
        
        return .success(.post(createPostRequest(path: .ITBL_PATH_DISABLE_DEVICE, body: body)))
    }
    
    private func createPostRequest(path: String, body: [AnyHashable: Any]? = nil) -> PostRequest {
        return PostRequest(path: path,
                           args: [AnyHashable.ITBL_HEADER_API_KEY: apiKey],
                           body: body)
    }
    
    private func createGetRequest(forPath path: String, withArgs args: [String: String]) -> GetRequest {
        return GetRequest(path: path,
                          args: args)
    }
    
    private func addEmailOrUserId(dict: inout [AnyHashable: Any], mustExist: Bool = true) {
        if let email = auth.email {
            dict[.ITBL_KEY_EMAIL] = email
        } else if let userId = auth.userId {
            dict[.ITBL_KEY_USER_ID] = userId
        } else if mustExist {
            assertionFailure("Either email or userId should be set")
        }
    }
    
    private static func pushServicePlatformToString(_ pushServicePlatform: PushServicePlatform) -> String {
        switch pushServicePlatform {
        case .production:
            return .ITBL_KEY_APNS
        case .sandbox:
            return .ITBL_KEY_APNS_SANDBOX
        case .auto:
            return IterableAPNSUtil.isSandboxAPNS() ? .ITBL_KEY_APNS_SANDBOX : .ITBL_KEY_APNS
        }
    }
    
    private static func userInterfaceIdiomEnumToString(_ idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone:
            return .ITBL_KEY_PHONE
        case .pad:
            return .ITBL_KEY_PAD
        default:
            return .ITBL_KEY_UNSPECIFIED
        }
    }
}
