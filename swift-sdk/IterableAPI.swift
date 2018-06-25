//
//  IterableApi.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 5/30/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/**
 * Custom URL handling delegate
 */
@objc public protocol IterableURLDelegate: class {
    /**
     * Callback called for a deeplink action. Return true to override default behavior
     * - parameter url:     Deeplink URL
     * - parameter action:  Original openUrl Action object
     * - returns: Boolean value. Return true if the URL was handled to override default behavior.
     */
    @objc func handleIterableURL(_ url: URL, fromAction action: IterableAction) -> Bool
}

/**
 * Custom action handling delegate
 */
@objc public protocol IterableCustomActionDelegate: class {
    /**
     * Callback called for custom actions from push notifications
     * - parameter action:  `IterableAction` object containing action payload
     * - returns: Boolean value. Reserved for future use.
     */
    @objc func handleIterableCustomAction(_ action:IterableAction) -> Bool
}

@objc public final class IterableAPI : NSObject, PushTrackerProtocol {
    // MARK: Initialization
    /// The big daddy of initialization. You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key. This is the only required parameter.
    /// - parameter launchOptions: The launchOptions coming from application:didLaunching:withOptions
    /// - parameter config: Iterable config object.
    /// - parameter email: user email for the logged in user.
    /// - parameter userId: user id for the logged in user
    /// - returns: an instance of IterableAPI
    @objc @discardableResult public static func initializeAPI(apiKey: String,
                                                              launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil,
                                                              config: IterableAPIConfig? = nil,
                                                              email: String? = nil,
                                                              userId: String? = nil) -> IterableAPI {
        return initializeAPI(apiKey: apiKey, launchOptions: launchOptions, config:config, email: email, userId:userId, dateProvider: SystemDateProvider())
    }
    
    /**
     Get the previously instantiated singleton instance of the API
     
     Must be initialized with `initializeAPI:` before
     calling this class method.
     
     - returns: the existing `IterableAPI` instance
     
     - warning: `instance` will return `nil` if called before calling `initializeAPI`
     */
    @objc public static var instance : IterableAPI? {
        if _sharedInstance == nil {
            ITBError("instance called before initializing API")
        }
        return _sharedInstance
    }
    
    @objc public static func clearInstance() {
        queue.sync {
            _sharedInstance = nil
        }
    }

    private var config: IterableAPIConfig?
    
    /**
     The apiKey that this IterableAPI is using
     */
    @objc public var apiKey: String
    
    /**
     The email of the logged in user that this IterableAPI is using
     */
    @objc public var email: String?

    /**
     The userId of the logged in user that this IterableAPI is using
     */
    @objc public var userId: String?

    @objc public weak var urlDelegate: IterableURLDelegate? {
        get {
            return config?.urlDelegate
        } set {
            config?.urlDelegate = newValue
        }
    }
    
    @objc public weak var customActionDelegate: IterableCustomActionDelegate? {
        get {
            return config?.customActionDelegate
        } set {
            config?.customActionDelegate = newValue
        }
    }
    
    /**
     The userInfo dictionary which came with last push.
     */
    @objc public var lastPushPayload: [AnyHashable : Any]? {
        return expirableValueFromUserDefaults(withKey: ITBL_USER_DEFAULTS_PAYLOAD_KEY) as? [AnyHashable : Any]
    }
    
