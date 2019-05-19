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

struct ApiClient {
    let apiKey: String
    let auth: Auth
    let endPoint: String
    let networkSession: NetworkSessionProtocol

    private func createRequestCreator() -> RequestCreator {
        return RequestCreator(apiKey: apiKey, auth: auth)
    }
    
    func register(hexToken: String,
                  appName: String,
                  deviceId: String,
                  sdkVersion: String?,
                  pushServicePlatform: PushServicePlatform,
                  notificationsEnabled: Bool) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createReqisterTokenRequest(hexToken: hexToken,
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
    
    func track(purchase total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackPurchaseRequest(total, items: items, dataFields: dataFields))
    }
    
    func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackPushOpenRequest(campaignId,
                                                                      templateId: templateId,
                                                                      messageId: messageId,
                                                                      appAlreadyRunning: appAlreadyRunning,
                                                                      dataFields: dataFields))
    }
    
    func track(event eventName: String, dataFields: [AnyHashable : Any]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackEventRequest(eventName, dataFields: dataFields))
    }

    func updateSubscriptions(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createUpdateSubscriptionsRequest(emailListIds, unsubscribedChannelIds: unsubscribedChannelIds, unsubscribedMessageTypeIds: unsubscribedMessageTypeIds))
    }

    func getInAppMessages(_ count: NSNumber) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createGetInppMessagesRequest(count))
    }

    func track(inAppOpen messageId: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInappOpenRequest(messageId))
    }

    func track(inAppClick messageId: String, buttonIndex: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInappClickRequest(messageId, buttonIndex: buttonIndex))
    }

    func track(inAppClick messageId: String, buttonURL: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createTrackInappClickRequest(messageId, buttonURL: buttonURL))
    }

    func inappConsume(messageId: String) -> Future<SendRequestValue, SendRequestError> {
        return send(iterableRequestResult: createRequestCreator().createInappConsumeRequest(messageId))
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
}




