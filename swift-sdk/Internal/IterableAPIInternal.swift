//
//
//  Created by Tapash Majumder on 5/30/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UserNotifications

final class IterableAPIInternal : NSObject, PushTrackerProtocol {
    /**
     Get the previously instantiated singleton instance of the API
     Must be initialized with `initialize:` before
     calling this class method.
     */
    static var sharedInstance : IterableAPIInternal? {
        if _sharedInstance == nil {
            ITBError("instance called before initializing API")
        }
        return _sharedInstance
    }
    
    var apiKey: String

    var email: String? {
        get {
            return _email
        } set {
            guard newValue != _email else {
                return
            }

            disableDeviceForPreviousUser()

            _email = newValue
            _userId = nil
            storeEmailAndUserId()

            enableDeviceForCurrentUser()
        }
    }

    var userId: String? {
        get {
            return _userId
        } set {
            guard newValue != _userId else {
                return
            }
            
            disableDeviceForPreviousUser()
            
            _userId = newValue
            _email = nil
            storeEmailAndUserId()
            
            enableDeviceForCurrentUser()
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
    
    var lastPushPayload: [AnyHashable : Any]? {
        return localStorage.payload
    }
    
    var attributionInfo : IterableAttributionInfo? {
        get {
            return localStorage.attributionInfo
        } set {
            let expiration = Calendar.current.date(byAdding: .hour,
                                                   value: .ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS,
                                                   to: dateProvider.currentDate)
            localStorage.save(attributionInfo: newValue, withExpiration: expiration)
        }
    }

    var inAppManager: IterableInAppManagerProtocol
    
    func register(token: Data) {
        register(token: token, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "registerToken"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "registerToken"))
    }

    func register(token: Data, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard let appName = pushIntegrationName else {
            ITBError("registerToken: appName is nil")
            onFailure?("Not registering device token - appName must not be nil", nil)
            return
        }
        
        register(token: token, appName: appName, pushServicePlatform: config.pushPlatform, onSuccess: onSuccess, onFailure: onFailure)
    }

    @discardableResult private func register(token: Data, appName: String, pushServicePlatform: PushServicePlatform, onSuccess: OnSuccessHandler? = nil, onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue> {
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            onFailure?("Both email and userId are nil", nil)
            return SendRequestError.createErroredFuture(reason: "Both email and userId are nil")
        }
        
        hexToken = (token as NSData).iteHexadecimalString()
        
        let device = UIDevice.current
        let pushServicePlatformString = IterableAPIInternal.pushServicePlatformToString(pushServicePlatform)
        
        var dataFields: [String : Any] = [
            .ITBL_DEVICE_LOCALIZED_MODEL: device.localizedModel,
            .ITBL_DEVICE_USER_INTERFACE: IterableAPIInternal.userInterfaceIdiomEnumToString(device.userInterfaceIdiom),
            .ITBL_DEVICE_SYSTEM_NAME: device.systemName,
            .ITBL_DEVICE_SYSTEM_VERSION: device.systemVersion,
            .ITBL_DEVICE_MODEL: device.model
        ]
        if let identifierForVendor = device.identifierForVendor?.uuidString {
            dataFields[.ITBL_DEVICE_ID_VENDOR] = identifierForVendor
        }
        dataFields[.ITBL_DEVICE_DEVICE_ID] = deviceId
        if let sdkVersion = localStorage.sdkVersion {
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
        
        let deviceDictionary: [String : Any] = [
            AnyHashable.ITBL_KEY_TOKEN: hexToken!,
            AnyHashable.ITBL_KEY_PLATFORM: pushServicePlatformString,
            AnyHashable.ITBL_KEY_APPLICATION_NAME: appName,
            AnyHashable.ITBL_KEY_DATA_FIELDS: dataFields
        ]
        
        var args = [AnyHashable : Any]()
        args[.ITBL_KEY_DEVICE] = deviceDictionary
        addEmailOrUserId(args: &args)
        
        if email == nil && userId != nil {
            args[.ITBL_KEY_PREFER_USER_ID] = true
        }
        
        ITBInfo("sending registerToken request with args \(args)")
        return
            createPostRequest(forPath: .ITBL_PATH_REGISTER_DEVICE_TOKEN, withBody: args)
                .map {sendRequest($0, onSuccess: onSuccess, onFailure: onFailure)} ?? SendRequestError.createErroredFuture(reason: "Couldn't create register request")
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
    
    func updateUser(_ dataFields: [AnyHashable : Any], mergeNestedObjects: Bool, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            onFailure?("Both email and userId are nil", nil)
            return
        }
        
        let mergeNested = NSNumber(value: mergeNestedObjects)
        var args = [AnyHashable: Any]()
        args[.ITBL_KEY_DATA_FIELDS] = dataFields
        args[.ITBL_KEY_MERGE_NESTED] = mergeNested
        addEmailOrUserId(args: &args)

        if let request = createPostRequest(forPath: .ITBL_PATH_UPDATE_USER, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    func updateEmail(_ newEmail: String, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard let email = email else {
            onFailure?("updateEmail should not be called with a userId. Init SDK with email instead of userId.", nil)
            return
        }
        
        let args: [String : Any] = [
            AnyHashable.ITBL_KEY_CURRENT_EMAIL: email,
            AnyHashable.ITBL_KEY_NEW_EMAIL: newEmail
        ]

        if let request = createPostRequest(forPath: .ITBL_PATH_UPDATE_EMAIL, withBody: args) {
            sendRequest(request,
                        onSuccess: { data in
                            self.email = newEmail
                            onSuccess?(data)
                        },
                        onFailure: onFailure)
        }
    }

    func trackPurchase(_ total: NSNumber, items: [CommerceItem]) {
        trackPurchase(total, items: items, dataFields: nil)
    }

    func trackPurchase(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?) {
        trackPurchase(total, items: items, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPurchase"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPurchase"))
    }

    func trackPurchase(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            onFailure?("Both email and userId are nil", nil)
            return
        }

        var itemsToSerialize = [[AnyHashable : Any]]()
        for item in items {
            itemsToSerialize.append(item.toDictionary())
        }
        
        var apiUserDict = [AnyHashable : Any]()
        addEmailOrUserId(args: &apiUserDict)
        
        let args : [String : Any]
        if let dataFields = dataFields {
            args = [
                AnyHashable.ITBL_KEY_USER: apiUserDict,
                AnyHashable.ITBL_KEY_ITEMS: itemsToSerialize,
                AnyHashable.ITBL_KEY_TOTAL: total,
                AnyHashable.ITBL_KEY_DATA_FIELDS: dataFields
            ]
        } else {
            args = [
                AnyHashable.ITBL_KEY_USER: apiUserDict,
                AnyHashable.ITBL_KEY_ITEMS: itemsToSerialize,
                AnyHashable.ITBL_KEY_TOTAL: total,
            ]
        }
        
        if let request = createPostRequest(forPath: .ITBL_PATH_COMMERCE_TRACK_PURCHASE, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    func trackPushOpen(_ userInfo: [AnyHashable : Any]) {
        trackPushOpen(userInfo, dataFields: nil)
    }
    
    func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?) {
        trackPushOpen(userInfo,
                      dataFields: dataFields,
                      onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPushOpen"),
                      onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen"))
    }

    func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        save(pushPayload: userInfo)
        if let metadata = IterableNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            trackPushOpen(metadata.campaignId, templateId: metadata.templateId, messageId: metadata.messageId, appAlreadyRunning: false, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onFailure?("Not tracking push open - payload is not an Iterable notification, or a test/proof/ghost push", nil)
        }
    }

    func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) {
        trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPushOpen"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen"))
    }

