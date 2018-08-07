//
//
//  Created by Tapash Majumder on 5/30/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public final class IterableAPIInternal : NSObject, PushTrackerProtocol {
    // MARK: Initialization

    /// You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key.
    /// - returns: an instance of IterableAPIImplementation
    @objc @discardableResult public static func initialize(apiKey: String) -> IterableAPIInternal {
        return initialize(apiKey: apiKey, config:IterableConfig())
    }

    /// You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key.
    /// - parameter config: Iterable config object.
    /// - returns: an instance of IterableAPIImplementation
    @objc @discardableResult public static func initialize(apiKey: String,
                                                           config: IterableConfig) -> IterableAPIInternal {
        return initialize(apiKey: apiKey, launchOptions: nil, config:config)
    }

    /**
     Get the previously instantiated singleton instance of the API
     
     Must be initialized with `initialize:` before
     calling this class method.
     
     - returns: the existing `IterableAPIImplementation` instance
     
     - warning: `instance` will return `nil` if called before calling `initialize`
     */
    @objc public static var sharedInstance : IterableAPIInternal? {
        if _sharedInstance == nil {
            ITBError("instance called before initializing API")
        }
        return _sharedInstance
    }
    
    /**
     The apiKey that this IterableAPIImplementation is using
     */
    @objc public var apiKey: String
    
    /**
     The email of the logged in user that this IterableAPIImplementation is using
     */
    @objc public var email: String? {
        get {
            return _email
        } set {
            _email = newValue
            _userId = nil
            storeEmailAndUserId()
        }
    }

    /**
     The userId of the logged in user that this IterableAPIImplementation is using
     */
    @objc public var userId: String? {
        get {
            return _userId
        } set {
            _userId = newValue
            _email = nil
            storeEmailAndUserId()
        }
    }

    @objc public weak var urlDelegate: IterableURLDelegate? {
        get {
            return config.urlDelegate
        } set {
            config.urlDelegate = newValue
        }
    }
    
    @objc public weak var customActionDelegate: IterableCustomActionDelegate? {
        get {
            return config.customActionDelegate
        } set {
            config.customActionDelegate = newValue
        }
    }
    
    /**
     The userInfo dictionary which came with last push.
     */
    @objc public var lastPushPayload: [AnyHashable : Any]? {
        return expirableValueFromUserDefaults(withKey: ITBConsts.UserDefaults.payloadKey) as? [AnyHashable : Any]
    }
    
    /**
     Attribution info (campaignId, messageId etc.) for last push open or app link click from an email.
     */
    @objc public var attributionInfo : IterableAttributionInfo? {
        get {
            return expirableValueFromUserDefaults(withKey: ITBConsts.UserDefaults.attributionInfoKey) as? IterableAttributionInfo
        } set {
            if let value = newValue {
                let expiration = Calendar.current.date(byAdding: .hour,
                                                       value: Int(ITBConsts.UserDefaults.attributionInfoExpirationHours),
                                                       to: dateProvider.currentDate)
                saveToUserDefaults(value: value, withKey: ITBConsts.UserDefaults.attributionInfoKey, andExpiration: expiration)

            } else {
                UserDefaults.standard.removeObject(forKey: ITBConsts.UserDefaults.attributionInfoKey)
            }
        }
    }

    /**
     * Register this device's token with Iterable
     * Push integration name and platform are read from `IterableConfig`. If platform is set to `AUTO`, it will
     * read APNS environment from the provisioning profile and use an integration name specified in `IterableConfig`.
     - parameters:
     - token:       The token representing this device/application pair, obtained from
     `application:didRegisterForRemoteNotificationsWithDeviceToken`
     after registering for remote notifications
     */
    @objc(registerToken:) public func register(token: Data) {
        register(token: token, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "registerToken"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "registerToken"))
    }

    /**
     * Register this device's token with Iterable
     * Push integration name and platform are read from `IterableConfig`. If platform is set to `AUTO`, it will
     * read APNS environment from the provisioning profile and use an integration name specified in `IterableConfig`.
     - parameters:
     - token:       The token representing this device/application pair, obtained from
                    `application:didRegisterForRemoteNotificationsWithDeviceToken`
                    after registering for remote notifications
     - onSuccess:   OnSuccessHandler to invoke if token registration is successful
     - onFailure:   OnFailureHandler to invoke if token registration fails
     */
    @objc(registerToken:onSuccess:OnFailure:) public func register(token: Data, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard let appName = pushIntegrationName else {
            ITBError("registerToken: appName is nil")
            onFailure?("Not registering device token - appName must not be nil", nil)
            return
        }
        
        register(token: token, appName: appName, pushServicePlatform: config.pushPlatform, onSuccess: onSuccess, onFailure: onFailure)
    }

    /**
     Disable this device's token in Iterable, for the current user.
     */
    @objc public func disableDeviceForCurrentUser() {
        disableDeviceForCurrentUser(withOnSuccess: IterableAPIInternal.defaultOnSucess(identifier: "disableDevice"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "disableDevice"))
    }

    /**
     Disable this device's token in Iterable, for all users with this device.
     */
    @objc public func disableDeviceForAllUsers() {
        disableDeviceForAllUsers(withOnSuccess: IterableAPIInternal.defaultOnSucess(identifier: "disableDevice"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "disableDevice"))
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
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            return
        }
        
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

        if let request = createPostRequest(forAction: ENDPOINT_UPDATE_USER, withBody: args) {
            sendRequest(request, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    /**
     Updates the current user's email.
     
     - remark:  Also updates the current email in this IterableAPIImplementation instance if the API call was successful.
     
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

        if let request = createPostRequest(forAction: ENDPOINT_UPDATE_EMAIL, withBody: args) {
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
        trackPurchase(total, items: items, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPurchase"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPurchase"))
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
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            return
        }

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
        
        if let request = createPostRequest(forAction: ENDPOINT_COMMERCE_TRACK_PURCHASE, withBody: args) {
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
                      onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPushOpen"),
                      onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen"))
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
        trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackPushOpen"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackPushOpen"))
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

        if let request = createPostRequest(forAction: ENDPOINT_TRACK_PUSH_OPEN, withBody: args) {
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
        track(eventName, dataFields: dataFields, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "track"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "track"))
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
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            return
        }

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
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK, withBody: args) {
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
        
        if let request = createPostRequest(forAction: ENDPOINT_UPDATE_SUBSCRIPTIONS, withBody: dictionary) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "updateSubscriptions"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "updateSubscriptions"))
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
                ITBError("No notifications found for inApp payload \(payload)")
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
            guard html.range(of: ITERABLE_IN_APP_HREF, options: [.caseInsensitive]) != nil else {
                ITBError("No href tag found in in-app html payload \(html)")
                self.inAppConsume(messageId)
                return
            }

            let inAppDisplaySettings = message[ITERABLE_IN_APP_DISPLAY_SETTINGS] as? [AnyHashable : Any]
            let backgroundAlpha = IterableInAppManager.getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
            let edgeInsets = IterableInAppManager.getPaddingFromPayload(inAppDisplaySettings)

            let notificationMetadata = IterableNotificationMetadata.metadata(fromInAppOptions: messageId)
            
            DispatchQueue.main.async {
                let opened = IterableInAppManager.showIterableNotificationHTML(html, trackParams: notificationMetadata, callbackBlock: callbackBlock, backgroundAlpha: backgroundAlpha, padding: edgeInsets)
                if opened {
                    self.inAppConsume(messageId)
                }
            }
        }
        
        getInAppMessages(1, onSuccess: onSuccess, onFailure: IterableAPIInternal.defaultOnFailure(identifier: "getInAppMessages"))
    }

    /**
     Gets the list of InAppMessages
     
     - parameter count:  the number of messages to fetch
     */
    @objc public func getInAppMessages(_ count: NSNumber) {
        getInAppMessages(count, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "getMessages"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "getMessages"))
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
        guard email != nil || userId != nil else {
            ITBError("Both email and userId are nil")
            return
        }

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
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK_INAPP_OPEN, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppOpen"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppOpen"))
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
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK_INAPP_CLICK, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppClick"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClick"))
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
        
        if let request = createPostRequest(forAction: ENDPOINT_TRACK_INAPP_CLICK, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "trackInAppClick"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "trackInAppClick"))
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
        
        if let request = createPostRequest(forAction: ENDPOINT_INAPP_CONSUME, withBody: args) {
            sendRequest(request, onSuccess: IterableAPIInternal.defaultOnSucess(identifier: "inAppConsume"), onFailure: IterableAPIInternal.defaultOnFailure(identifier: "inAppConsume"))
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
        _sharedInstance?.deeplinkManager.getAndTrackDeeplink(webpageURL: webpageURL, callbackBlock: callbackBlock)
    }

    /**
     * Handles a Universal Link
     * For Iterable links, it will track the click and retrieve the original URL,
     * pass it to `IterableURLDelegate` for handling
     * If it's not an Iterable link, it just passes the same URL to `IterableURLDelegate`
     *
     - parameter url: the URL obtained from `UserActivity.webpageURL`
     - returns: true if it is an Iterable link, or the value returned from `IterableURLDelegate` otherwise
     */
    @objc @discardableResult public func handleUniversalLink(_ url: URL) -> Bool {
        return deeplinkManager.handleUniversalLink(url, urlDelegate: config.urlDelegate, urlOpener: AppUrlOpener())
    }
    
    // MARK: For Private and Internal Use ========================================>
    
    var config: IterableConfig
    var deeplinkManager: IterableDeeplinkManager
    
    var _email: String? = nil
    var _userId: String? = nil
    
    static var _sharedInstance: IterableAPIInternal?
    
    static var queue = DispatchQueue(label: "MyLockQueue")
    
    /**
     The hex representation of this device token
     */
    var hexToken: String?
    
    let dateProvider: DateProviderProtocol
    
    private var networkSessionProvider : () -> NetworkSessionProtocol
    
    lazy var networkSession: NetworkSessionProtocol = {
        networkSessionProvider()
    }()
    
    var encodedCharacterSet : CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+")
        return characterSet
    } ()
    
    // Package private method. Do not call this directly.
    init(apiKey: String,
         launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil,
         config: IterableConfig = IterableConfig(),
         dateProvider: DateProviderProtocol = SystemDateProvider(),
         networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = URLSession(configuration: URLSessionConfiguration.default)) {
        self.apiKey = apiKey
        self.config = config
        self.dateProvider = dateProvider
        self.networkSessionProvider = networkSession
        
        // setup
        deeplinkManager = IterableDeeplinkManager()
        
        // super init
        super.init()
        
        // Fix for NSArchiver bug
        NSKeyedUnarchiver.setClass(IterableAttributionInfo.self, forClassName: "IterableAttributionInfo")

        // get email and userId from UserDefaults if present
        retrieveEmailAndUserId()
        
        IterableAppIntegration.implementation = IterableAppIntegrationInternal(tracker: self,
                                                                       versionInfo: SystemVersionInfo(),
                                                                       urlDelegate: config.urlDelegate,
                                                                       customActionDelegate: config.customActionDelegate,
                                                                       urlOpener: AppUrlOpener())
        
        handle(launchOptions: launchOptions)
    }
}
