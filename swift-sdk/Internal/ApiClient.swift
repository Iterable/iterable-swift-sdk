//
//  Created by Tapash Majumder on 5/16/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

struct DeviceMetadata: Codable {
    let deviceId: String
    let platform: String
    let appPackageName: String
}

// MARK: - API CLIENT FUNCTIONS

class ApiClient {
    init(apiKey: String,
         authProvider: AuthProvider,
         endPoint: String,
         networkSession: NetworkSessionProtocol,
         deviceMetadata: DeviceMetadata) {
        self.apiKey = apiKey
        self.authProvider = authProvider
        self.endPoint = endPoint
        self.networkSession = networkSession
        self.deviceMetadata = deviceMetadata
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
    
    // MARK: - Private
    
    private func createRequestCreator() -> RequestCreator {
        guard let authProvider = authProvider else {
            fatalError("authProvider is missing")
        }
        
        return RequestCreator(apiKey: apiKey, auth: authProvider.auth, deviceMetadata: deviceMetadata)
    }
    
    private func createIterableHeaders() -> [String: String] {
        var headers = [JsonKey.contentType.jsonKey: JsonValue.applicationJson.jsonStringValue,
                       JsonKey.Header.sdkPlatform: JsonValue.iOS.jsonStringValue,
                       JsonKey.Header.sdkVersion: IterableAPI.sdkVersion,
                       JsonKey.Header.apiKey: apiKey]
        
        if let authToken = authProvider?.auth.authToken {
            headers[JsonKey.Header.authorization] = "Bearer \(authToken)"
        }
        
        return headers
    }
    
    private let apiKey: String
    private weak var authProvider: AuthProvider?
    private let endPoint: String
    private let networkSession: NetworkSessionProtocol
    private let deviceMetadata: DeviceMetadata
}

// MARK: - API REQUEST CALLS

extension ApiClient: ApiClientProtocol {
    func register(hexToken: String,
                  appName: String,
                  deviceId: String,
                  sdkVersion: String?,
                  deviceAttributes: [String: String],
                  pushServicePlatform: String,
                  notificationsEnabled: Bool) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createRegisterTokenRequest(hexToken: hexToken,
                                                                                      appName: appName,
                                                                                      deviceId: deviceId,
                                                                                      sdkVersion: sdkVersion,
                                                                                      deviceAttributes: deviceAttributes,
                                                                                      pushServicePlatform: pushServicePlatform,
                                                                                      notificationsEnabled: notificationsEnabled))
    }
    
    func updateUser(_ dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createUpdateUserRequest(dataFields: dataFields, mergeNestedObjects: mergeNestedObjects))
    }
    
    func updateEmail(newEmail: String) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createUpdateEmailRequest(newEmail: newEmail))
    }
    
    func getInAppMessages(_ count: NSNumber) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createGetInAppMessagesRequest(count))
    }
    
    func disableDevice(forAllUsers allUsers: Bool, hexToken: String) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createDisableDeviceRequest(forAllUsers: allUsers, hexToken: hexToken))
    }
    
    func track(purchase total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackPurchaseRequest(total, items: items, dataFields: dataFields))
    }
    
    func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackPushOpenRequest(campaignId,
                                                                                      templateId: templateId,
                                                                                      messageId: messageId,
                                                                                      appAlreadyRunning: appAlreadyRunning,
                                                                                      dataFields: dataFields))
    }
    
    func track(event eventName: String, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackEventRequest(eventName, dataFields: dataFields))
    }
    
    func updateSubscriptions(_ emailListIds: [NSNumber]? = nil,
                             unsubscribedChannelIds: [NSNumber]? = nil,
                             unsubscribedMessageTypeIds: [NSNumber]? = nil,
                             subscribedMessageTypeIds: [NSNumber]? = nil,
                             campaignId: NSNumber? = nil,
                             templateId: NSNumber? = nil) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createUpdateSubscriptionsRequest(emailListIds,
                                                                                            unsubscribedChannelIds: unsubscribedChannelIds,
                                                                                            unsubscribedMessageTypeIds: unsubscribedMessageTypeIds,
                                                                                            subscribedMessageTypeIds: subscribedMessageTypeIds,
                                                                                            campaignId: campaignId,
                                                                                            templateId: templateId))
    }
    
    func track(inAppOpen inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInAppOpenRequest(inAppMessageContext: inAppMessageContext))
    }
    
    func track(inAppClick inAppMessageContext: InAppMessageContext, clickedUrl: String) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInAppClickRequest(inAppMessageContext: inAppMessageContext, clickedUrl: clickedUrl))
    }
    
    func track(inAppClose inAppMessageContext: InAppMessageContext, source: InAppCloseSource?, clickedUrl: String?) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInAppCloseRequest(inAppMessageContext: inAppMessageContext, source: source, clickedUrl: clickedUrl))
    }
    
    func track(inAppDelivery inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInAppDeliveryRequest(inAppMessageContext: inAppMessageContext))
    }
    
    func track(inboxSession: IterableInboxSession) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInboxSessionRequest(inboxSession: inboxSession))
    }
    
    func inAppConsume(messageId: String) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createInAppConsumeRequest(messageId))
    }
    
    func inAppConsume(inAppMessageContext: InAppMessageContext, source: InAppDeleteSource?) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInAppConsumeRequest(inAppMessageContext: inAppMessageContext, source: source))
    }
}

// MARK: - DEPRECATED

extension ApiClient {
    // deprecated - will be removed in version 6.3.x or above
    func track(inAppOpen messageId: String) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInAppOpenRequest(messageId))
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func track(inAppClick messageId: String, clickedUrl: String) -> Future<SendRequestValue, SendRequestError> {
        send(iterableRequestResult: createRequestCreator().createTrackInAppClickRequest(messageId, clickedUrl: clickedUrl))
    }
}
