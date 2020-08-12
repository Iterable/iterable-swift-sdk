//
//  Created by Tapash Majumder on 5/30/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

final class IterableAPIInternal: NSObject, PushTrackerProtocol, AuthProvider {
    var apiKey: String
    
    var email: String? {
        get {
            _email
        } set {
            setEmail(newValue)
        }
    }
    
    var userId: String? {
        get {
            _userId
        } set {
            setUserId(newValue)
        }
    }
    
    var deviceId: String {
        if let value = localStorage.deviceId {
            return value
        } else {
            let value = IterableUtil.generateUUID()
            localStorage.deviceId = value
            return value
        }
    }
    
    var deviceMetadata: DeviceMetadata {
        DeviceMetadata(deviceId: deviceId,
                       platform: JsonValue.iOS.jsonStringValue,
                       appPackageName: Bundle.main.appPackageName ?? "")
    }
    
    var lastPushPayload: [AnyHashable: Any]? {
        localStorage.getPayload(currentDate: dateProvider.currentDate)
    }
    
    var attributionInfo: IterableAttributionInfo? {
        get {
            localStorage.getAttributionInfo(currentDate: dateProvider.currentDate)
        } set {
            let expiration = Calendar.current.date(byAdding: .hour,
                                                   value: Const.UserDefaults.attributionInfoExpiration,
                                                   to: dateProvider.currentDate)
            localStorage.save(attributionInfo: newValue, withExpiration: expiration)
        }
    }
    
    var auth: Auth {
        Auth(userId: userId, email: email, authToken: authToken)
    }
    
    lazy var inAppManager: IterableInternalInAppManagerProtocol = {
        self.dependencyContainer.createInAppManager(config: self.config,
                                                    apiClient: self.apiClient,
                                                    deviceMetadata: deviceMetadata)
    }()
    
    // MARK: - SDK Functions
    
    @discardableResult func handleUniversalLink(_ url: URL) -> Bool {
        let (result, future) = deepLinkManager.handleUniversalLink(url, urlDelegate: config.urlDelegate, urlOpener: AppUrlOpener())
        future.onSuccess { attributionInfo in
            if let attributionInfo = attributionInfo {
                self.attributionInfo = attributionInfo
            }
        }
        return result
    }
    
    func setDeviceAttribute(name: String, value: String) {
        deviceAttributes[name] = value
    }
    
