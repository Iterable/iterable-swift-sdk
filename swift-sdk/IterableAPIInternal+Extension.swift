//
//  IterableAPIImplementation+Extension.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

extension IterableAPIInternal {
    /**
     * Returns the push integration name for this app depending on the config options
     * @return push integration name to use
     */
    var pushIntegrationName: String? {
        if let pushIntegrationName = config.pushIntegrationName, let sandboxPushIntegrationName = config.sandboxPushIntegrationName {
            switch(config.pushPlatform) {
            case .APNS:
                return pushIntegrationName
            case .APNS_SANDBOX:
                return sandboxPushIntegrationName
            case .AUTO:
                return IterableAPNSUtil.isSandboxAPNS() ? sandboxPushIntegrationName : pushIntegrationName
            }
        }
        return config.pushIntegrationName
    }
    
    /**
     Creates an iterable session with launchOptions.
     - parameter launchOptions: from application:didFinishLaunchingWithOptions
     */
    func handle(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
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
    
    /**
     Register this device's token with Iterable
     
     - parameters:
     - token:       The token representing this device/application pair, obtained from
     `application:didRegisterForRemoteNotificationsWithDeviceToken`
     after registering for remote notifications
     - appName:     The application name, as configured in Iterable during set up of the push integration
     - pushServicePlatform:     The PushServicePlatform to use for this device; dictates whether to register this token in the sandbox or production environment
     - onSuccess:   OnSuccessHandler to invoke if token registration is successful
     - onFailure:   OnFailureHandler to invoke if token registration fails
     
     - SeeAlso: PushServicePlatform, OnSuccessHandler, OnFailureHandler
     */
    func register(token: Data, appName: String, pushServicePlatform: PushServicePlatform, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            onFailure?("Both email and userId are nil", nil)
            return
        }

        hexToken = (token as NSData).iteHexadecimalString()
        
        let device = UIDevice.current
        let psp = IterableAPIInternal.pushServicePlatformToString(pushServicePlatform)
        
        var dataFields: [String : Any] = [
            ITBL_DEVICE_LOCALIZED_MODEL: device.localizedModel,
            ITBL_DEVICE_USER_INTERFACE: IterableAPIInternal.userInterfaceIdiomEnumToString(device.userInterfaceIdiom),
            ITBL_DEVICE_SYSTEM_NAME: device.systemName,
            ITBL_DEVICE_SYSTEM_VERSION: device.systemVersion,
            ITBL_DEVICE_MODEL: device.model
        ]
        if let identifierForVendor = device.identifierForVendor?.uuidString {
            dataFields[ITBL_DEVICE_ID_VENDOR] = identifierForVendor
        }
        
        let deviceDictionary: [String : Any] = [
            ITBL_KEY_TOKEN: hexToken!,
            ITBL_KEY_PLATFORM: psp,
            ITBL_KEY_APPLICATION_NAME: appName,
            ITBL_KEY_DATA_FIELDS: dataFields
        ]
        
        var args: [String : Any]
        if let email = email {
            args = [
                ITBL_KEY_EMAIL: email,
                ITBL_KEY_DEVICE: deviceDictionary
            ]
        } else if let userId = userId {
            args = [
                ITBL_KEY_USER_ID: userId,
                ITBL_KEY_DEVICE: deviceDictionary
            ]
        } else {
            ITBError("Either email or userId is required.")
            assertionFailure("either email or userId should be set")
            args = [
                ITBL_KEY_DEVICE: deviceDictionary
            ]
        }
        
        ITBInfo("sending registerToken request with args \(args)")
        if let request = createPostRequest(forAction: ENDPOINT_REGISTER_DEVICE_TOKEN, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    @objc public func createPostRequest(forAction action: String, withBody body: [AnyHashable : Any]) -> URLRequest? {
        return IterableRequestUtil.createPostRequest(forApiEndPoint: ITBConsts.apiEndpoint, path: action, args: [ITBL_KEY_API_KEY : apiKey], body: body)
    }
    
    func createGetRequest(forAction action: String, withArgs args: [String : String]) -> URLRequest? {
        var argsWithApiKey = args
        argsWithApiKey[ITBL_KEY_API_KEY] = apiKey
        return IterableRequestUtil.createGetRequest(forApiEndPoint: ITBConsts.apiEndpoint, path: action, args: argsWithApiKey)
    }
    
    func addEmailOrUserId(args: inout [AnyHashable : Any]) {
        if let email = email {
            args[ITBL_KEY_EMAIL] = email
        } else if let userId = userId {
            args[ITBL_KEY_USER_ID] = userId
        } else {
            assertionFailure("Either email or userId should be set")
        }
    }
    
    @objc public func sendPush(toEmail email: String, withCampaignId campaignId: Int, withOnSuccess onSuccess: OnSuccessHandler? = nil, withOnFailure onFailure: OnFailureHandler? = nil) {
        let args: [String: Any] = [
            ITBL_KEY_RECIPIENT_EMAIL: email,
            ITBL_KEY_CAMPAIGN_ID: campaignId
        ]
       if let request = createPostRequest(forAction: ENDPOINT_PUSH_TARGET, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
       } else {
            onFailure?("couldn't create request", nil)
        }
    }

    @objc public func sendInApp(toEmail email: String, withCampaignId campaignId: Int, withOnSuccess onSuccess: OnSuccessHandler? = nil, withOnFailure onFailure: OnFailureHandler? = nil) {
        let args: [String: Any] = [
            ITBL_KEY_RECIPIENT_EMAIL: email,
            ITBL_KEY_CAMPAIGN_ID: campaignId
        ]
        if let request = createPostRequest(forAction: ENDPOINT_IN_APP_TARGET, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onFailure?("couldn't create request", nil)
        }
    }

    @objc public func getCampaigns(withOnSuccess onSuccess: OnSuccessHandler?, withOnFailure onFailure: OnFailureHandler?) {
        guard let request = createGetRequest(forAction: "campaigns", withArgs: [:]) else {
            ITBError("Couldn't create get request for campaigns")
            onFailure?("couldn't create get request", nil)
            return
        }
        sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @objc public func encodeURLParam(_ paramValue: String?) -> String? {
        guard let paramValue = paramValue else {
            return nil
        }
        return paramValue.addingPercentEncoding(withAllowedCharacters: encodedCharacterSet)
    }
    
    @objc public static func dictToJson(_ dict: [AnyHashable : Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch (let error) {
            ITBError("dictToJson failed: \(error.localizedDescription)")
            return nil
        }
    }

    /**
     Executes the given `request`, attaching success and failure handlers.
     
     A request is considered successful as long as it does not meet any of the criteria outlined below:
     - there is no response
     - the server responds with a non-OK status
     - the server responds with a string that can not be parsed into JSON
     - the server responds with a string that can be parsed into JSON, but is not a dictionary
     
     - parameter request:     A `URLRequest` with the request to execute.
     - parameter onSuccess:   A closure to execute if the request is successful. It should accept one argument, an `Dictionary` of the response.
     - parameter onFailure:   A closure to execute if the request fails. It should accept two arguments: an `String` containing the reason this request failed, and an `Data` containing the raw response.
     */
    @objc public func sendRequest(_ request: URLRequest, onSuccess: OnSuccessHandler? = nil, onFailure: OnFailureHandler? = nil) {
        NetworkHelper.sendRequest(request, usingSession: networkSession).observe { (result) in
            switch result {
            case .value(let json):
                onSuccess?(json)
                print()
            case .error(let failureInfo):
                onFailure?(failureInfo.errorMessage, failureInfo.data)
            }
        }
    }

    static func defaultOnSucess(identifier: String) -> OnSuccessHandler {
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
                toLog += ", got response \(data)"
            }
            ITBError(toLog)
        }
    }
    
    func save(pushPayload payload: [AnyHashable : Any]) {
        let expiration = Calendar.current.date(byAdding: .hour,
                                               value: Int(ITBConsts.UserDefaults.payloadExpirationHours),
                                               to: dateProvider.currentDate)
        saveToUserDefaults(value: payload, withKey: ITBConsts.UserDefaults.payloadKey, andExpiration: expiration)

        if let metadata = IterableNotificationMetadata.metadata(fromLaunchOptions: payload) {
            if let templateId = metadata.templateId, let messageId = metadata.messageId {
                attributionInfo = IterableAttributionInfo(campaignId: metadata.campaignId, templateId: templateId, messageId: messageId)
            }
        }
    }
    
    func saveToUserDefaults(value: Any, withKey key: String, andExpiration expiration: Date?) {
        let encodedObject = NSKeyedArchiver.archivedData(withRootObject: value)
        let toSave: [String: Any]
        if let expiration = expiration {
            toSave = [ITBConsts.UserDefaults.objectTag : encodedObject,
                      ITBConsts.UserDefaults.expirationTag : expiration]
        } else {
            toSave = [ITBConsts.UserDefaults.objectTag : encodedObject]
        }
        UserDefaults.standard.set(toSave, forKey: key)
    }
    
    func expirableValueFromUserDefaults(withKey key: String) -> Any? {
        guard let saved = UserDefaults.standard.dictionary(forKey: key) else {
            return nil
        }
        guard let encodedObject = saved[ITBConsts.UserDefaults.objectTag] as? Data else {
            return nil
        }
        guard let value = NSKeyedUnarchiver.unarchiveObject(with: encodedObject) else {
            return nil
        }
        guard let expiration = saved[ITBConsts.UserDefaults.expirationTag] as? Date else {
            // note if expiration is nil return the value
            return value
        }

        if expiration.timeIntervalSinceReferenceDate > dateProvider.currentDate.timeIntervalSinceReferenceDate {
            return value
        } else {
            return nil
        }
    }
    
    /**
     Converts a PushServicePlatform into a NSString recognized by Iterable
     
     - parameter pushServicePlatform: the PushServicePlatform
     
     - returns: an NSString that the Iterable backend can understand
     */
    @objc public static func pushServicePlatformToString(_ pushServicePlatform: PushServicePlatform) -> String {
        switch pushServicePlatform {
        case .APNS:
            return ITBL_KEY_APNS
        case .APNS_SANDBOX:
            return ITBL_KEY_APNS_SANDBOX
        case .AUTO:
            return IterableAPNSUtil.isSandboxAPNS() ? ITBL_KEY_APNS_SANDBOX : ITBL_KEY_APNS
        }
    }
    
    @objc public static func userInterfaceIdiomEnumToString(_ idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone:
            return ITBL_KEY_PHONE
        case .pad:
            return ITBL_KEY_PAD
        default:
            return ITBL_KEY_UNSPECIFIED
        }
    }
    
    func disableDevice(forAllUsers allUsers: Bool, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
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
        
        var args: [String : Any] = [ITBL_KEY_TOKEN : hexToken]
        if !allUsers {
            if let email = email {
                args = [
                    ITBL_KEY_EMAIL : email,
                    ITBL_KEY_TOKEN : hexToken
                ]
            } else if let userId = userId {
                args = [
                    ITBL_KEY_USER_ID : userId,
                    ITBL_KEY_TOKEN : hexToken
                ]
            }
        }

        ITBInfo("sending disableToken request with args \(args)")
        if let request = createPostRequest(forAction: ENDPOINT_DISABLE_DEVICE, withBody:args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    func addEmailOrUserId(toDictionary dictionary: inout [String : Any]) {
        if let email = email {
            dictionary[ITBL_KEY_EMAIL] = email
        } else if let userId = userId {
            dictionary[ITBL_KEY_USER_ID] = userId
        }
        assertionFailure("either email or userId should be set")
    }
    
    func storeEmailAndUserId() {
        UserDefaults.standard.set(_email, forKey: ITBConsts.UserDefaults.emailKey)
        UserDefaults.standard.set(_userId, forKey: ITBConsts.UserDefaults.userIdKey)
    }
    
    func retrieveEmailAndUserId() {
        _email = UserDefaults.standard.string(forKey: ITBConsts.UserDefaults.emailKey)
        _userId = UserDefaults.standard.string(forKey: ITBConsts.UserDefaults.userIdKey)
    }
    
    // Internal Only used in unit tests.
    @discardableResult static func initialize(apiKey: String,
                                                 launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil,
                                                 config: IterableConfig = IterableConfig(),
                                                 dateProvider: DateProviderProtocol = SystemDateProvider(),
                                                 networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = URLSession(configuration: URLSessionConfiguration.default)) -> IterableAPIInternal {
        queue.sync {
            _sharedInstance = IterableAPIInternal(apiKey: apiKey, config: config, dateProvider: dateProvider, networkSession: networkSession)
        }
        return _sharedInstance!
    }
}
