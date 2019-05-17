//
//
//  Created by Tapash Majumder on 5/16/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

protocol ApiClientProtocol {
    @discardableResult func track(event: String, dataFields: [AnyHashable : Any]?) -> Future<SendRequestValue, SendRequestError>
}

extension ApiClientProtocol {
    func track(event: String) -> Future<SendRequestValue, SendRequestError> {
        return track(event: event, dataFields: nil)
    }
}

struct Auth {
    let userId: String?
    let email: String?
}

enum IterableRequest {
    case get(GetRequest)
    case post(PostRequest)
}

struct GetRequest {
    let path: String
    let args: [String : String]?
}

struct PostRequest {
    let path: String
    let args: [String: String]?
    let body: [AnyHashable : Any]?
}

struct ApiClient {
    let apiKey: String
    let auth: Auth
    let endPoint: String
    let networkSession: NetworkSessionProtocol

    func register(hexToken: String,
                  appName: String,
                  deviceId: String,
                  sdkVersion: String?,
                  pushServicePlatform: PushServicePlatform,
                  notificationsEnabled: Bool) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createReqisterTokenRequest(hexToken: hexToken,
                                                                      appName: appName,
                                                                      deviceId: deviceId,
                                                                      sdkVersion: sdkVersion,
                                                                      pushServicePlatform: pushServicePlatform,
                                                                      notificationsEnabled: notificationsEnabled))
    }
    
    func updateUser(_ dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createUpdateUserRequest(dataFields: dataFields, mergeNestedObjects: mergeNestedObjects))
    }
    
    func updateEmail(newEmail: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createUpdateEmailRequest(newEmail: newEmail))
    }
    
    func track(purchase total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createTrackPurchaseRequest(total, items: items, dataFields: dataFields))
    }
    
    func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createTrackPushOpenRequest(campaignId,
                                                                      templateId: templateId,
                                                                      messageId: messageId,
                                                                      appAlreadyRunning: appAlreadyRunning,
                                                                      dataFields: dataFields))
    }
    
    func track(event eventName: String, dataFields: [AnyHashable : Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createTrackEventRequest(eventName, dataFields: dataFields))
    }

    func updateSubscriptions(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createUpdateSubscriptionsRequest(emailListIds, unsubscribedChannelIds: unsubscribedChannelIds, unsubscribedMessageTypeIds: unsubscribedMessageTypeIds))
    }

    func createUpdateEmailRequest(newEmail: String) -> Result<IterableRequest, IterableError> {
        var body: [String : Any] = [
            AnyHashable.ITBL_KEY_NEW_EMAIL: newEmail
        ]
        
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
    
    func createReqisterTokenRequest(hexToken: String,
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
        let pushServicePlatformString = ApiClient.pushServicePlatformToString(pushServicePlatform)
        
        var dataFields: [String : Any] = [
            .ITBL_DEVICE_LOCALIZED_MODEL: device.localizedModel,
            .ITBL_DEVICE_USER_INTERFACE: ApiClient.userInterfaceIdiomEnumToString(device.userInterfaceIdiom),
            .ITBL_DEVICE_SYSTEM_NAME: device.systemName,
            .ITBL_DEVICE_SYSTEM_VERSION: device.systemVersion,
            .ITBL_DEVICE_MODEL: device.model
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
        
        let deviceDictionary: [String : Any] = [
            AnyHashable.ITBL_KEY_TOKEN: hexToken,
            AnyHashable.ITBL_KEY_PLATFORM: pushServicePlatformString,
            AnyHashable.ITBL_KEY_APPLICATION_NAME: appName,
            AnyHashable.ITBL_KEY_DATA_FIELDS: dataFields
        ]
        
        var body = [AnyHashable : Any]()
        body[.ITBL_KEY_DEVICE] = deviceDictionary
        addEmailOrUserId(dict: &body)
        
        if auth.email == nil && auth.userId != nil {
            body[.ITBL_KEY_PREFER_USER_ID] = true
        }
        return .success(.post(createPostRequest(path: .ITBL_PATH_REGISTER_DEVICE_TOKEN, body: body)))
    }

    
    func createUpdateUserRequest(dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable: Any]()
        body[.ITBL_KEY_DATA_FIELDS] = dataFields
        body[.ITBL_KEY_MERGE_NESTED] = NSNumber(value: mergeNestedObjects)
        addEmailOrUserId(dict: &body)
        return .success(.post(createPostRequest(path: .ITBL_PATH_UPDATE_USER, body: body)))
    }
    
    func createTrackPurchaseRequest(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?) -> Result<IterableRequest, IterableError> {
        guard auth.email != nil || auth.userId != nil else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var itemsToSerialize = [[AnyHashable : Any]]()
        for item in items {
            itemsToSerialize.append(item.toDictionary())
        }
        
        var apiUserDict = [AnyHashable : Any]()
        addEmailOrUserId(dict: &apiUserDict)
        
        let body : [String : Any]
        if let dataFields = dataFields {
            body = [
                AnyHashable.ITBL_KEY_USER: apiUserDict,
                AnyHashable.ITBL_KEY_ITEMS: itemsToSerialize,
                AnyHashable.ITBL_KEY_TOTAL: total,
                AnyHashable.ITBL_KEY_DATA_FIELDS: dataFields
            ]
        } else {
            body = [
                AnyHashable.ITBL_KEY_USER: apiUserDict,
                AnyHashable.ITBL_KEY_ITEMS: itemsToSerialize,
                AnyHashable.ITBL_KEY_TOTAL: total,
            ]
        }

        return .success(.post(createPostRequest(path: .ITBL_PATH_COMMERCE_TRACK_PURCHASE, body: body)))
    }
    
    func createTrackPushOpenRequest(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable : Any]()
        
        var reqDataFields: [AnyHashable : Any]
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

    func createTrackEventRequest(_ eventName: String, dataFields: [AnyHashable : Any]?) -> Result<IterableRequest, IterableError> {
        guard auth.email != nil || auth.userId != nil else {
            ITBError("Both email and userId are nil")
            return .failure(IterableError.general(description: "Both email and userId are nil"))
        }
        
        var body = [AnyHashable : Any]()
        addEmailOrUserId(dict: &body)
        body[.ITBL_KEY_EVENT_NAME] = eventName
        if let dataFields = dataFields {
            body[.ITBL_KEY_DATA_FIELDS] = dataFields
        }

        return .success(.post(createPostRequest(path: .ITBL_PATH_TRACK, body: body)))
    }

    func createUpdateSubscriptionsRequest(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) -> Result<IterableRequest, IterableError> {
        var body = [AnyHashable : Any]()
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

    func convertToURLRequest(iterableRequest: IterableRequest) -> URLRequest? {
        switch (iterableRequest) {
        case .get(let getRequest):
            return IterableRequestUtil.createGetRequest(forApiEndPoint: endPoint, path: getRequest.path, args: getRequest.args)
        case .post(let postRequest):
            return IterableRequestUtil.createPostRequest(forApiEndPoint: endPoint, path: postRequest.path, args: postRequest.args, body: postRequest.body)
        }
    }
    
    fileprivate func send(iterableRequestResult result: Result<IterableRequest, IterableError>) -> Future<SendRequestValue, SendRequestError> {
        switch result {
        case .success(let iterableRequest):
            return send(iterableRequest: iterableRequest)
        case .failure(let iterableError):
            return SendRequestError.createErroredFuture(reason: iterableError.localizedDescription)
        }
    }
    
    private func send(iterableRequest: IterableRequest) -> Future<SendRequestValue, SendRequestError> {
        guard let urlRequest = convertToURLRequest(iterableRequest: iterableRequest) else {
            return SendRequestError.createErroredFuture()
        }
        
        return NetworkHelper.sendRequest(urlRequest, usingSession: networkSession)
    }
    
    private func createPostRequest(path: String, body: [AnyHashable : Any]? = nil) -> PostRequest {
        return PostRequest(path: path,
                           args: [AnyHashable.ITBL_KEY_API_KEY : apiKey],
                           body: body)
    }

    private func addEmailOrUserId(dict: inout [AnyHashable : Any], mustExist: Bool = true) {
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