    /**
     Attribution info (campaignId, messageId etc.) for last push open or app link click from an email.
     */
    @objc public var attributionInfo : IterableAttributionInfo? {
        get {
            return expirableValueFromUserDefaults(withKey: ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY) as? IterableAttributionInfo
        } set {
            if let value = newValue {
                let expiration = Calendar.current.date(byAdding: .hour,
                                                       value: Int(ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS),
                                                       to: dateProvider.currentDate)
                saveToUserDefaults(value: value, withKey: ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY, andExpiration: expiration)

            } else {
                UserDefaults.standard.removeObject(forKey: ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY)
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
     
     - seeAlso: PushServicePlatform
     */
    @objc public func registerToken(_ token: Data, appName: String, pushServicePlatform: PushServicePlatform) {
        registerToken(token, appName: appName, pushServicePlatform: pushServicePlatform, onSuccess: IterableAPI.defaultOnSucess(identifier: "registerToken"), onFailure: IterableAPI.defaultOnFailure(identifier: "registerToken"))
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
    @objc public func registerToken(_ token: Data, appName: String, pushServicePlatform: PushServicePlatform, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        hexToken = (token as NSData).iteHexadecimalString()

        let device = UIDevice.current
        let psp = IterableAPI.pushServicePlatformToString(pushServicePlatform)
        
        var dataFields: [String : Any] = [
            ITBL_DEVICE_LOCALIZED_MODEL: device.localizedModel,
            ITBL_DEVICE_USER_INTERFACE: IterableAPI.userInterfaceIdiomEnumToString(device.userInterfaceIdiom),
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
        } else {
            if let userId = userId {
                args = [
                    ITBL_KEY_USER_ID: userId,
                    ITBL_KEY_DEVICE: deviceDictionary
                ]
            } else {
                ITBError("Either email or userId is required.")
                args = [
                    ITBL_KEY_DEVICE: deviceDictionary
                ]
            }
        }
        
        ITBInfo("sending registerToken request with args \(args)")
        if let request = createPostRequest(forAction: ENDPOINT_REGISTER_DEVICE_TOKEN, withArgs: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    /**
     Disable this device's token in Iterable, for the current user.
     */
    @objc public func disableDeviceForCurrentUser() {
        disableDeviceForCurrentUser(withOnSuccess: IterableAPI.defaultOnSucess(identifier: "disableDevice"), onFailure: IterableAPI.defaultOnFailure(identifier: "disableDevice"))
    }

    /**
     Disable this device's token in Iterable, for all users with this device.
     */
    @objc public func disableDeviceForAllUsers() {
        disableDeviceForAllUsers(withOnSuccess: IterableAPI.defaultOnSucess(identifier: "disableDevice"), onFailure: IterableAPI.defaultOnFailure(identifier: "disableDevice"))
    }

    /**
     Disable this device's token in Iterable, for the current user, with custom completion blocks
     
     - parameter onSuccess:               OnSuccessHandler to invoke if disabling the token is successful
     - parameter onFailure:               OnFailureHandler to invoke if disabling the token fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    @objc public func disableDeviceForCurrentUser(withOnSuccess onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        disableDevice(forAllUsers: false, onSuccess: onSuccess, onFailure: onFailure)
    }

    /**
     Disable this device's token in Iterable, for all users of this device, with custom completion blocks.
     
     - parameter onSuccess:               OnSuccessHandler to invoke if disabling the token is successful
     - parameter onFailure:               OnFailureHandler to invoke if disabling the token fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    @objc public func disableDeviceForAllUsers(withOnSuccess onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        disableDevice(forAllUsers: true, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Updates the available user fields
     
     - parameters:
        - dataFields:              Data fields to store in the user profile
        - mergeNestedObjects:      Merge top level objects instead of overwriting
        - onSuccess:               OnSuccessHandler to invoke if update is successful
        - onFailure:               OnFailureHandler to invoke if update fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    @objc public func updateUser(_ dataFields: [AnyHashable : Any], mergeNestedObjects: Bool, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        let args: [String : Any]
        let mergeNested = NSNumber(value: mergeNestedObjects)
        if let email = email {
            args = [
                ITBL_KEY_EMAIL: email,
                ITBL_KEY_DATA_FIELDS: dataFields,
                ITBL_KEY_MERGE_NESTED: mergeNested
            ]
        } else if let userId = userId {
            args = [
                ITBL_KEY_USER_ID: userId,
                ITBL_KEY_DATA_FIELDS: dataFields,
                ITBL_KEY_MERGE_NESTED: mergeNested
            ]
        } else {
            args = [
                ITBL_KEY_DATA_FIELDS: dataFields,
                ITBL_KEY_MERGE_NESTED: mergeNested
            ]
            assertionFailure("expecting either userId or email to be set.")
        }

        if let request = createPostRequest(forAction: ENDPOINT_UPDATE_USER, withArgs: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    /**
     Updates the current user's email.
     
     - remark:  Also updates the current email in this IterableAPI instance if the API call was successful.
     
     - parameters:
     - newEmail:                New Email
     - onSuccess:               OnSuccessHandler to invoke if update is successful
     - onFailure:               OnFailureHandler to invoke if update fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    @objc public func updateEmail(_ newEmail: String, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard let email = email else {
            onFailure?("updateEmail should not be called with a userId. Init SDK with email instead of userId.", nil)
            return
        }
        
        let args: [String : Any] = [
            ITBL_KEY_CURRENT_EMAIL: email,
            ITBL_KEY_NEW_EMAIL: newEmail
        ]

        if let request = createPostRequest(forAction: ENDPOINT_UPDATE_EMAIL, withArgs: args) {
            sendRequest(request,
                        onSuccess: { data in
                            self.email = newEmail
                            onSuccess?(data)
                        },
                        onFailure: onFailure)
        }
    }

    /**
     Tracks a purchase
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter total:       total purchase amount
     - parameter items:       list of purchased items

     - seeAlso: CommerceItem
     */
    @objc public func trackPurchase(_ total: NSNumber, items: [CommerceItem]) {
        trackPurchase(total, items: items, dataFields: nil)
    }

    /**
     Tracks a purchase with additional data.
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter total:       total purchase amount
     - parameter items:       list of purchased items
     - parameter dataFields:  an `Dictionary` containing any additional information to save along with the event

     - seeAlso: CommerceItem
     */
    @objc public func trackPurchase(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?) {
        trackPurchase(total, items: items, dataFields: dataFields, onSuccess: IterableAPI.defaultOnSucess(identifier: "trackPurchase"), onFailure: IterableAPI.defaultOnFailure(identifier: "trackPurchase"))
    }

    /**
     Tracks a purchase with additional data and custom completion blocks.
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter total:       total purchase amount
     - parameter items:       list of purchased items
     - parameter dataFields:  an `Dictionary` containing any additional information to save along with the event
     - parameter onSuccess:   OnSuccessHandler to invoke if the purchase is tracked successfully
     - parameter onFailure:   OnFailureHandler to invoke if tracking the purchase fails

     - seeAlso: CommerceItem, OnSuccessHandler, OnFailureHandler
     */
    @objc public func trackPurchase(_ total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        var itemsToSerialize = [[AnyHashable : Any]]()
        for item in items {
            itemsToSerialize.append(item.toDictionary())
        }
        
        let apiUserDict: [AnyHashable : Any]
        if let email = email {
            apiUserDict = [
                ITBL_KEY_EMAIL: email
            ]
        } else if let userId = userId {
            apiUserDict = [
                ITBL_KEY_USER_ID : userId
            ]
        } else {
            assertionFailure("Expected email or userId")
            apiUserDict = [
                ITBL_KEY_USER_ID : NSNull()
            ]
        }
        
        let args : [String : Any]
        if let dataFields = dataFields {
            args = [
                ITBL_KEY_USER: apiUserDict,
                ITBL_KEY_ITEMS: itemsToSerialize,
                ITBL_KEY_TOTAL: total,
                ITBL_KEY_DATA_FIELDS: dataFields
            ]
        } else {
            args = [
                ITBL_KEY_USER: apiUserDict,
                ITBL_KEY_ITEMS: itemsToSerialize,
                ITBL_KEY_TOTAL: total,
            ]
        }
        
        if let request = createPostRequest(forAction: ENDPOINT_COMMERCE_TRACK_PURCHASE, withArgs: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    /**
     Tracks a pushOpen event with a push notification payload
     
     - remark: Pass in the `userInfo` from the push notification payload
     
     - parameter userInfo:    the push notification payload
     */
    @objc public func trackPushOpen(_ userInfo: [AnyHashable : Any]) {
        trackPushOpen(userInfo, dataFields: nil)
    }
    
    /**
     Tracks a pushOpen event with a push notification and optional additional data
     
     - remark: Pass in the `userInfo` from the push notification payload
     
     - parameter userInfo:    the push notification payload
     - parameter dataFields:  a `Dictionary` containing any additional information to save along with the event
     */
    @objc public func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?) {
        trackPushOpen(userInfo,
                      dataFields: dataFields,
                      onSuccess: IterableAPI.defaultOnSucess(identifier: "trackPushOpen"),
                      onFailure: IterableAPI.defaultOnFailure(identifier: "trackPushOpen"))
    }

    /**
     Tracks a pushOpen event with a push notification, optional additional data, and custom completion blocks
     
     - remark: Pass in the `userInfo` from the push notification payload
     - Parameters:
        - userInfo:    the push notification payload
        - dataFields:  a `Dictionary` containing any additional information to save along with the event
        - onSuccess:           OnSuccessHandler to invoke if the open is tracked successfully
        - onFailure:           OnFailureHandler to invoke if tracking the open fails
     
     - SeeAlso: OnSuccessHandler
     - SeeAlso: OnFailureHandler
     */
    @objc public func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        save(pushPayload: userInfo)
        if let metadata = IterableNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            trackPushOpen(metadata.campaignId, templateId: metadata.templateId, messageId: metadata.messageId, appAlreadyRunning: false, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onFailure?("Not tracking push open - payload is not an Iterable notification, or a test/proof/ghost push", nil)
        }
    }

    /**
     Tracks a pushOpen event for the specified campaign and template ids, whether the app was already running when the push was received, and optional additional data
     
     - remark: Pass in the the relevant campaign data
     - parameters:
        - campaignId:          The campaignId of the the push notification that caused this open event
        - templateId:          The templateId  of the the push notification that caused this open event
        - messageId:           The messageId  of the the push notification that caused this open event
        - appAlreadyRunning:   This will get merged into the dataFields. Whether the app is already running when the notification was received
        - dataFields:          A `Dictionary` containing any additional information to save along with the event
     */
    @objc public func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) {
        trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields, onSuccess: IterableAPI.defaultOnSucess(identifier: "trackPushOpen"), onFailure: IterableAPI.defaultOnFailure(identifier: "trackPushOpen"))
    }

    /**
     Tracks a pushOpen event for the specified campaign and template ids, whether the app was already running when the push was received, and optional additional data
     
     - remark: Pass in the the relevant campaign data
     - parameters:
     - campaignId:          The campaignId of the the push notification that caused this open event
     - templateId:          The templateId  of the the push notification that caused this open event
     - messageId:           The messageId  of the the push notification that caused this open event
     - appAlreadyRunning:   This will get merged into the dataFields. Whether the app is already running when the notification was received
     - dataFields:          A `Dictionary` containing any additional information to save along with the event
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    @objc public func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        var args: [String : Any] = [:]

        var reqDataFields: [AnyHashable : Any]
        if let dataFields = dataFields {
            reqDataFields = dataFields
        } else {
            reqDataFields = [:]
        }
        reqDataFields["appAlreadyRunning"] = appAlreadyRunning
        args[ITBL_KEY_DATA_FIELDS] = reqDataFields

        if let email = email {
            args[ITBL_KEY_EMAIL] = email
        }
        if let userId = userId {
            args[ITBL_KEY_USER_ID] = userId
        }
        args[ITBL_KEY_CAMPAIGN_ID] = campaignId
        if let templateId = templateId {
            args[ITBL_KEY_TEMPLATE_ID] = templateId
        }
        if let messageId = messageId {
            args[ITBL_KEY_MESSAGE_ID] = messageId
        }

        if let request = createPostRequest(forAction: ENDPOINT_TRACK_PUSH_OPEN, withArgs: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    /**
     Tracks a custom event.
     
     - remark: Pass in the the custom event data.
     
     - parameter eventName:   Name of the event
     */
    @objc public func track(_ eventName: String) {
        track(eventName, dataFields: nil)
    }

    /**
     Tracks a custom event.
     
     - remark: Pass in the the custom event data.
     
     - parameter eventName:   Name of the event
     - parameter dataFields:  A `Dictionary` containing any additional information to save along with the event
     */
    @objc public func track(_ eventName: String, dataFields: [AnyHashable : Any]?) {
        track(eventName, dataFields: dataFields, onSuccess: IterableAPI.defaultOnSucess(identifier: "track"), onFailure: IterableAPI.defaultOnFailure(identifier: "track"))
    }

    /**
     Tracks a custom event.
     
     - remark: Pass in the the custom event data.
     - parameters:
        - eventName:   Name of the event
        - dataFields:  A `Dictionary` containing any additional information to save along with the event
        - onSuccess:           OnSuccessHandler to invoke if the open is tracked successfully
        - onFailure:           OnFailureHandler to invoke if tracking the open fails
     */
    @objc public func track(_ eventName: String, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        let args: [String : Any]
        if let dataFields = dataFields {
            if let email = email {
                args = [
                    ITBL_KEY_EMAIL: email,
                    ITBL_KEY_EVENT_NAME: eventName,
                    ITBL_KEY_DATA_FIELDS: dataFields
                ]
            } else if let userId = userId {
                args = [
                    ITBL_KEY_USER_ID: userId,
                    ITBL_KEY_EVENT_NAME: eventName,
                    ITBL_KEY_DATA_FIELDS: dataFields
                ]
            } else {
                assertionFailure("either email or userId should be set")
                args = [
                    ITBL_KEY_USER_ID: NSNull(),
                    ITBL_KEY_EVENT_NAME: eventName,
                    ITBL_KEY_DATA_FIELDS: dataFields
                ]
            }
        } else {
            if let email = email {
                args = [
                    ITBL_KEY_EMAIL: email,
                    ITBL_KEY_EVENT_NAME: eventName,
                ]
            } else if let userId = userId {
                args = [
                    ITBL_KEY_USER_ID: userId,
                    ITBL_KEY_EVENT_NAME: eventName,
                ]
            } else {
                assertionFailure("either email or userId should be set")
                args = [
                    ITBL_KEY_USER_ID: NSNull(),
                    ITBL_KEY_EVENT_NAME: eventName,
                ]
            }
        }
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK, withArgs: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    /**
     Updates a user's subscription preferences
     
     - Parameters:
        - emailListIds:                Email lists to subscribe to
        - unsubscribedChannelIds:      List of channels to unsubscribe from
        - unsubscribedMessageTypeIds:  List of message types to unsubscribe from
     
     - remark: passing in an empty array will clear subscription list, passing in nil will not modify the list
     */
    @objc public func updateSubscriptions(_ emailListIds: [String]?, unsubscribedChannelIds: [String]?, unsubscribedMessageTypeIds: [String]?) {
        var dictionary = [String : Any]()
        addEmailOrUserId(toDictionary: &dictionary)
        
        if let emailListIds = emailListIds {
            dictionary[ITBL_KEY_EMAIL_LIST_IDS] = emailListIds
        }
        if let unsubscribedChannelIds = unsubscribedChannelIds {
            dictionary[ITBL_KEY_UNSUB_CHANNEL] = unsubscribedChannelIds
        }
        if let unsubscribedMessageTypeIds = unsubscribedMessageTypeIds {
            dictionary[ITBL_KEY_UNSUB_MESSAGE] = unsubscribedMessageTypeIds
        }
        
        if let request = createPostRequest(forAction: ENDPOINT_UPDATE_SUBSCRIPTIONS, withArgs: dictionary) {
            sendRequest(request, onSuccess: IterableAPI.defaultOnSucess(identifier: "updateSubscriptions"), onFailure: IterableAPI.defaultOnFailure(identifier: "updateSubscriptions"))
        }
    }
    
    //MARK: In-App Notifications
    /**
     Gets the list of InAppNotification and displays the next notification
     
     - parameter callbackBlock:  Callback ITEActionBlock
     
     */
    @objc public func spawn(inAppNotification callbackBlock:ITEActionBlock?) {
        let onSuccess: OnSuccessHandler = { payload in
            guard let payload = payload else {
                return
            }
            guard let dialogOptions = IterableInAppManager.getNextMessageFromPayload(payload) else {
                ITBError("No notifications found fro inApp payload \(payload)")
                return
            }
            guard let message = dialogOptions[ITERABLE_IN_APP_CONTENT] as? [AnyHashable : Any] else {
                return
            }
            guard let messageId = dialogOptions[ITBL_KEY_MESSAGE_ID] as? String else {
                return
            }
            guard let html = message[ITERABLE_IN_APP_HTML] as? String else {
                return
            }
            if html.range(of: ITERABLE_IN_APP_HREF, options: [.caseInsensitive]) == nil {
                ITBError("No href tag found in in-app html payload \(html)")
            }

            let inAppDisplaySettings = message[ITERABLE_IN_APP_DISPLAY_SETTINGS] as? [AnyHashable : Any]
            let backgroundAlpha = IterableInAppManager.getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
            let edgeInsets = IterableInAppManager.getPaddingFromPayload(inAppDisplaySettings)

            let notificationMetadata = IterableNotificationMetadata.metadata(fromInAppOptions: messageId)
            
            DispatchQueue.main.sync {
                IterableInAppManager.showIterableNotificationHTML(html, trackParams: notificationMetadata, callbackBlock: callbackBlock, backgroundAlpha: backgroundAlpha, padding: edgeInsets)
            }

            self.inAppConsume(messageId)
        }
        
        getInAppMessages(1, onSuccess: onSuccess, onFailure: IterableAPI.defaultOnFailure(identifier: "getInAppMessages"))
    }

    /**
     Gets the list of InAppMessages
     
     - parameter count:  the number of messages to fetch
     */
    @objc public func getInAppMessages(_ count: NSNumber) {
        getInAppMessages(count, onSuccess: IterableAPI.defaultOnSucess(identifier: "getMessages"), onFailure: IterableAPI.defaultOnFailure(identifier: "getMessages"))
    }

    /**
     Gets the list of InAppMessages with optional additional fields and custom completion blocks
     
     - Parameters:
        - count:  the number of messages to fetch
        - onSuccess:   OnSuccessHandler to invoke if the get call succeeds
        - onFailure:   OnFailureHandler to invoke if the get call fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    @objc public func getInAppMessages(_ count: NSNumber, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        let args: [String : String]
        if let email = email {
            args = [
                ITBL_KEY_EMAIL: email,
                ITBL_KEY_COUNT: count.description,
                ITBL_KEY_PLATFORM: ITBL_PLATFORM_IOS,
                ITBL_KEY_SDK_VERSION: "0.0.0"
            ]
        } else if let userId = userId {
            args = [
                ITBL_KEY_USER_ID: userId,
                ITBL_KEY_COUNT: count.description,
                ITBL_KEY_PLATFORM: ITBL_PLATFORM_IOS,
                ITBL_KEY_SDK_VERSION: "0.0.0"
            ]
        } else {
            assertionFailure()
            args = [
                ITBL_KEY_COUNT: count.description,
                ITBL_KEY_PLATFORM: ITBL_PLATFORM_IOS,
                ITBL_KEY_SDK_VERSION: "0.0.0"
            ]
        }
        
        if let request = createGetRequest(forAction: ENDPOINT_GET_INAPP_MESSAGES, withArgs: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    /**
     Tracks a InAppOpen event with custom completion blocks
     - parameter messageId:       The messageId of the notification
     */
    @objc public func trackInAppOpen(_ messageId: String) {
        let args: Dictionary<String, String>
        if let email = email {
            args = [ITBL_KEY_EMAIL : email,
                    ITBL_KEY_MESSAGE_ID: messageId]
        } else {
            guard let userId = userId else {
                NSLog("Either email or userId must be set")
                return
            }
            args = [ITBL_KEY_USER_ID : userId,
                    ITBL_KEY_MESSAGE_ID : messageId]
        }
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK_INAPP_OPEN, withArgs: args) {
            sendRequest(request, onSuccess: IterableAPI.defaultOnSucess(identifier: "trackInAppOpen"), onFailure: IterableAPI.defaultOnFailure(identifier: "trackInAppOpen"))
        }
    }

    /**
     Tracks a inAppClick event
     
     - parameter messageId:       The messageId of the notification
     - parameter buttonIndex:     The index of the button that was clicked
     */
    @objc public func trackInAppClick(_ messageId: String, buttonIndex: String) {
        var args: [AnyHashable : Any] = [
            ITBL_KEY_MESSAGE_ID: messageId,
            ITERABLE_IN_APP_BUTTON_INDEX: buttonIndex
        ]
        addEmailOrUserId(args: &args)
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK_INAPP_CLICK, withArgs: args) {
            sendRequest(request, onSuccess: IterableAPI.defaultOnSucess(identifier: "trackInAppClick"), onFailure: IterableAPI.defaultOnFailure(identifier: "trackInAppClick"))
        }
    }

    
    /**
     Tracks a inAppClick event
     
     - parameter messageId:       The messageId of the notification
     - parameter buttonURL:     The url of the button that was clicked
     */
    @objc public func trackInAppClick(_ messageId: String, buttonURL: String) {
        var args: [AnyHashable : Any] = [
            ITBL_KEY_MESSAGE_ID: messageId,
            ITERABLE_IN_APP_CLICK_URL: buttonURL
        ]
        addEmailOrUserId(args: &args)
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK_INAPP_CLICK, withArgs: args) {
            sendRequest(request, onSuccess: IterableAPI.defaultOnSucess(identifier: "trackInAppClick"), onFailure: IterableAPI.defaultOnFailure(identifier: "trackInAppClick"))
        }
    }

    /**
     Consumes the notification and removes it from the list of inAppMessages
     
     - parameter messageId:       The messageId of the notification
     */
    @objc public func inAppConsume(_ messageId: String) {
        var args: [AnyHashable : Any] = [
            ITBL_KEY_MESSAGE_ID: messageId,
        ]
        addEmailOrUserId(args: &args)
        
        if let request = createPostRequest(forAction: ENDPOINT_INAPP_CONSUME, withArgs: args) {
            sendRequest(request, onSuccess: IterableAPI.defaultOnSucess(identifier: "inAppConsume"), onFailure: IterableAPI.defaultOnFailure(identifier: "inAppConsume"))
        }
    }

    /**
     Displays a iOS system style notification with one button
     
     - parameters:
        - title:           the NSDictionary containing the dialog options
        - body:            the notification message body
        - button:          the text of the left button
        - callbackBlock:   the callback to send after a button on the notification is clicked
     
     - remark:            passes the string of the button clicked to the callbackBlock
     */
    @objc public func showSystemNotification(_ title: String, body: String, button: String?, callbackBlock: ITEActionBlock?) {
        showSystemNotification(title, body: body, buttonLeft: button, buttonRight: nil, callbackBlock: callbackBlock)
    }

    /**
     Displays a iOS system style notification with one button
     
     - parameters:
     - title:           the NSDictionary containing the dialog options
     - body:            the notification message body
     - buttonLeft:          the text of the left button
     - buttonRight:          the text of the right button
     - callbackBlock:   the callback to send after a button on the notification is clicked
     
     - remark:            passes the string of the button clicked to the callbackBlock
     */
    @objc public func showSystemNotification(_ title: String, body: String, buttonLeft: String?, buttonRight:String?, callbackBlock: ITEActionBlock?) {
        IterableInAppManager.showSystemNotification(title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }


    /**
     Tracks a link click and passes the redirected URL to the callback
     
     - parameter webpageURL:      the URL that was clicked
     - parameter callbackBlock:   the callback to send after the webpageURL is called
     */
    @objc public static func getAndTrackDeeplink(_ webpageURL: URL, callbackBlock: @escaping ITEActionBlock) {
        IterableDeeplinkManager.instance.getAndTrackDeeplink(webpageURL: webpageURL, callbackBlock: callbackBlock)
    }
    
    // MARK: For Private and Internal Use
    static var _sharedInstance: IterableAPI?
    
    static var queue = DispatchQueue(label: "MyLockQueue")
    
    /**
     The hex representation of this device token
     */
    var hexToken: String?
    
    // the API endpoint
    let endpoint = "https://api.iterable.com/api/"
    
    let dateProvider: DateProviderProtocol
    
    var urlSession: URLSession = {
        return URLSession(configuration: URLSessionConfiguration.default)
    } ()
    
    var encodedCharacterSet : CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+")
        return characterSet
    } ()
    
    // Package private method. Do not call this directly.
    init(apiKey: String,
         launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil,
         config: IterableAPIConfig? = nil,
         email: String? = nil,
         userId: String? = nil,
         dateProvider: DateProviderProtocol = SystemDateProvider()) {
        self.apiKey = apiKey
        self.email = email
        self.userId = userId
        self.config = config
        self.dateProvider = dateProvider
        super.init()
        
        // setup
        let actionRunner = IterableActionRunner(urlDelegate: config?.urlDelegate, customActionDelegate: config?.customActionDelegate, urlOpener: AppUrlOpener())
        IterableAppIntegration.minion = IterableAppIntegrationInternal(tracker: self, actionRunner: actionRunner, versionInfo: SystemVersionInfo())
        
        performDefaultNotificationAction(withLaunchOptions: launchOptions)
    }
}