    func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        var args = [AnyHashable : Any]()

        var reqDataFields: [AnyHashable : Any]
        if let dataFields = dataFields {
            reqDataFields = dataFields
        } else {
            reqDataFields = [:]
        }
        reqDataFields["appAlreadyRunning"] = appAlreadyRunning
        args[.ITBL_KEY_DATA_FIELDS] = reqDataFields

        addEmailOrUserId(args: &args, mustExist: false)
        
        args[.ITBL_KEY_CAMPAIGN_ID] = campaignId
        if let templateId = templateId {
            args[.ITBL_KEY_TEMPLATE_ID] = templateId
        }
        if let messageId = messageId {
            args[.ITBL_KEY_MESSAGE_ID] = messageId
        }

        if let request = createPostRequest(forPath: .ITBL_PATH_TRACK_PUSH_OPEN, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    private func save(pushPayload payload: [AnyHashable : Any]) {
        let expiration = Calendar.current.date(byAdding: .hour,
                                               value: .ITBL_USER_DEFAULTS_PAYLOAD_EXPIRATION_HOURS,
                                               to: dateProvider.currentDate)
        localStorage.save(payload: payload, withExpiration: expiration)
        
        if let metadata = IterableNotificationMetadata.metadata(fromLaunchOptions: payload) {
            if let templateId = metadata.templateId, let messageId = metadata.messageId {
                attributionInfo = IterableAttributionInfo(campaignId: metadata.campaignId, templateId: templateId, messageId: messageId)
            }
        }
    }
    
    func track(_ eventName: String) {
        track(eventName, dataFields: nil)
    }

    func track(_ eventName: String, dataFields: [AnyHashable : Any]?) {
        track(eventName, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "track"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "track"))
    }

