//
//  Created by Tapash Majumder on 8/10/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// `IterableAPIinternal` will delegate all network related calls to this struct.
struct IterableRequestProcessor {
    let apiClient: ApiClientProtocol!
    
    struct RegisterTokenInfo {
        let hexToken: String
        let appName: String
        let pushServicePlatform: PushServicePlatform
        let apnsType: APNSType
        let deviceId: String
        let deviceAttributes: [String: String]
        let sdkVersion: String?
    }
    
    struct UpdateSubscriptionsInfo {
        let emailListIds: [NSNumber]?
        let unsubscribedChannelIds: [NSNumber]?
        let unsubscribedMessageTypeIds: [NSNumber]?
        let subscribedMessageTypeIds: [NSNumber]?
        let campaignId: NSNumber?
        let templateId: NSNumber?
    }
    
    @discardableResult
    func register(registerTokenInfo: RegisterTokenInfo,
                  notificationStateProvider: NotificationStateProviderProtocol,
                  onSuccess: OnSuccessHandler? = nil,
                  onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        // check notificationsEnabled then call register with enabled/not-enabled
        notificationStateProvider.notificationsEnabled
            .mapFailure(SendRequestError.from(error:))
            .replaceError(with: false)
            .flatMap { enabled in
                self.register(registerTokenInfo: registerTokenInfo,
                              notificationsEnabled: enabled,
                              onSuccess: onSuccess,
                              onFailure: onFailure)
            }
    }
    
