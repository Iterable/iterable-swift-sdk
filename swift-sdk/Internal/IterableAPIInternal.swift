//
//  Created by Tapash Majumder on 5/30/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

struct DeviceMetadata: Codable {
    let deviceId: String
    let platform: String
    let appPackageName: String
}

final class IterableAPIInternal: NSObject, PushTrackerProtocol, AuthProvider {
    var apiKey: String
    
    var email: String? {
        get {
            return _email
        } set {
            guard newValue != _email else {
                return
            }
            
            logoutPreviousUser()
            
            _email = newValue
            _userId = nil
            storeEmailAndUserId()
            
            loginNewUser()
        }
    }
    
    var userId: String? {
        get {
            return _userId
        } set {
            guard newValue != _userId else {
                return
            }
            
            logoutPreviousUser()
            
            _userId = newValue
            _email = nil
            storeEmailAndUserId()
            
            loginNewUser()
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
        return DeviceMetadata(deviceId: deviceId,
                              platform: JsonValue.iOS.jsonStringValue,
                              appPackageName: Bundle.main.appPackageName ?? "")
    }
    
    var lastPushPayload: [AnyHashable: Any]? {
        return localStorage.getPayload(currentDate: dateProvider.currentDate)
    }
    
    var attributionInfo: IterableAttributionInfo? {
        get {
            return localStorage.getAttributionInfo(currentDate: dateProvider.currentDate)
        } set {
            let expiration = Calendar.current.date(byAdding: .hour,
                                                   value: Const.UserDefaults.attributionInfoExpiration,
                                                   to: dateProvider.currentDate)
            localStorage.save(attributionInfo: newValue, withExpiration: expiration)
        }
    }
    
    // AuthProvider Protocol
    var auth: Auth {
        return Auth(userId: userId, email: email)
    }
    
    lazy var inAppManager: IterableInternalInAppManagerProtocol = {
        self.dependencyContainer.createInAppManager(config: self.config, apiClient: self.apiClient, deviceMetadata: deviceMetadata)
    }()
    
    func register(token: Data,
                  onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "registerToken"),
                  onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "registerToken")) {
        guard let appName = pushIntegrationName else {
            ITBError("registerToken: appName is nil")
            onFailure?("Not registering device token - appName must not be nil", nil)
            return
        }
        
        self.register(token: token,
                      appName: appName,
                      pushServicePlatform: self.config.pushPlatform,
                      notificationsEnabled: notificationStateProvider.notificationsEnabled,
                      onSuccess: onSuccess,
                      onFailure: onFailure)
    }
    
    @discardableResult private func register(token: Data,
                                             appName: String,
                                             pushServicePlatform: PushServicePlatform,
                                             notificationsEnabled: Bool,
                                             onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "registerToken"),
                                             onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "registerToken")) -> Future<SendRequestValue, SendRequestError> {
        hexToken = token.hexString()
        
        let pushServicePlatformString = IterableAPIInternal.pushServicePlatformToString(pushServicePlatform, apnsType: dependencyContainer.apnsTypeChecker.apnsType)
        
        return IterableAPIInternal.call(successHandler: onSuccess,
                                        andFailureHandler: onFailure,
                                        forResult: apiClient.register(hexToken: hexToken!,
                                                                      appName: appName,
                                                                      deviceId: deviceId,
                                                                      sdkVersion: localStorage.sdkVersion,
                                                                      deviceAttributes: deviceAttributes,
                                                                      pushServicePlatform: pushServicePlatformString,
                                                                      notificationsEnabled: notificationsEnabled))
    }
    
    func disableDeviceForCurrentUser(withOnSuccess onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "disableDevice"),
                                     onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "disableDevice")) {
        disableDevice(forAllUsers: false, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func disableDeviceForAllUsers(withOnSuccess onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "disableDevice"),
                                  onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "disableDevice")) {
        disableDevice(forAllUsers: true, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func updateUser(_ dataFields: [AnyHashable: Any],
                    mergeNestedObjects: Bool,
                    onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "updateUser"),
                    onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "updateUser")) {
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects))
    }
    
    func updateEmail(_ newEmail: String,
                     onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "updateEmail"),
                     onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "updateEmail")) {
        apiClient.updateEmail(newEmail: newEmail).onSuccess { json in
            if let _ = self.email {
                // we change the email only if we were using email before
                self.email = newEmail
            }
            onSuccess?(json)
        }.onError { error in
            onFailure?(error.reason, error.data)
        }
    }
    
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "trackPurchase"),
                       onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "trackPurchase")) {
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.track(purchase: total, items: items, dataFields: dataFields))
    }
    
    func trackPushOpen(_ userInfo: [AnyHashable: Any],
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "trackPushOpen"),
                       onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen")) {
        save(pushPayload: userInfo)
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            trackPushOpen(metadata.campaignId,
                          templateId: metadata.templateId,
                          messageId: metadata.messageId,
                          appAlreadyRunning: false,
                          dataFields: dataFields,
                          onSuccess: onSuccess,
                          onFailure: onFailure)
        } else {
            onFailure?("Not tracking push open - payload is not an Iterable notification, or is a test/proof/ghost push", nil)
        }
    }
    
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String?,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "trackPushOpen"),
                       onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen")) {
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.track(pushOpen: campaignId,
                                                            templateId: templateId,
                                                            messageId: messageId,
                                                            appAlreadyRunning: appAlreadyRunning,
                                                            dataFields: dataFields))
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
    
    func track(_ eventName: String,
               dataFields: [AnyHashable: Any]? = nil,
               onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "trackEvent"),
               onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "trackEvent")) {
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.track(event: eventName, dataFields: dataFields))
    }
    
    func updateSubscriptions(_ emailListIds: [NSNumber]?,
                             unsubscribedChannelIds: [NSNumber]?,
                             unsubscribedMessageTypeIds: [NSNumber]?,
                             subscribedMessageTypeIds: [NSNumber]?,
                             campaignId: NSNumber?,
                             templateId: NSNumber?) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "updateSubscriptions"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "updateSubscriptions"),
                                 forResult: apiClient.updateSubscriptions(emailListIds,
                                                                          unsubscribedChannelIds: unsubscribedChannelIds,
                                                                          unsubscribedMessageTypeIds: unsubscribedMessageTypeIds,
                                                                          subscribedMessageTypeIds: subscribedMessageTypeIds,
                                                                          campaignId: campaignId,
                                                                          templateId: templateId))
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func trackInAppOpen(_ messageId: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "trackInAppOpen"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppOpen"),
                                 forResult: apiClient.track(inAppOpen: messageId))
    }
    
    func trackInAppOpen(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String? = nil) {
        let result = apiClient.track(inAppOpen: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId))
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "trackInAppOpen"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppOpen"),
                                 forResult: result)
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func trackInAppClick(_ messageId: String, clickedUrl: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "trackInAppClick"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClick"),
                                 forResult: apiClient.track(inAppClick: messageId, clickedUrl: clickedUrl))
    }
    
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         clickedUrl: String) {
        let result = apiClient.track(inAppClick: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId),
                                     clickedUrl: clickedUrl)
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "trackInAppClick"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClick"),
                                 forResult: result)
    }
    
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         source: InAppCloseSource? = nil,
                         clickedUrl: String? = nil) {
        let result = apiClient.track(inAppClose: InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId),
                                     source: source,
                                     clickedUrl: clickedUrl)
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "trackInAppClose"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClose"),
                                 forResult: result)
    }
    
    func track(inboxSession: IterableInboxSession) {
        let result = apiClient.track(inboxSession: inboxSession)
        
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "trackInboxSession"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInboxSession"),
                                 forResult: result)
    }
    
    func track(inAppDelivery message: IterableInAppMessage) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "trackInAppDelivery"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppDelivery"),
                                 forResult: apiClient.track(inAppDelivery: InAppMessageContext.from(message: message, location: nil)))
    }
    
    func inAppConsume(_ messageId: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "inAppConsume"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "inAppConsume"),
                                 forResult: apiClient.inAppConsume(messageId: messageId))
    }
    
    func inAppConsume(message: IterableInAppMessage, location: InAppLocation = .inApp, source: InAppDeleteSource? = nil) {
        let result = apiClient.inAppConsume(inAppMessageContext: InAppMessageContext.from(message: message, location: location),
                                            source: source)
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSuccess(identifier: "inAppConsumeWithSource"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "inAppConsumeWithSource"),
                                 forResult: result)
    }
    
    private func disableDevice(forAllUsers allUsers: Bool,
                               onSuccess: OnSuccessHandler? = IterableAPIInternal.defaultOnSuccess(identifier: "disableDevice"),
                               onFailure: OnFailureHandler? = IterableAPIInternal.defaultOnFailure(identifier: "disableDevice")) {
        guard let hexToken = hexToken else {
            ITBError("Device not registered.")
            onFailure?("Device not registered.", nil)
            return
        }
        
        guard !(allUsers == false && email == nil && userId == nil) else {
            ITBError("Emal or userId must be set.")
            onFailure?("Email or userId must be set.", nil)
            return
        }
        
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.disableDevice(forAllUsers: allUsers, hexToken: hexToken))
    }
    
    // deprecated - will be removed in version 6.3.x or above
    func showSystemNotification(withTitle title: String, body: String, buttonLeft: String? = nil, buttonRight: String? = nil, callbackBlock: ITEActionBlock?) {
        InAppDisplayer.showSystemNotification(withTitle: title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }
    
    // deprecated - will be removed in version 6.3.x or above
    @discardableResult func getAndTrack(deepLink: URL, callbackBlock: @escaping ITEActionBlock) -> Future<IterableAttributionInfo?, Error>? {
        return deepLinkManager.getAndTrack(deepLink: deepLink, callbackBlock: callbackBlock).onSuccess { attributionInfo in
            if let attributionInfo = attributionInfo {
                self.attributionInfo = attributionInfo
            }
        }
    }
    
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
    
    @discardableResult private static func call(successHandler onSuccess: OnSuccessHandler? = nil,
                                                andFailureHandler onFailure: OnFailureHandler? = nil,
                                                forResult result: Future<SendRequestValue, SendRequestError>) -> Future<SendRequestValue, SendRequestError> {
        result.onSuccess { json in
            onSuccess?(json)
        }.onError { error in
            onFailure?(error.reason, error.data)
        }
        return result
    }
    
    // MARK: For Private and Internal Use ========================================>
    
    private var config: IterableConfig
    
    private let dateProvider: DateProviderProtocol
    
    private let inAppDisplayer: InAppDisplayerProtocol
    
    private var deepLinkManager: IterableDeepLinkManager
    
    private var _email: String?
    private var _userId: String?
    
    // the hex representation of this device token
    private var hexToken: String?
    
    private var notificationStateProvider: NotificationStateProviderProtocol
    
    private var localStorage: LocalStorageProtocol
    
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    
    lazy var apiClient: ApiClient = {
        ApiClient(apiKey: apiKey, authProvider: self, endPoint: config.apiEndpoint, networkSession: networkSession, deviceMetadata: deviceMetadata)
    }()
    
    var networkSession: NetworkSessionProtocol
    
    private var urlOpener: UrlOpenerProtocol
    
    private var deviceAttributes = [String: String]()
    
    private var dependencyContainer: DependencyContainerProtocol
    
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
        return IterableUtil.isNotNullOrEmpty(string: _email) || IterableUtil.isNotNullOrEmpty(string: _userId)
    }
    
    private func logoutPreviousUser() {
        ITBInfo()
        guard isEitherUserIdOrEmailSet() else {
            return
        }
        
        if config.autoPushRegistration == true {
            disableDeviceForCurrentUser()
        }
        
        _ = inAppManager.reset()
    }
    
    private func loginNewUser() {
        ITBInfo()
        guard isEitherUserIdOrEmailSet() else {
            return
        }
        
        if config.autoPushRegistration == true {
            notificationStateProvider.registerForRemoteNotifications()
        }
        
        _ = inAppManager.scheduleSync()
    }
    
    static func defaultOnSuccess(identifier: String) -> OnSuccessHandler {
        return { data in
            if let data = data {
                ITBInfo("\(identifier) succeeded, got response: \(data)")
            } else {
                ITBInfo("\(identifier) succeeded.")
            }
        }
    }
    
    static func defaultOnFailure(identifier: String) -> OnFailureHandler {
        return { reason, data in
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
    
    private func storeEmailAndUserId() {
        localStorage.email = _email
        localStorage.userId = _userId
    }
    
    private func retrieveEmailAndUserId() {
        _email = localStorage.email
        _userId = localStorage.userId
    }
    
    // MARK: Initialization
    
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
        // sdk version
        updateSDKVersion()
        
        // check for deferred deep linking
        checkForDeferredDeepLink()
        
        // get email and userId from UserDefaults if present
        retrieveEmailAndUserId()
        
        if config.autoPushRegistration == true, isEitherUserIdOrEmailSet() {
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
