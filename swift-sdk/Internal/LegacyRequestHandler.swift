//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// Request handling pre iOS 10.0
@available(iOSApplicationExtension, unavailable)
class LegacyRequestHandler: RequestHandlerProtocol {
    init(apiKey: String,
         authProvider: AuthProvider?,
         authManager: IterableAuthManagerProtocol?,
         endPoint: String,
         networkSession: NetworkSessionProtocol,
         deviceMetadata: DeviceMetadata,
         dateProvider: DateProviderProtocol) {
        self.authManager = authManager
        apiClient = ApiClient(apiKey: apiKey,
                              authProvider: authProvider,
                              endPoint: endPoint,
                              networkSession: networkSession,
                              deviceMetadata: deviceMetadata,
                              dateProvider: dateProvider)
    }
    
    var offlineMode = false
    
    func start() {
        ITBInfo()
    }
    
    func stop() {
        ITBInfo()
    }
    
    @discardableResult
    func register(registerTokenInfo: RegisterTokenInfo,
                  notificationStateProvider: NotificationStateProviderProtocol,
                  onSuccess: OnSuccessHandler? = nil,
                  onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        self.register(registerTokenInfo: registerTokenInfo,
                      notificationsEnabled: notificationStateProvider.notificationsEnabled,
                      onSuccess: onSuccess,
                      onFailure: onFailure)
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
        applyCallbacks(successHandler: onSuccess,
                       andFailureHandler: onFailure,
                       withIdentifier: "updateUser",
                       forResult: apiClient.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects))
    }
    
    @discardableResult
    func updateEmail(_ newEmail: String,
                     onSuccess: OnSuccessHandler? = nil,
                     onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        applyCallbacks(successHandler: onSuccess,
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
        applyCallbacks(successHandler: onSuccess,
                       andFailureHandler: onFailure,
                       withIdentifier: "trackPurchase",
                       forResult: apiClient.track(purchase: total, items: items, dataFields: dataFields))
    }
    
    @discardableResult
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        applyCallbacks(successHandler: onSuccess,
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
        applyCallbacks(successHandler: onSuccess,
                       andFailureHandler: onFailure,
                       withIdentifier: "trackEvent",
                       forResult: apiClient.track(event: event, dataFields: dataFields))
    }
    
    @discardableResult
    func updateSubscriptions(info: UpdateSubscriptionsInfo,
                             onSuccess: OnSuccessHandler? = nil,
                             onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        applyCallbacks(successHandler: onSuccess,
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
        return applyCallbacks(successHandler: onSuccess,
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
        return applyCallbacks(successHandler: onSuccess,
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
        return applyCallbacks(successHandler: onSuccess,
                              andFailureHandler: onFailure,
                              withIdentifier: "trackInAppClose",
                              forResult: result)
    }
    
    @discardableResult
    func track(inboxSession: IterableInboxSession,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inboxSession: inboxSession)
        
        return applyCallbacks(successHandler: onSuccess,
                              andFailureHandler: onFailure,
                              withIdentifier: "trackInboxSession",
                              forResult: result)
    }
    
    @discardableResult
    func track(inAppDelivery message: IterableInAppMessage,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        applyCallbacks(successHandler: onSuccess,
                       andFailureHandler: onFailure,
                       withIdentifier: "trackInAppDelivery",
                       forResult: apiClient.track(inAppDelivery: InAppMessageContext.from(message: message, location: nil)))
    }
    
    @discardableResult
    func inAppConsume(_ messageId: String,
                      onSuccess: OnSuccessHandler? = nil,
                      onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        applyCallbacks(successHandler: onSuccess,
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
        return applyCallbacks(successHandler: onSuccess,
                              andFailureHandler: onFailure,
                              withIdentifier: "inAppConsumeWithSource",
                              forResult: result)
    }
    
    func handleLogout() {
    }
    
    func getRemoteConfiguration() -> Future<RemoteConfiguration, SendRequestError> {
        apiClient.getRemoteConfiguration()
    }

    private let apiClient: ApiClientProtocol
    private weak var authManager: IterableAuthManagerProtocol?
    
    @discardableResult
    private func register(registerTokenInfo: RegisterTokenInfo,
                          notificationsEnabled: Bool,
                          onSuccess: OnSuccessHandler? = nil,
                          onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        return applyCallbacks(successHandler: onSuccess,
                              andFailureHandler: onFailure,
                              withIdentifier: "registerToken",
                              forResult: apiClient.register(registerTokenInfo: registerTokenInfo,
                                                            notificationsEnabled: notificationsEnabled))
    }
    
    @discardableResult
    private func disableDevice(forAllUsers allUsers: Bool,
                               hexToken: String,
                               onSuccess: OnSuccessHandler? = nil,
                               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        applyCallbacks(successHandler: onSuccess,
                       andFailureHandler: onFailure,
                       withIdentifier: "disableDevice",
                       forResult: apiClient.disableDevice(forAllUsers: allUsers, hexToken: hexToken))
    }
    
    private func applyCallbacks(successHandler onSuccess: OnSuccessHandler? = nil,
                                andFailureHandler onFailure: OnFailureHandler? = nil,
                                withIdentifier identifier: String,
                                forResult result: Future<SendRequestValue, SendRequestError>) -> Future<SendRequestValue, SendRequestError> {
        RequestProcessorUtil.apply(successHandler: onSuccess,
                                   andFailureHandler: onFailure,
                                   andAuthManager: authManager,
                                   toResult: result,
                                   withIdentifier: identifier)
    }
}