    @discardableResult
    func disableDeviceForCurrentUser(hexToken: String,
                                     withOnSuccess onSuccess: OnSuccessHandler? = nil,
                                     onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        disableDevice(forAllUsers: false, hexToken: hexToken, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func disableDeviceForAllUsers(hexToken: String,
                                  withOnSuccess onSuccess: OnSuccessHandler? = nil,
                                  onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        disableDevice(forAllUsers: true, hexToken: hexToken, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateUser(_ dataFields: [AnyHashable: Any],
                    mergeNestedObjects: Bool,
                    onSuccess: OnSuccessHandler? = nil,
                    onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "updateUser",
                                      forResult: apiClient.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects))
    }
    
    @discardableResult
    func updateEmail(_ newEmail: String,
                     withToken _: String? = nil,
                     onSuccess: OnSuccessHandler? = nil,
                     onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "updateEmail",
                                      forResult: apiClient.updateEmail(newEmail: newEmail))
    }
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "trackPurchase",
                                      forResult: apiClient.track(purchase: total, items: items, dataFields: dataFields))
    }
    
    @discardableResult
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String?,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "trackPushOpen",
                                      forResult: apiClient.track(pushOpen: campaignId,
                                                                 templateId: templateId,
                                                                 messageId: messageId,
                                                                 appAlreadyRunning: appAlreadyRunning,
                                                                 dataFields: dataFields))
    }
    
    @discardableResult
    func track(event: String,
               dataFields: [AnyHashable: Any]? = nil,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "trackEvent",
                                      forResult: apiClient.track(event: event, dataFields: dataFields))
    }
    
    @discardableResult
    func updateSubscriptions(info: UpdateSubscriptionsInfo,
                             onSuccess: OnSuccessHandler? = nil,
                             onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "updateSubscriptions",
                                      forResult: apiClient.updateSubscriptions(info.emailListIds,
                                                                               unsubscribedChannelIds: info.unsubscribedChannelIds,
                                                                               unsubscribedMessageTypeIds: info.unsubscribedMessageTypeIds,
                                                                               subscribedMessageTypeIds: info.subscribedMessageTypeIds,
                                                                               campaignId: info.campaignId,
                                                                               templateId: info.templateId))
    }
    
    @discardableResult
    func trackInAppOpen(_ message: IterableInAppMessage,
                        location: InAppLocation,
                        inboxSessionId: String? = nil,
                        onSuccess: OnSuccessHandler? = nil,
                        onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inAppOpen: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId))
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             withIdentifier: "trackInAppOpen",
                                             forResult: result)
    }
    
    @discardableResult
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler? = nil,
                         onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inAppClick: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId),
                                     clickedUrl: clickedUrl)
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             withIdentifier: "trackInAppClick",
                                             forResult: result)
    }
    
    @discardableResult
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         source: InAppCloseSource? = nil,
                         clickedUrl: String? = nil,
                         onSuccess: OnSuccessHandler? = nil,
                         onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inAppClose: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId),
                                     source: source,
                                     clickedUrl: clickedUrl)
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             withIdentifier: "trackInAppClose",
                                             forResult: result)
    }
    
    @discardableResult
    func track(inboxSession: IterableInboxSession,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inboxSession: inboxSession)
        
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             withIdentifier: "trackInboxSession",
                                             forResult: result)
    }
    
    @discardableResult
    func track(inAppDelivery message: IterableInAppMessage,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "trackInAppDelivery",
                                      forResult: apiClient.track(inAppDelivery: InAppMessageContext.from(message: message, location: nil)))
    }
    
    @discardableResult
    func inAppConsume(_ messageId: String,
                      onSuccess: OnSuccessHandler? = nil,
                      onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "inAppConsume",
                                      forResult: apiClient.inAppConsume(messageId: messageId))
    }
    
    @discardableResult
    func inAppConsume(message: IterableInAppMessage,
                      location: InAppLocation = .inApp,
                      source: InAppDeleteSource? = nil,
                      onSuccess: OnSuccessHandler? = nil,
                      onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.inAppConsume(inAppMessageContext: InAppMessageContext.from(message: message, location: location),
                                            source: source)
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             withIdentifier: "inAppConsumeWithSource",
                                             forResult: result)
    }
    
    // MARK: DEPRECATED
    
    @discardableResult
    func trackInAppOpen(_ messageId: String,
                        onSuccess: OnSuccessHandler? = nil,
                        onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inAppOpen: messageId)
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             withIdentifier: "trackInAppOpen",
                                             forResult: result)
    }
    
    @discardableResult
    func trackInAppClick(_ messageId: String,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler? = nil,
                         onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "trackInAppClick",
                                      forResult: apiClient.track(inAppClick: messageId, clickedUrl: clickedUrl))
    }
    
    @discardableResult
    private func register(registerTokenInfo: RegisterTokenInfo,
                          notificationsEnabled: Bool,
                          onSuccess: OnSuccessHandler? = nil,
                          onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let pushServicePlatformString = IterableRequestProcessor.pushServicePlatformToString(registerTokenInfo.pushServicePlatform, apnsType: registerTokenInfo.apnsType)
        
        return IterableRequestProcessor.call(successHandler: onSuccess,
                                             andFailureHandler: onFailure,
                                             withIdentifier: "registerToken",
                                             forResult: apiClient.register(hexToken: registerTokenInfo.hexToken,
                                                                           appName: registerTokenInfo.appName,
                                                                           deviceId: registerTokenInfo.deviceId,
                                                                           sdkVersion: registerTokenInfo.sdkVersion,
                                                                           deviceAttributes: registerTokenInfo.deviceAttributes,
                                                                           pushServicePlatform: pushServicePlatformString,
                                                                           notificationsEnabled: notificationsEnabled))
    }
    
    @discardableResult
    private func disableDevice(forAllUsers allUsers: Bool,
                               hexToken: String,
                               onSuccess: OnSuccessHandler? = nil,
                               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        IterableRequestProcessor.call(successHandler: onSuccess,
                                      andFailureHandler: onFailure,
                                      withIdentifier: "disableDevice",
                                      forResult: apiClient.disableDevice(forAllUsers: allUsers, hexToken: hexToken))
    }
    
    private static func pushServicePlatformToString(_ pushServicePlatform: PushServicePlatform, apnsType: APNSType) -> String {
        switch pushServicePlatform {
        case .production:
            return JsonValue.apnsProduction.jsonStringValue
        case .sandbox:
            return JsonValue.apnsSandbox.jsonStringValue
        case .auto:
            return apnsType == .sandbox ? JsonValue.apnsSandbox.jsonStringValue : JsonValue.apnsProduction.jsonStringValue
        }
    }
    
    @discardableResult
    private static func call(successHandler onSuccess: OnSuccessHandler? = nil,
                             andFailureHandler onFailure: OnFailureHandler? = nil,
                             withIdentifier identifier: String,
                             forResult result: Future<SendRequestValue, SendRequestError>) -> Future<SendRequestValue, SendRequestError> {
        result.onSuccess { json in
            if let onSuccess = onSuccess {
                onSuccess(json)
            } else {
                defaultOnSuccess(identifier)(json)
            }
        }.onError { error in
            if let onFailure = onFailure {
                onFailure(error.reason, error.data)
            } else {
                defaultOnFailure(identifier)(error.reason, error.data)
            }
        }
        return result
    }
    
    static func defaultOnSuccess(_ identifier: String) -> OnSuccessHandler {
        { data in
            if let data = data {
                ITBInfo("\(identifier) succeeded, got response: \(data)")
            } else {
                ITBInfo("\(identifier) succeeded.")
            }
        }
    }
    
    static func defaultOnFailure(_ identifier: String) -> OnFailureHandler {
        { reason, data in
            var toLog = "\(identifier) failed:"
            if let reason = reason {
                toLog += ", \(reason)"
            }
            if let data = data {
                toLog += ", got response \(String(data: data, encoding: .utf8) ?? "nil")"
            }
            ITBError(toLog)
        }
    }
}
