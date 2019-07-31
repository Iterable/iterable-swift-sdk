//
//
//  Created by Tapash Majumder on 5/16/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

protocol ApiClientProtocol: class {
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
    
    func track(inAppOpen messageId: String, saveToInbox: Bool?, silentInbox: Bool?, location: String?) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppClick messageId: String, saveToInbox: Bool?, silentInbox: Bool?, location: String?, buttonURL: String) -> Future<SendRequestValue, SendRequestError>
    
    @discardableResult func inAppConsume(messageId: String) -> Future<SendRequestValue, SendRequestError>
    
    func disableDevice(forAllUsers allUsers: Bool, hexToken: String) -> Future<SendRequestValue, SendRequestError>
}

struct Auth {
    let userId: String?
    let email: String?
}

protocol AuthProvider: class {
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
                                                                                             deviceId: deviceMetadata.deviceId,
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
    
    func track(inAppOpen messageId: String, saveToInbox: Bool?, silentInbox: Bool?, location: String?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppOpenRequest(messageId, saveToInbox: saveToInbox, silentInbox: silentInbox, location: location, deviceMetadata: deviceMetadata))
    }
    
    func track(inAppClick messageId: String, saveToInbox: Bool?, silentInbox: Bool?, location: String?, buttonURL: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInAppClickRequest(messageId, saveToInbox: saveToInbox, silentInbox: silentInbox, location: location, deviceMetadata: deviceMetadata, buttonURL: buttonURL))
    }
    
    func inAppConsume(messageId: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createInAppConsumeRequest(messageId))
    }
    
    func disableDevice(forAllUsers allUsers: Bool, hexToken: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createDisableDeviceRequest(forAllUsers: allUsers, hexToken: hexToken))
    }
    
    func convertToURLRequest(iterableRequest: IterableRequest) -> URLRequest? {
        switch (iterableRequest) {
        case .get(let getRequest):
            return IterableRequestUtil.createGetRequest(forApiEndPoint: endPoint, path: getRequest.path, args: getRequest.args)
        case .post(let postRequest):
            return IterableRequestUtil.createPostRequest(forApiEndPoint: endPoint, path: postRequest.path, args: postRequest.args, body: postRequest.body)
        }
    }
    
    func send(iterableRequestResult result: Result<IterableRequest, IterableError>) -> Future<SendRequestValue, SendRequestError> {
        switch result {
        case .success(let iterableRequest):
            return send(iterableRequest: iterableRequest)
        case .failure(let iterableError):
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
        
        return RequestCreator(apiKey: apiKey, auth: authProvider.auth)
    }
    
    private let apiKey: String
    private weak var authProvider: AuthProvider?
    private let endPoint: String
    private let networkSession: NetworkSessionProtocol    
    private var deviceMetadata: DeviceMetadata
}