    func removeDeviceAttribute(name: String) {
        deviceAttributes.removeValue(forKey: name)
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
    
    func setEmail(_ email: String?, withToken token: String? = nil) {
        if email != _email {
            logoutPreviousUser()
            
            _email = email
            _userId = nil
            authToken = token
            
            storeAuthData()
            
            loginNewUser()
        } else if token != authToken {
            authToken = token
            
            storeAuthData()
        }
    }
    
    func setUserId(_ userId: String?, withToken token: String? = nil) {
        if userId != _userId {
            logoutPreviousUser()
            
            _email = nil
            _userId = userId
            authToken = token
            
            storeAuthData()
            
            loginNewUser()
        } else if token != authToken {
            authToken = token
            
            storeAuthData()
        }
    }
    
    func logoutUser() {
        logoutPreviousUser()
    }
    
    // MARK: - API Request Calls

    @discardableResult
    func register(token: Data,
                  onSuccess: OnSuccessHandler? = nil,
                  onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        guard let appName = pushIntegrationName else {
            let errorMessage = "Not registering device token - appName must not be nil"
            ITBError(errorMessage)
            onFailure?(errorMessage, nil)
            return SendRequestError.createErroredFuture(reason: errorMessage)
        }

        hexToken = token.hexString()
        let registerTokenInfo = IterableRequestProcessor.RegisterTokenInfo(hexToken: token.hexString(),
                                                                           appName: appName,
                                                                           pushServicePlatform: config.pushPlatform,
                                                                           apnsType: dependencyContainer.apnsTypeChecker.apnsType,
                                                                           deviceId: deviceId,
                                                                           deviceAttributes: deviceAttributes,
                                                                           sdkVersion: localStorage.sdkVersion)
        return requestProcessor.register(registerTokenInfo: registerTokenInfo,
                                         notificationStateProvider: notificationStateProvider,
                                         onSuccess: onSuccess,
                                         onFailure: onFailure)
    }
    
    @discardableResult
    func disableDeviceForCurrentUser(withOnSuccess onSuccess: OnSuccessHandler? = nil,
                                     onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        guard let hexToken = hexToken else {
            let errorMessage = "no token present"
            onFailure?(errorMessage, nil)
            return SendRequestError.createErroredFuture(reason: errorMessage)
        }
        guard userId != nil || email != nil else {
            let errorMessage = "either userId or email must be present"
            onFailure?(errorMessage, nil)
            return SendRequestError.createErroredFuture(reason: errorMessage)
        }
        
        return requestProcessor.disableDeviceForCurrentUser(hexToken: hexToken, withOnSuccess: onSuccess, onFailure: onFailure)
    }

    @discardableResult
    func disableDeviceForAllUsers(withOnSuccess onSuccess: OnSuccessHandler? = nil,
                                  onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        guard let hexToken = hexToken else {
            let errorMessage = "no token present"
            onFailure?(errorMessage, nil)
            return SendRequestError.createErroredFuture(reason: errorMessage)
        }
        return requestProcessor.disableDeviceForAllUsers(hexToken: hexToken, withOnSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateUser(_ dataFields: [AnyHashable: Any],
                    mergeNestedObjects: Bool,
                    onSuccess: OnSuccessHandler? = nil,
                    onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        requestProcessor.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateEmail(_ newEmail: String,
                     withToken token: String? = nil,
                     onSuccess: OnSuccessHandler? = nil,
                     onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        requestProcessor.updateEmail(newEmail, withToken: token, onSuccess: onSuccess, onFailure: onFailure).onSuccess { _ in
            // only change email if one is being used
            if self.email != nil {
                self.setEmail(newEmail, withToken: token)
            }
        }
    }
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        requestProcessor.trackPurchase(total, items: items, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func trackPushOpen(_ userInfo: [AnyHashable: Any],
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        save(pushPayload: userInfo)
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            return trackPushOpen(metadata.campaignId,
                                 templateId: metadata.templateId,
                                 messageId: metadata.messageId,
                                 appAlreadyRunning: false,
                                 dataFields: dataFields,
                                 onSuccess: onSuccess,
                                 onFailure: onFailure)
        } else {
            return SendRequestError.createErroredFuture(reason: "Not tracking push open - payload is not an Iterable notification, or is a test/proof/ghost push")
        }
    }
    
    @discardableResult
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String?,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        requestProcessor.trackPushOpen(campaignId,
                                       templateId: templateId,
                                       messageId: messageId,
                                       appAlreadyRunning: appAlreadyRunning,
                                       dataFields: dataFields,
                                       onSuccess: onSuccess,
                                       onFailure: onFailure)
    }
    
    @discardableResult
    func track(_ eventName: String,
               dataFields: [AnyHashable: Any]? = nil,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        requestProcessor.track(event: eventName, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateSubscriptions(_ emailListIds: [NSNumber]?,
                             unsubscribedChannelIds: [NSNumber]?,
                             unsubscribedMessageTypeIds: [NSNumber]?,
                             subscribedMessageTypeIds: [NSNumber]?,
                             campaignId: NSNumber?,
                             templateId: NSNumber?,
                             onSuccess: OnSuccessHandler? = nil,
                             onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        let updateSubscriptionsInfo = IterableRequestProcessor.UpdateSubscriptionsInfo(emailListIds: emailListIds,
                                                                                       unsubscribedChannelIds: unsubscribedChannelIds,
                                                                                       unsubscribedMessageTypeIds: unsubscribedMessageTypeIds,
                                                                                       subscribedMessageTypeIds: subscribedMessageTypeIds,
                                                                                       campaignId: campaignId,
                                                                                       templateId: templateId)
        return requestProcessor.updateSubscriptions(info: updateSubscriptionsInfo, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppOpen(_ message: IterableInAppMessage,
                        location: InAppLocation,
                        inboxSessionId: String? = nil,
                        onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess("trackInAppOpen"),
                        onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure("trackInAppOpen")) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inAppOpen: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId))
        return IterableAPIInternal.call(successHandler: onSuccess,
                                        andFailureHandler: onFailure,
                                        forResult: result)
    }
    
    @discardableResult
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess("trackInAppClick"),
                         onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure("trackInAppClick")) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inAppClick: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId),
                                     clickedUrl: clickedUrl)
        return IterableAPIInternal.call(successHandler: onSuccess,
                                        andFailureHandler: onFailure,
                                        forResult: result)
    }
    
