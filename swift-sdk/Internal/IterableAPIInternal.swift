//
//
//  Created by Tapash Majumder on 5/30/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
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
                              platform: .ITBL_PLATFORM_IOS,
                              appPackageName: Bundle.main.appPackageName ?? "")
    }
    
    weak var urlDelegate: IterableURLDelegate? {
        get {
            return config.urlDelegate
        } set {
            config.urlDelegate = newValue
        }
    }
    
    weak var customActionDelegate: IterableCustomActionDelegate? {
        get {
            return config.customActionDelegate
        } set {
            config.customActionDelegate = newValue
        }
    }
    
    var lastPushPayload: [AnyHashable: Any]? {
        return localStorage.getPayload(currentDate: dateProvider.currentDate)
    }
    
    var attributionInfo: IterableAttributionInfo? {
        get {
            return localStorage.getAttributionInfo(currentDate: dateProvider.currentDate)
        } set {
            let expiration = Calendar.current.date(byAdding: .hour,
                                                   value: .ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS,
                                                   to: dateProvider.currentDate)
            localStorage.save(attributionInfo: newValue, withExpiration: expiration)
        }
    }
    
    // AuthProvider Protocol
    var auth: Auth {
        return Auth(userId: userId, email: email)
    }
    
    lazy var inAppManager: IterableInAppManagerProtocolInternal = {
        self.dependencyContainer.createInAppManager(config: self.config, apiClient: self.apiClient)
    }()
    
    func register(token: Data) {
        register(token: token,
                 onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "registerToken"),
                 onFailure: IterableAPIInternal.defaultOnFailure(identifier: "registerToken"))
    }
    
    func register(token: Data, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard let appName = pushIntegrationName else {
            ITBError("registerToken: appName is nil")
            onFailure?("Not registering device token - appName must not be nil", nil)
            return
        }
        
        // Check notificationsEnabled then call register with enabled/not-not enabled
        notificationStateProvider.notificationsEnabled.onSuccess { enabled in
            self.register(token: token,
                          appName: appName,
                          pushServicePlatform: self.config.pushPlatform,
                          notificationsEnabled: enabled,
                          onSuccess: onSuccess,
                          onFailure: onFailure)
        }.onError { _ in
            self.register(token: token,
                          appName: appName,
                          pushServicePlatform: self.config.pushPlatform,
                          notificationsEnabled: false,
                          onSuccess: onSuccess,
                          onFailure: onFailure)
        }
    }
    
    @discardableResult private func register(token: Data,
                                             appName: String,
                                             pushServicePlatform: PushServicePlatform,
                                             notificationsEnabled: Bool,
                                             onSuccess: OnSuccessHandler? = nil,
                                             onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue, SendRequestError> {
        hexToken = token.hexString()
        
        return IterableAPIInternal.call(successHandler: onSuccess,
                                        andFailureHandler: onFailure,
                                        forResult: apiClient.register(hexToken: hexToken!,
                                                                      appName: appName,
                                                                      deviceId: deviceId,
                                                                      sdkVersion: localStorage.sdkVersion,
                                                                      pushServicePlatform: pushServicePlatform,
                                                                      notificationsEnabled: notificationsEnabled))
    }
    
    func disableDeviceForCurrentUser() {
        disableDeviceForCurrentUser(withOnSuccess: IterableAPIInternal.defaultOnSucess(identifier: "disableDevice"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "disableDevice"))
    }
    
    func disableDeviceForAllUsers() {
        disableDeviceForAllUsers(withOnSuccess: IterableAPIInternal.defaultOnSucess(identifier: "disableDevice"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "disableDevice"))
    }
    
    func disableDeviceForCurrentUser(withOnSuccess onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        disableDevice(forAllUsers: false, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func disableDeviceForAllUsers(withOnSuccess onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        disableDevice(forAllUsers: true, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func updateUser(_ dataFields: [AnyHashable: Any], mergeNestedObjects: Bool, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects))
    }
    
    func updateEmail(_ newEmail: String, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
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
    
    func trackPurchase(_ total: NSNumber, items: [CommerceItem]) {
        trackPurchase(total, items: items, dataFields: nil)
    }
    
    func trackPurchase(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) {
        trackPurchase(total, items: items, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPurchase"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPurchase"))
    }
    
    func trackPurchase(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.track(purchase: total, items: items, dataFields: dataFields))
    }
    
    func trackPushOpen(_ userInfo: [AnyHashable: Any]) {
        trackPushOpen(userInfo, dataFields: nil)
    }
    
    func trackPushOpen(_ userInfo: [AnyHashable: Any], dataFields: [AnyHashable: Any]?) {
        trackPushOpen(userInfo,
                      dataFields: dataFields,
                      onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPushOpen"),
                      onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen"))
    }
    
    func trackPushOpen(_ userInfo: [AnyHashable: Any], dataFields: [AnyHashable: Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        save(pushPayload: userInfo)
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            trackPushOpen(metadata.campaignId, templateId: metadata.templateId, messageId: metadata.messageId, appAlreadyRunning: false, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onFailure?("Not tracking push open - payload is not an Iterable notification, or a test/proof/ghost push", nil)
        }
    }
    
    func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) {
        trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPushOpen"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen"))
    }
    
    func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
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
                                               value: .ITBL_USER_DEFAULTS_PAYLOAD_EXPIRATION_HOURS,
                                               to: dateProvider.currentDate)
        localStorage.save(payload: payload, withExpiration: expiration)
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload) {
            if let templateId = metadata.templateId, let messageId = metadata.messageId {
                attributionInfo = IterableAttributionInfo(campaignId: metadata.campaignId, templateId: templateId, messageId: messageId)
            }
        }
    }
    
    func track(_ eventName: String) {
        track(eventName, dataFields: nil)
    }
    
    func track(_ eventName: String, dataFields: [AnyHashable: Any]?) {
        track(eventName, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "track"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "track"))
    }
    
    func track(_ eventName: String, dataFields: [AnyHashable: Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        IterableAPIInternal.call(successHandler: onSuccess,
                                 andFailureHandler: onFailure,
                                 forResult: apiClient.track(event: eventName, dataFields: dataFields))
    }
    
    func updateSubscriptions(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSucess(identifier: "updateSubscriptions"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "updateSubscriptions"),
                                 forResult: apiClient.updateSubscriptions(emailListIds, unsubscribedChannelIds: unsubscribedChannelIds, unsubscribedMessageTypeIds: unsubscribedMessageTypeIds))
    }
    
    @discardableResult func getInAppMessages(_ count: NSNumber) -> Future<SendRequestValue, SendRequestError> {
        return getInAppMessages(count, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "getMessages"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "getMessages"))
    }
    
    @discardableResult func getInAppMessages(_ count: NSNumber, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        return IterableAPIInternal.call(successHandler: onSuccess,
                                        andFailureHandler: onFailure,
                                        forResult: apiClient.getInAppMessages(count))
    }
    
    func trackInAppOpen(_ messageId: String, saveToInbox: Bool?, silentInbox: Bool?, location: String?) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppOpen"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppOpen"),
                                 forResult: apiClient.track(inAppOpen: messageId, saveToInbox: saveToInbox, silentInbox: silentInbox, location: location, deviceMetadata: deviceMetadata))
    }
    
    func trackInAppClick(_ messageId: String, saveToInbox: Bool?, silentInbox: Bool?, location: String?, clickedUrl: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppClick"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClick"),
                                 forResult: apiClient.track(inAppClick: messageId, saveToInbox: saveToInbox, silentInbox: silentInbox, location: location, clickedUrl: clickedUrl, deviceMetadata: deviceMetadata))
    }
    
    func trackInAppClose(_ message: IterableInAppMessage, location: InAppLocation = .unknown, source: InAppCloseSource = .unknown, clickedUrl: String? = nil) {
        let result = apiClient.track(inAppClose: message,
                                     inAppMessageContext: InAppMessageContext(message: message, location: location, deviceMetadata: deviceMetadata),
                                     source: source,
                                     clickedUrl: clickedUrl)
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppClose"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClose"),
                                 forResult: result)
    }
    
    func trackInAppDelivery(_ message: IterableInAppMessage) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppDelivery"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppDelivery"),
                                 forResult: apiClient.track(inAppDelivery: message.messageId,
                                                            saveToInbox: message.saveToInbox,
                                                            silentInbox: message.saveToInbox && message.trigger.type == .never,
                                                            deviceMetadata: deviceMetadata))
    }
    
    func inAppConsume(_ messageId: String) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSucess(identifier: "inAppConsume"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "inAppConsume"),
                                 forResult: apiClient.inAppConsume(messageId: messageId))
    }
    
    func inAppConsume(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource) {
        IterableAPIInternal.call(successHandler: IterableAPIInternal.defaultOnSucess(identifier: "inAppConsumeWithSource"),
                                 andFailureHandler: IterableAPIInternal.defaultOnFailure(identifier: "inAppConsumeWithSource"),
                                 forResult: apiClient.inAppConsume(message: message,
                                                                   inAppMessageContext: InAppMessageContext(message: message, location: location, deviceMetadata: deviceMetadata),
                                                                   source: source))
    }
    
    private func disableDevice(forAllUsers allUsers: Bool, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
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
    
    func showSystemNotification(_ title: String, body: String, button: String?, callbackBlock: ITEActionBlock?) {
        showSystemNotification(title, body: body, buttonLeft: button, buttonRight: nil, callbackBlock: callbackBlock)
    }
    
    func showSystemNotification(_ title: String, body: String, buttonLeft: String?, buttonRight: String?, callbackBlock: ITEActionBlock?) {
        InAppDisplayer.showSystemNotification(title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }
    
    func getAndTrackDeeplink(webpageURL: URL, callbackBlock: @escaping ITEActionBlock) {
        deeplinkManager.getAndTrackDeeplink(webpageURL: webpageURL, callbackBlock: callbackBlock)
    }
    
    @discardableResult func handleUniversalLink(_ url: URL) -> Bool {
        return deeplinkManager.handleUniversalLink(url, urlDelegate: config.urlDelegate, urlOpener: AppUrlOpener())
    }
    
    @discardableResult private static func call(successHandler onSuccess: OnSuccessHandler? = nil, andFailureHandler onFailure: OnFailureHandler? = nil, forResult result: Future<SendRequestValue, SendRequestError>) -> Future<SendRequestValue, SendRequestError> {
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
    
    private var deeplinkManager: IterableDeeplinkManager
    
    private var _email: String?
    private var _userId: String?
    
    /**
     The hex representation of this device token
     */
    private var hexToken: String?
    
    private var notificationStateProvider: NotificationStateProviderProtocol
    
    private var localStorage: LocalStorageProtocol
    
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    
    private lazy var apiClient: ApiClient = {
        ApiClient(apiKey: apiKey, authProvider: self, endPoint: .ITBL_ENDPOINT_API, networkSession: networkSession)
    }()
    
    var networkSession: NetworkSessionProtocol
    
    private var urlOpener: UrlOpenerProtocol
    
    private var dependencyContainer: DependencyContainerProtocol
    
    /**
     * Returns the push integration name for this app depending on the config options
     */
    private var pushIntegrationName: String? {
        if let pushIntegrationName = config.pushIntegrationName, let sandboxPushIntegrationName = config.sandboxPushIntegrationName {
            switch config.pushPlatform {
            case .production:
                return pushIntegrationName
            case .sandbox:
                return sandboxPushIntegrationName
            case .auto:
                return IterableAPNSUtil.isSandboxAPNS() ? sandboxPushIntegrationName : pushIntegrationName
            }
        }
        return config.pushIntegrationName
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
    
    private static func defaultOnSucess(identifier: String) -> OnSuccessHandler {
        return { data in
            if let data = data {
                ITBInfo("\(identifier) succeeded, got response: \(data)")
            } else {
                ITBInfo("\(identifier) succeeded.")
            }
        }
    }
    
    private static func defaultOnFailure(identifier: String) -> OnFailureHandler {
        return { reason, data in
            var toLog = "\(identifier) failed:"
            if let reason = reason {
                toLog += ", \(reason)"
            }
            if let data = data {
                toLog += ", got response \(data)"
            }
            ITBError(toLog)
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
    
    // Package private method. Do not call this directly.
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
        deeplinkManager = IterableDeeplinkManager()
    }
    
    func start() {
        ITBInfo()
        // sdk version
        updateSDKVersion()
        
        // check for deferred deeplinking
        checkForDeferredDeeplink()
        
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
        
        inAppManager.start()
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
    
    private func checkForDeferredDeeplink() {
        guard config.checkForDeferredDeeplink else {
            return
        }
        guard localStorage.ddlChecked == false else {
            return
        }
        
        guard let request = IterableRequestUtil.createPostRequest(forApiEndPoint: .ITBL_ENDPOINT_LINKS,
                                                                  path: .ITBL_PATH_DDL_MATCH,
                                                                  apiKey: apiKey,
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
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self.urlDelegate, inContext: context),
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