    func track(_ eventName: String, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            onFailure?("Both email and userId are nil", nil)
            return
        }

        var args = [AnyHashable : Any]()
        addEmailOrUserId(args: &args)
        args[.ITBL_KEY_EVENT_NAME] = eventName
        if let dataFields = dataFields {
            args[.ITBL_KEY_DATA_FIELDS] = dataFields
        }
        
        if let request = createPostRequest(forPath: .ITBL_PATH_TRACK, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    func updateSubscriptions(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) {
        var dictionary = [AnyHashable : Any]()
        addEmailOrUserId(args: &dictionary)
        
        if let emailListIds = emailListIds {
            dictionary[.ITBL_KEY_EMAIL_LIST_IDS] = emailListIds
        }
        if let unsubscribedChannelIds = unsubscribedChannelIds {
            dictionary[.ITBL_KEY_UNSUB_CHANNEL] = unsubscribedChannelIds
        }
        if let unsubscribedMessageTypeIds = unsubscribedMessageTypeIds {
            dictionary[.ITBL_KEY_UNSUB_MESSAGE] = unsubscribedMessageTypeIds
        }
        
        if let request = createPostRequest(forPath: .ITBL_PATH_UPDATE_SUBSCRIPTIONS, withBody: dictionary) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "updateSubscriptions"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "updateSubscriptions"))
        }
    }

    @discardableResult func spawn(inAppNotification callbackBlock:ITEActionBlock?) -> Future<Bool> {
        let promise = Promise<Bool>()

        DispatchQueue.main.async {
            InAppHelper.spawn(inAppNotification: callbackBlock, internalApi: self).onSuccess {
                promise.resolve(with: $0)
            }
        }
        
        return promise
    }

    @discardableResult func getInAppMessages(_ count: NSNumber) -> Future<SendRequestValue> {
        return getInAppMessages(count, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "getMessages"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "getMessages"))
    }

    @discardableResult func getInAppMessages(_ count: NSNumber, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) -> Future<SendRequestValue> {
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            onFailure?("Both email and userId are nil", nil)
            return SendRequestError.createErroredFuture(reason: "Both email and userId are nil")
        }

        var args : [AnyHashable : Any] = [
            AnyHashable.ITBL_KEY_COUNT: count.description,
            AnyHashable.ITBL_KEY_PLATFORM: String.ITBL_PLATFORM_IOS,
            AnyHashable.ITBL_KEY_SDK_VERSION: IterableAPI.sdkVersion
        ]

        addEmailOrUserId(args: &args)

        return createGetRequest(forPath: .ITBL_PATH_GET_INAPP_MESSAGES, withArgs: args as! [String : String]).map {
            sendRequest($0, onSuccess: onSuccess, onFailure: onFailure)
        } ?? SendRequestError.createErroredFuture(reason: "Could not create get request for getInApp")
    }

    func trackInAppOpen(_ messageId: String) {
        var args = [AnyHashable : Any]()
        addEmailOrUserId(args: &args)
        args[.ITBL_KEY_MESSAGE_ID] = messageId
        
        if let request = createPostRequest(forPath: .ITBL_PATH_TRACK_INAPP_OPEN, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppOpen"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppOpen"))
        }
    }

    func trackInAppClick(_ messageId: String, buttonIndex: String) {
        var args: [AnyHashable : Any] = [
            .ITBL_KEY_MESSAGE_ID: messageId,
            .ITBL_IN_APP_BUTTON_INDEX: buttonIndex
        ]
        addEmailOrUserId(args: &args)
        
        if let request = createPostRequest(forPath: .ITBL_PATH_TRACK_INAPP_CLICK, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppClick"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClick"))
        }
    }

    
    func trackInAppClick(_ messageId: String, buttonURL: String) {
        var args: [AnyHashable : Any] = [
            .ITBL_KEY_MESSAGE_ID: messageId,
            .ITBL_IN_APP_CLICK_URL: buttonURL
        ]
        addEmailOrUserId(args: &args)
        
        if let request = createPostRequest(forPath: .ITBL_PATH_TRACK_INAPP_CLICK, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppClick"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClick"))
        }
    }

    func inAppConsume(_ messageId: String) {
        var args: [AnyHashable : Any] = [
            .ITBL_KEY_MESSAGE_ID: messageId,
        ]
        addEmailOrUserId(args: &args)
        
        if let request = createPostRequest(forPath: .ITBL_PATH_INAPP_CONSUME, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "inAppConsume"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "inAppConsume"))
        }
    }

    func showSystemNotification(_ title: String, body: String, button: String?, callbackBlock: ITEActionBlock?) {
        showSystemNotification(title, body: body, buttonLeft: button, buttonRight: nil, callbackBlock: callbackBlock)
    }

    func showSystemNotification(_ title: String, body: String, buttonLeft: String?, buttonRight:String?, callbackBlock: ITEActionBlock?) {
        InAppHelper.showSystemNotification(title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }

    func getAndTrackDeeplink(webpageURL: URL, callbackBlock: @escaping ITEActionBlock) {
        deeplinkManager.getAndTrackDeeplink(webpageURL: webpageURL, callbackBlock: callbackBlock)
    }

    @discardableResult func handleUniversalLink(_ url: URL) -> Bool {
        return deeplinkManager.handleUniversalLink(url, urlDelegate: config.urlDelegate, urlOpener: AppUrlOpener())
    }

    func createPostRequest(forPath path: String, withBody body: [AnyHashable : Any]) -> URLRequest? {
        return IterableRequestUtil.createPostRequest(forApiEndPoint: .ITBL_ENDPOINT_API, path: path, args: [AnyHashable.ITBL_KEY_API_KEY : apiKey], body: body)
    }
    
    @discardableResult func sendRequest(_ request: URLRequest, onSuccess: OnSuccessHandler? = nil, onFailure: OnFailureHandler? = nil) -> Future<SendRequestValue> {
        return NetworkHelper.sendRequest(request, usingSession: networkSession).onSuccess { (json) in
            onSuccess?(json)
        }.onError { (error) in
            if let sendError = error as? SendRequestError {
                onFailure?(sendError.reason, sendError.data)
            } else {
                onFailure?("send request failed", nil)
            }
        }
    }
    
    // MARK: For Private and Internal Use ========================================>
    static var _sharedInstance: IterableAPIInternal?
    
    static var queue = DispatchQueue(label: "MyLockQueue")
    
    private var config: IterableConfig
    
    private let dateProvider: DateProviderProtocol
    
    private var deeplinkManager: IterableDeeplinkManager
    
    private var _email: String? = nil
    private var _userId: String? = nil
    
    /**
     The hex representation of this device token
     */
    private var hexToken: String?
    
    private var networkSessionProvider : () -> NetworkSessionProtocol
    
    private var notificationStateProvider: NotificationStateProviderProtocol
    
    private var localStorage: LocalStorageProtocol
    
    private lazy var networkSession: NetworkSessionProtocol = {
        networkSessionProvider()
    }()
    
    private var urlOpener: UrlOpenerProtocol
    
    /**
     * Returns the push integration name for this app depending on the config options
     */
    private var pushIntegrationName: String? {
        if let pushIntegrationName = config.pushIntegrationName, let sandboxPushIntegrationName = config.sandboxPushIntegrationName {
            switch(config.pushPlatform) {
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
    
    private func disableDeviceForPreviousUser() {
        guard config.autoPushRegistration == true, isEitherUserIdOrEmailSet() else {
            return
        }

        disableDeviceForCurrentUser()
    }
    
    private func enableDeviceForCurrentUser() {
        guard config.autoPushRegistration == true, isEitherUserIdOrEmailSet() else {
            return
        }
        
        notificationStateProvider.notificationsEnabled.onSuccess { (authorized) in
            if authorized {
                self.notificationStateProvider.registerForRemoteNotifications()
            }
        }
    }
    
    private func createGetRequest(forPath path: String, withArgs args: [String : String]) -> URLRequest? {
        var argsWithApiKey = args
        argsWithApiKey[AnyHashable.ITBL_KEY_API_KEY] = apiKey
        return IterableRequestUtil.createGetRequest(forApiEndPoint: .ITBL_ENDPOINT_API, path: path, args: argsWithApiKey)
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
        
        var args = [AnyHashable : Any]()
        args[.ITBL_KEY_TOKEN] = hexToken
        if !allUsers {
            addEmailOrUserId(args: &args, mustExist: false)
        }
        
        ITBInfo("sending disableToken request with args \(args)")
        if let request = createPostRequest(forPath: .ITBL_PATH_DISABLE_DEVICE, withBody:args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
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
    
    private func storeEmailAndUserId() {
        localStorage.email = _email
        localStorage.userId = _userId
    }
    
    private func retrieveEmailAndUserId() {
        _email = localStorage.email
        _userId = localStorage.userId
    }
    
    private func addEmailOrUserId(args: inout [AnyHashable : Any], mustExist: Bool = true) {
        if let email = email {
            args[.ITBL_KEY_EMAIL] = email
        } else if let userId = userId {
            args[.ITBL_KEY_USER_ID] = userId
        } else if mustExist {
            assertionFailure("Either email or userId should be set")
        }
    }

    // MARK: Initialization
    // Package private method. Do not call this directly.
    init(apiKey: String,
         launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil,
         config: IterableConfig = IterableConfig(),
         dateProvider: DateProviderProtocol = SystemDateProvider(),
         networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = URLSession(configuration: URLSessionConfiguration.default),
         notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
         inAppSynchronizer: InAppSynchronizerProtocol = InAppSynchronizer(),
         inAppDisplayer: InAppDisplayerProtocol = InAppDisplayer(),
         urlOpener: UrlOpenerProtocol = AppUrlOpener(),
         applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
         notificationCenter: NotificationCenterProtocol = NotificationCenter.default) {
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: dateProvider, logDelegate: config.logDelegate)
        ITBInfo()
        self.apiKey = apiKey
        self.config = config
        self.dateProvider = dateProvider
        self.networkSessionProvider = networkSession
        self.notificationStateProvider = notificationStateProvider
        self.localStorage = UserDefaultsLocalStorage(dateProvider: self.dateProvider)
        let inAppManager = InAppManager(synchronizer: inAppSynchronizer,
                                        displayer: inAppDisplayer,
                                        inAppDelegate: config.inAppDelegate,
                                        urlDelegate: config.urlDelegate,
                                        customActionDelegate: config.customActionDelegate,
                                        urlOpener: urlOpener,
                                        applicationStateProvider: applicationStateProvider,
                                        notificationCenter: notificationCenter,
                                        retryInterval: config.newInAppMessageCallbackIntervalInSeconds)
        self.inAppManager = inAppManager
        self.urlOpener = urlOpener
        
        // setup
        deeplinkManager = IterableDeeplinkManager()
        
        // super init
        super.init()

        // after calling super we can set self as a property
        inAppManager.internalApi = self

        // sdk version
        updateSDKVersion()
        
        // check for deferred deeplinking
        checkForDeferredDeeplink()
        
        // get email and userId from UserDefaults if present
        retrieveEmailAndUserId()
        
        if config.autoPushRegistration == true && isEitherUserIdOrEmailSet() {
            notificationStateProvider.registerForRemoteNotifications()
        }
        
        IterableAppIntegration.implementation = IterableAppIntegrationInternal(tracker: self,
                                                                       urlDelegate: config.urlDelegate,
                                                                       customActionDelegate: config.customActionDelegate,
                                                                       urlOpener: self.urlOpener)
        
        handle(launchOptions: launchOptions)
    }

    static func initialize(apiKey: String,
                           launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil,
                           config: IterableConfig = IterableConfig()) -> IterableAPIInternal {
        queue.sync {
            _sharedInstance = IterableAPIInternal(apiKey: apiKey,
                                                  launchOptions: launchOptions,
                                                  config: config
                                                  )
        }
        return _sharedInstance!
    }

    private func handle(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        guard let launchOptions = launchOptions else {
            return
        }
        if let remoteNotificationPayload = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
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
        
        guard let request = IterableRequestUtil.createPostRequest(forApiEndPoint: .ITBL_ENDPOINT_LINKS, path: .ITBL_PATH_DDL_MATCH, args: [AnyHashable.ITBL_KEY_API_KEY : apiKey], body: DeviceInfo.createDeviceInfo()) else {
            ITBError("Could not create request")
            return
        }
        
        NetworkHelper.sendRequest(request, usingSession: networkSession).onSuccess { (json) in
            self.handleDDL(json: json)
        }.onError { (error) in
            if let sendError = error as? SendRequestError, let reason = sendError.reason {
                ITBError(reason)
            } else {
                ITBError("failed to send handleDDl request")
            }
        }
    }
    
    private func handleDDL(json: [AnyHashable : Any]) {
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
    
    private func performUpgrade(lastVersion: String, newVersion: String) {
        // do upgrade things here
        // ....
        // then set new version
        localStorage.sdkVersion = newVersion
    }
    
    deinit {
        ITBInfo()
    }
}