    @discardableResult
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         source: InAppCloseSource? = nil,
                         clickedUrl: String? = nil,
                         onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess("trackInAppClose"),
                         onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure("trackInAppClose")) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inAppClose: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId),
                                     source: source,
                                     clickedUrl: clickedUrl)
        return IterableAPIInternal.call(successHandler: onSuccess,
                                        andFailureHandler: onFailure,
                                        forResult: result)
    }
    
    @discardableResult
    func track(inboxSession: IterableInboxSession,
               onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess("trackInboxSession"),
               onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure("trackInboxSession")) -> Future<SendRequestValue, SendRequestError> {
        let result = apiClient.track(inboxSession: inboxSession)
        
        return IterableAPIInternal.call(successHandler: onSuccess,
                                        andFailureHandler: onFailure,
                                        forResult: result)
    }
    
    func track(inAppDelivery message: IterableInAppMessage) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess("trackInAppDelivery"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure("trackInAppDelivery"),
                                 forResult: apiClient.track(inAppDelivery: InAppMessageContext.from(message: message, location: nil)))
    }
    
    func inAppConsume(_ messageId: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess("inAppConsume"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure("inAppConsume"),
                                 forResult: apiClient.inAppConsume(messageId: messageId))
    }
    
    func inAppConsume(message: IterableInAppMessage, location: InAppLocation = .inApp, source: InAppDeleteSource? = nil) {
        let result = apiClient.inAppConsume(inAppMessageContext: InAppMessageContext.from(message: message, location: location),
                                            source: source)
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess("inAppConsumeWithSource"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure("inAppConsumeWithSource"),
                                 forResult: result)
    }
    
    // MARK: - Private/Internal/Initializers
    
    private var config: IterableConfig
    
    private let dateProvider: DateProviderProtocol
    private let inAppDisplayer: InAppDisplayerProtocol
    private var notificationStateProvider: NotificationStateProviderProtocol
    private var localStorage: LocalStorageProtocol
    var networkSession: NetworkSessionProtocol
    private var urlOpener: UrlOpenerProtocol
    private var dependencyContainer: DependencyContainerProtocol
    
    private var deepLinkManager: IterableDeepLinkManager
    
    private var _email: String?
    private var _userId: String?
    private var authToken: String?
    
    // the hex representation of this device token
    private var hexToken: String?
    
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    
    lazy var apiClient: ApiClient = {
        ApiClient(apiKey: apiKey,
                  authProvider: self,
                  endPoint: config.apiEndpoint,
                  networkSession: networkSession,
                  deviceMetadata: deviceMetadata)
    }()
    
    lazy var requestProcessor: IterableRequestProcessor = {
        IterableRequestProcessor(apiClient: self.apiClient)
    }()
    
    private var deviceAttributes = [String: String]()
    
    private var pushIntegrationName: String? {
        if let pushIntegrationName = config.pushIntegrationName, let sandboxPushIntegrationName = config.sandboxPushIntegrationName {
            switch config.pushPlatform {
            case .production:
                return pushIntegrationName
            case .sandbox:
                return sandboxPushIntegrationName
            case .auto:
                return dependencyContainer.apnsTypeChecker.apnsType == .sandbox ? sandboxPushIntegrationName : pushIntegrationName
            }
        } else if let pushIntegrationName = config.pushIntegrationName {
            return pushIntegrationName
        } else {
            return Bundle.main.appPackageName
        }
    }
    
    private func isEitherUserIdOrEmailSet() -> Bool {
        IterableUtil.isNotNullOrEmpty(string: _email) || IterableUtil.isNotNullOrEmpty(string: _userId)
    }
    
    private func logoutPreviousUser() {
        ITBInfo()
        
        guard isEitherUserIdOrEmailSet() else {
            return
        }
        
        if config.autoPushRegistration {
            disableDeviceForCurrentUser()
        }
        
        _email = nil
        _userId = nil
        authToken = nil
        
        storeAuthData()
        
        _ = inAppManager.reset()
    }
    
    private func loginNewUser() {
        ITBInfo()
        
        guard isEitherUserIdOrEmailSet() else {
            return
        }
        
        if config.autoPushRegistration {
            notificationStateProvider.registerForRemoteNotifications()
        }
        
        _ = inAppManager.scheduleSync()
    }
    
    private func storeAuthData() {
        localStorage.email = _email
        localStorage.userId = _userId
        localStorage.authToken = authToken
    }
    
    private func retrieveAuthData() {
        _email = localStorage.email
        _userId = localStorage.userId
        authToken = localStorage.authToken
    }
    
    private func save(pushPayload payload: [AnyHashable: Any]) {
        let expiration = Calendar.current.date(byAdding: .hour,
                                               value: Const.UserDefaults.payloadExpiration,
                                               to: dateProvider.currentDate)
        localStorage.save(payload: payload, withExpiration: expiration)
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload) {
            if let templateId = metadata.templateId, let messageId = metadata.messageId {
                attributionInfo = IterableAttributionInfo(campaignId: metadata.campaignId, templateId: templateId, messageId: messageId)
            }
        }
    }
    
    @discardableResult
    private static func call(successHandler onSuccess: OnSuccessHandler? = nil,
                             andFailureHandler onFailure: OnFailureHandler? = nil,
                             forResult result: Future<SendRequestValue, SendRequestError>) -> Future<SendRequestValue, SendRequestError> {
        result.onSuccess { json in
            onSuccess?(json)
        }.onError { error in
            onFailure?(error.reason, error.data)
        }
        return result
    }
    
    // package private method. Do not call this directly.
    init(apiKey: String,
         launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
         config: IterableConfig = IterableConfig(),
         dependencyContainer: DependencyContainerProtocol = DependencyContainer()) {
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: dependencyContainer.dateProvider, logDelegate: config.logDelegate)
        ITBInfo()
        self.apiKey = apiKey
        self.launchOptions = launchOptions
        self.config = config
        self.dependencyContainer = dependencyContainer
        dateProvider = dependencyContainer.dateProvider
        networkSession = dependencyContainer.networkSession
        notificationStateProvider = dependencyContainer.notificationStateProvider
        localStorage = dependencyContainer.localStorage
        inAppDisplayer = dependencyContainer.inAppDisplayer
        urlOpener = dependencyContainer.urlOpener
        deepLinkManager = IterableDeepLinkManager()
    }
    
    func start() -> Future<Bool, Error> {
        ITBInfo()
        
        updateSDKVersion()
        
        checkForDeferredDeepLink()
        
        // get email, userId, and authToken from UserDefaults if present
        retrieveAuthData()
        
        if config.autoPushRegistration, isEitherUserIdOrEmailSet() {
            notificationStateProvider.registerForRemoteNotifications()
        }
        
        IterableAppIntegration.implementation = IterableAppIntegrationInternal(tracker: self,
                                                                               urlDelegate: config.urlDelegate,
                                                                               customActionDelegate: config.customActionDelegate,
                                                                               urlOpener: urlOpener,
                                                                               inAppNotifiable: inAppManager)
        
        handle(launchOptions: launchOptions)
        
        return inAppManager.start()
    }
    
    private func handle(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let launchOptions = launchOptions else {
            return
        }
        if let remoteNotificationPayload = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            if let _ = IterableUtil.rootViewController {
                // we are ready
                IterableAppIntegration.implementation?.performDefaultNotificationAction(remoteNotificationPayload)
            } else {
                // keywindow not set yet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    IterableAppIntegration.implementation?.performDefaultNotificationAction(remoteNotificationPayload)
                }
            }
        }
    }
    
    private func checkForDeferredDeepLink() {
        guard config.checkForDeferredDeeplink else {
            return
        }
        guard localStorage.ddlChecked == false else {
            return
        }
        
        guard let request = IterableRequestUtil.createPostRequest(forApiEndPoint: config.linksEndpoint,
                                                                  path: Const.Path.ddlMatch,
                                                                  headers: [JsonKey.Header.apiKey: apiKey],
                                                                  args: nil,
                                                                  body: DeviceInfo.createDeviceInfo()) else {
            ITBError("Could not create request")
            return
        }
        
        NetworkHelper.sendRequest(request, usingSession: networkSession).onSuccess { json in
            self.handleDDL(json: json)
        }.onError { sendError in
            ITBError(sendError.reason)
        }
    }
    
    private func handleDDL(json: [AnyHashable: Any]) {
        if let serverResponse = try? JSONDecoder().decode(ServerResponse.self, from: JSONSerialization.data(withJSONObject: json, options: [])),
            serverResponse.isMatch,
            let destinationUrlString = serverResponse.destinationUrl {
            handleUrl(urlString: destinationUrlString, fromSource: .universalLink)
        }
        
        localStorage.ddlChecked = true
    }
    
    private func handleUrl(urlString: String, fromSource source: IterableActionSource) {
        guard let action = IterableAction.actionOpenUrl(fromUrlString: urlString) else {
            ITBError("Could not create action from: \(urlString)")
            return
        }
        
        let context = IterableActionContext(action: action, source: source)
        DispatchQueue.main.async {
            IterableActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self.config.urlDelegate, inContext: context),
                                         urlOpener: self.urlOpener)
        }
    }
    
    private func updateSDKVersion() {
        if let lastVersion = localStorage.sdkVersion, lastVersion != IterableAPI.sdkVersion {
            performUpgrade(lastVersion: lastVersion, newVersion: IterableAPI.sdkVersion)
        } else {
            localStorage.sdkVersion = IterableAPI.sdkVersion
        }
    }
    
    private func performUpgrade(lastVersion _: String, newVersion: String) {
        // do upgrade things here
        // ....
        // then set new version
        localStorage.sdkVersion = newVersion
    }
    
    deinit {
        ITBInfo()
    }
}

// MARK: - DEPRECATED

extension IterableAPIInternal {
    // deprecated - will be removed in version 6.3.x or above
    func trackInAppOpen(_ messageId: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess("trackInAppOpen"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure("trackInAppOpen"),
                                 forResult: apiClient.track(inAppOpen: messageId))
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func trackInAppClick(_ messageId: String, clickedUrl: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess("trackInAppClick"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure("trackInAppClick"),
                                 forResult: apiClient.track(inAppClick: messageId, clickedUrl: clickedUrl))
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func showSystemNotification(withTitle title: String, body: String, buttonLeft: String? = nil, buttonRight: String? = nil, callbackBlock: ITEActionBlock?) {
        InAppDisplayer.showSystemNotification(withTitle: title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }
    
    // deprecated - will be removed in version 6.3.x or above
    @discardableResult func getAndTrack(deepLink: URL, callbackBlock: @escaping ITEActionBlock) -> Future<IterableAttributionInfo?, Error>? {
        deepLinkManager.getAndTrack(deepLink: deepLink, callbackBlock: callbackBlock).onSuccess { attributionInfo in
            if let attributionInfo = attributionInfo {
                self.attributionInfo = attributionInfo
            }
        }
    }
}
