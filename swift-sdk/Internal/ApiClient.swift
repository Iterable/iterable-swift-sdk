//
//
//  Created by Tapash Majumder on 5/16/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

/// Responsible for sending request to server
protocol ApiClientProtocol: AnyObject {
    func register(hexToken: String,
                  appName: String,
                  deviceId: String,
                  sdkVersion: String?,
                  pushServicePlatform: PushServicePlatform,
                  notificationsEnabled: Bool) -> Future<SendRequestValue, SendRequestError>
    
    func updateUser(_ dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Future<SendRequestValue, SendRequestError>
    
    func updateEmail(newEmail: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(purchase total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError>
    
    func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError>
    
    func track(event eventName: String, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError>
    
    func updateSubscriptions(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) -> Future<SendRequestValue, SendRequestError>
    
    func getInAppMessages(_ count: NSNumber) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppOpen messageId: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppOpen inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppClick messageId: String, clickedUrl: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppClick inAppMessageContext: InAppMessageContext, clickedUrl: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppClose inAppMessageContext: InAppMessageContext, source: InAppCloseSource, clickedUrl: String?) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppDelivery inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError>
    
    @discardableResult func inAppConsume(messageId: String) -> Future<SendRequestValue, SendRequestError>
    
    @discardableResult func inAppConsume(inAppMessageContext: InAppMessageContext, source: InAppDeleteSource) -> Future<SendRequestValue, SendRequestError>
    
    func track(inboxSession: IterableInboxSession) -> Future<SendRequestValue, SendRequestError>
    
    func disableDevice(forAllUsers allUsers: Bool, hexToken: String) -> Future<SendRequestValue, SendRequestError>
}

struct Auth {
    let userId: String?
    let email: String?
}

protocol AuthProvider: AnyObject {
    var auth: Auth { get }
}

class ApiClient: ApiClientProtocol {
    init(apiKey: String, authProvider: AuthProvider, endPoint: String, networkSession: NetworkSessionProtocol, deviceMetadata: DeviceMetadata) {
        self.apiKey = apiKey
        self.authProvider = authProvider
        self.endPoint = endPoint
        self.networkSession = networkSession
        self.deviceMetadata = deviceMetadata
    }
    
    func register(hexToken: String,
                  appName: String,
                  deviceId: String,
                  sdkVersion: String?,
                  pushServicePlatform: PushServicePlatform,
                  notificationsEnabled: Bool) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createRegisterTokenRequest(hexToken: hexToken,
                                                                                             appName: appName,
                                                                                             deviceId: deviceId,
                                                                                             sdkVersion: sdkVersion,
                                                                                             pushServicePlatform: pushServicePlatform,
                                                                                             notificationsEnabled: notificationsEnabled))
    }
    
    func updateUser(_ dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createUpdateUserRequest(dataFields: dataFields, mergeNestedObjects: mergeNestedObjects))
    }
    
    func updateEmail(newEmail: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createUpdateEmailRequest(newEmail: newEmail))
    }
    
    func track(purchase total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackPurchaseRequest(total, items: items, dataFields: dataFields))
    }
    
    func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackPushOpenRequest(campaignId,
                                                                                             templateId: templateId,
                                                                                             messageId: messageId,
                                                                                             appAlreadyRunning: appAlreadyRunning,
                                                                                             dataFields: dataFields))
    }
    
    func track(event eventName: String, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackEventRequest(eventName, dataFields: dataFields))
    }
    
    func updateSubscriptions(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createUpdateSubscriptionsRequest(emailListIds, unsubscribedChannelIds: unsubscribedChannelIds, unsubscribedMessageTypeIds: unsubscribedMessageTypeIds))
    }
    
    func getInAppMessages(_ count: NSNumber) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createGetInAppMessagesRequest(count))
    }
    
    func track(inAppOpen messageId: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppOpenRequest(messageId))
    }
    
    func track(inAppOpen inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppOpenRequest(inAppMessageContext: inAppMessageContext))
    }
    
    func track(inAppClick messageId: String, clickedUrl: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppClickRequest(messageId, clickedUrl: clickedUrl))
    }
    
    func track(inAppClick inAppMessageContext: InAppMessageContext, clickedUrl: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppClickRequest(inAppMessageContext: inAppMessageContext, clickedUrl: clickedUrl))
    }
    
    func track(inAppClose inAppMessageContext: InAppMessageContext, source: InAppCloseSource, clickedUrl: String?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppCloseRequest(inAppMessageContext: inAppMessageContext, source: source, clickedUrl: clickedUrl))
    }
    
    func track(inAppDelivery inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppDeliveryRequest(inAppMessageContext: inAppMessageContext))
    }
    
    func track(inboxSession: IterableInboxSession) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInboxSessionRequest(inboxSession: inboxSession))
    }
    
    func inAppConsume(messageId: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createInAppConsumeRequest(messageId))
    }
    
    func inAppConsume(inAppMessageContext: InAppMessageContext, source: InAppDeleteSource) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppConsumeRequest(inAppMessageContext: inAppMessageContext, source: source))
    }
    
    func disableDevice(forAllUsers allUsers: Bool, hexToken: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createDisableDeviceRequest(forAllUsers: allUsers, hexToken: hexToken))
    }
    
    func convertToURLRequest(iterableRequest: IterableRequest) -> URLRequest? {
        switch iterableRequest {
        case let .get(getRequest):
            return IterableRequestUtil.createGetRequest(forApiEndPoint: endPoint, path: getRequest.path, headers: createIterableHeaders(), args: getRequest.args)
        case let .post(postRequest):
            return IterableRequestUtil.createPostRequest(forApiEndPoint: endPoint, path: postRequest.path, headers: createIterableHeaders(), args: postRequest.args, body: postRequest.body)
        }
    }
    
    func send(iterableRequestResult result: Result<IterableRequest, IterableError>) -> Future<SendRequestValue, SendRequestError> {
        switch result {
        case let .success(iterableRequest):
            return send(iterableRequest: iterableRequest)
        case let .failure(iterableError):
            return SendRequestError.createErroredFuture(reason: iterableError.localizedDescription)
        }
    }
    
    func send(iterableRequest: IterableRequest) -> Future<SendRequestValue, SendRequestError> {
        guard let urlRequest = convertToURLRequest(iterableRequest: iterableRequest) else {
            return SendRequestError.createErroredFuture()
        }
        
        return NetworkHelper.sendRequest(urlRequest, usingSession: networkSession)
    }
    
    private func createRequestCreator() -> RequestCreator {
        guard let authProvider = authProvider else {
            fatalError("authProvider is missing")
        }
        
        return RequestCreator(apiKey: apiKey, auth: authProvider.auth, deviceMetadata: deviceMetadata)
    }
    
    func createIterableHeaders() -> [String: String] {
        return [
            "Content-Type": "application/json",
            AnyHashable.ITBL_HEADER_SDK_PLATFORM: .ITBL_PLATFORM_IOS,
            AnyHashable.ITBL_HEADER_SDK_VERSION: IterableAPI.sdkVersion,
            AnyHashable.ITBL_HEADER_API_KEY: apiKey,
        ]
    }
    
    private let apiKey: String
    private weak var authProvider: AuthProvider?
    private let endPoint: String
    private let networkSession: NetworkSessionProtocol
    private let deviceMetadata: DeviceMetadata
}
