//
//  IterableAPI.swift
//  swift-sdk
//
//  Created by Ilya Brin on 11/19/14.
//  Ported to Swift by Tapash Majumder on 7/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objcMembers
public final class IterableAPI : NSObject {
    // Current SDK Version.
    static let sdkVersion = "6.1.5"
    
    // MARK: Initialization
    /// You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key.
    public static func initialize(apiKey: String) {
        initialize(apiKey: apiKey, launchOptions: nil)
    }
    
    /// You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key.
    /// - parameter config: Iterable config object.
    public static func initialize(apiKey: String,
                                  config: IterableConfig) {
        initialize(apiKey: apiKey, launchOptions: nil, config: config)
    }
    
    /// You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key.
    /// - parameter launchOptions: The launchOptions coming from application:didLaunching:withOptions
    public static func initialize(apiKey: String,
                                  launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        initialize(apiKey: apiKey, launchOptions: launchOptions, config: IterableConfig())
    }
    
    /// The big daddy of initialization. You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key. This is the only required parameter.
    /// - parameter launchOptions: The launchOptions coming from application:didLaunching:withOptions
    /// - parameter config: Iterable config object.
    public static func initialize(apiKey: String,
                                  launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                  config: IterableConfig = IterableConfig()) {
        internalImplementation = IterableAPIInternal.initialize(apiKey: apiKey, launchOptions: launchOptions, config:config)
    }
    
    /**
     The email of the logged in user that this IterableAPI is using
     */
    public static var email: String? {
        get {
            return internalImplementation?.email
        } set {
            internalImplementation?.email = newValue
        }
    }
    
    /**
     The userId of the logged in user that this IterableAPI is using
     */
    public static var userId: String? {
        get {
            return internalImplementation?.userId
        } set {
            internalImplementation?.userId = newValue
        }
    }
    
    /**
     The userInfo dictionary which came with last push.
     */
    public static var lastPushPayload: [AnyHashable : Any]? {
        return internalImplementation?.lastPushPayload
    }

    /**
     Attribution info (campaignId, messageId etc.) for last push open or app link click from an email.
     */
    public static var attributionInfo : IterableAttributionInfo? {
        get {
            return internalImplementation?.attributionInfo
        } set {
            internalImplementation?.attributionInfo = newValue
        }
    }

    /**
     * Register this device's token with Iterable
     * Push integration name and platform are read from `IterableConfig`. If platform is set to `auto`, it will
     * read APNS environment from the provisioning profile and use an integration name specified in `IterableConfig`.
     - parameters:
     - token:       The token representing this device/application pair, obtained from
     `application:didRegisterForRemoteNotificationsWithDeviceToken`
     after registering for remote notifications
     */
    @objc(registerToken:) public static func register(token: Data) {
        internalImplementation?.register(token: token)
    }
    
    /**
     * Register this device's token with Iterable
     * Push integration name and platform are read from `IterableConfig`. If platform is set to `auto`, it will
     * read APNS environment from the provisioning profile and use an integration name specified in `IterableConfig`.
     - parameters:
     - token:       The token representing this device/application pair, obtained from
     `application:didRegisterForRemoteNotificationsWithDeviceToken`
     after registering for remote notifications
     - onSuccess:   OnSuccessHandler to invoke if token registration is successful
     - onFailure:   OnFailureHandler to invoke if token registration fails
     */
    @objc(registerToken:onSuccess:OnFailure:) public static func register(token: Data, onSuccess: OnSuccessHandler? = nil, onFailure: OnFailureHandler? = nil) {
        internalImplementation?.register(token: token, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Disable this device's token in Iterable, for the current user.
     */
    public static func disableDeviceForCurrentUser() {
        internalImplementation?.disableDeviceForCurrentUser()
    }
    
    /**
     Disable this device's token in Iterable, for all users with this device.
     */
    public static func disableDeviceForAllUsers() {
        internalImplementation?.disableDeviceForAllUsers()
    }
    
    /**
     Disable this device's token in Iterable, for the current user, with custom completion blocks
     
     - parameter onSuccess:               OnSuccessHandler to invoke if disabling the token is successful
     - parameter onFailure:               OnFailureHandler to invoke if disabling the token fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    public static func disableDeviceForCurrentUser(withOnSuccess onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.disableDeviceForCurrentUser(withOnSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Disable this device's token in Iterable, for all users of this device, with custom completion blocks.
     
     - parameter onSuccess:               OnSuccessHandler to invoke if disabling the token is successful
     - parameter onFailure:               OnFailureHandler to invoke if disabling the token fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    public static func disableDeviceForAllUsers(withOnSuccess onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.disableDeviceForAllUsers(withOnSuccess: onSuccess, onFailure: onFailure)
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
    @objc(updateUser:mergeNestedObjects:onSuccess:onFailure:) public static func updateUser(_ dataFields: [AnyHashable : Any], mergeNestedObjects: Bool, onSuccess: OnSuccessHandler? = nil, onFailure: OnFailureHandler? = nil) {
        internalImplementation?.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects, onSuccess: onSuccess, onFailure: onFailure)
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
    @objc(updateEmail:onSuccess:onFailure:) public static func updateEmail(_ newEmail: String, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.updateEmail(newEmail, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Tracks a purchase
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter withTotal:       total purchase amount
     - parameter items:       list of purchased items
     
     - seeAlso: CommerceItem
     */
    @objc(trackPurchase:items:) public static func track(purchase withTotal: NSNumber, items: [CommerceItem]) {
        track(purchase: withTotal, items: items, dataFields: nil)
    }

    /**
     Tracks a purchase with additional data.
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter withTotal:       total purchase amount
     - parameter items:       list of purchased items
     - parameter dataFields:  an `Dictionary` containing any additional information to save along with the event
     
     - seeAlso: CommerceItem
     */
    @objc(trackPurchase:items:dataFields:) public static func track(purchase withTotal: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?) {
        internalImplementation?.trackPurchase(withTotal, items: items, dataFields: dataFields)
    }
    
    /**
     Tracks a purchase with additional data and custom completion blocks.
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter withTotal:   total purchase amount
     - parameter items:       list of purchased items
     - parameter dataFields:  an `Dictionary` containing any additional information to save along with the event
     - parameter onSuccess:   OnSuccessHandler to invoke if the purchase is tracked successfully
     - parameter onFailure:   OnFailureHandler to invoke if tracking the purchase fails
     
     - seeAlso: CommerceItem, OnSuccessHandler, OnFailureHandler
     */
    @objc(trackPurchase:items:dataFields:onSuccess:onFailure:) public static func track(purchase withTotal: NSNumber, items: [CommerceItem], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.trackPurchase(withTotal, items: items, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Tracks a pushOpen event with a push notification payload
     
     - remark: Pass in the `userInfo` from the push notification payload
     
     - parameter userInfo:    the push notification payload
     */
    @objc(trackPushOpen:) public static func track(pushOpen userInfo: [AnyHashable : Any]) {
        track(pushOpen: userInfo, dataFields: nil)
    }
    
    /**
     Tracks a pushOpen event with a push notification and optional additional data
     
     - remark: Pass in the `userInfo` from the push notification payload
     
     - parameter userInfo:    the push notification payload
     - parameter dataFields:  a `Dictionary` containing any additional information to save along with the event
     */
    @objc(trackPushOpen:dataFields:) public static func track(pushOpen userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?) {
        internalImplementation?.trackPushOpen(userInfo, dataFields: dataFields)
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
    @objc(trackPushOpen:dataFields:onSuccess:onFailure:) public static func track(pushOpen userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.trackPushOpen(userInfo, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
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
    @objc(trackPushOpen:templateId:messageId:appAlreadyRunning:dataFields:) public static func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) {
        internalImplementation?.trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields)
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
    @objc(trackPushOpen:templateId:messageId:appAlreadyRunning:dataFields:onSuccess:onFailure:) public static func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Tracks a custom event.
     
     - remark: Pass in the the custom event data.
     
     - parameter eventName:   Name of the event
     */
    @objc(track:) public static func track(event eventName: String) {
        internalImplementation?.track(eventName)
    }
    
    /**
     Tracks a custom event.
     
     - remark: Pass in the the custom event data.
     
     - parameter eventName:   Name of the event
     - parameter dataFields:  A `Dictionary` containing any additional information to save along with the event
     */
    @objc(track:dataFields:) public static func track(event eventName: String, dataFields: [AnyHashable : Any]?) {
        internalImplementation?.track(eventName, dataFields: dataFields)
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
    @objc(track:dataFields:onSuccess:onFailure:) public static func track(event eventName: String, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.track(eventName, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Updates a user's subscription preferences
     
     - Parameters:
     - emailListIds:                Email lists to subscribe to
     - unsubscribedChannelIds:      List of channels to unsubscribe from
     - unsubscribedMessageTypeIds:  List of message types to unsubscribe from
     
     - remark: passing in an empty array will clear subscription list, passing in nil will not modify the list
     */
    @objc(updateSubscriptions:unsubscribedChannelIds:unsubscribedMessageTypeIds:subscribedMessageTypeIds:campaignIds:templateId:)
    public static func updateSubscriptions(_ emailListIds: [NSNumber]?,
                                           unsubscribedChannelIds: [NSNumber]?,
                                           unsubscribedMessageTypeIds: [NSNumber]?,
                                           subscribedMessageTypeIds: [NSNumber]?,
                                           campaignId: NSNumber?,
                                           templateId: NSNumber?) {
        internalImplementation?.updateSubscriptions(emailListIds,
                                                    unsubscribedChannelIds: unsubscribedChannelIds,
                                                    unsubscribedMessageTypeIds: unsubscribedMessageTypeIds,
                                                    subscribedMessageTypeIds: subscribedMessageTypeIds,
                                                    campaignId: campaignId,
                                                    templateId: templateId)
    }
    
    //MARK: In-App Notifications
    @available(*, unavailable, message: "In-app messages are automatically shown by SDK now. Please check our migration guide here https://github.com/iterable/swift-sdk/#migrating-in-app-messages-from-the-previous-version-of-the-sdk.")
    public static func spawnInAppNotification(_ callbackBlock:ITEActionBlock?) {
    }

    /**
     Deprecated. Gets the list of InAppMessages from the server.
     
     This is deprecated in SDK version 6.1.0.
     In-App notifications are automatically shown via `IterableInAppDelegate` methods. The SDK takes care of getting messages automatically.
     See `IterableAPI.inAppManager.getMessages()` method to get messages already fetched from the server.

     - parameter count:  the number of messages to fetch
     */
    @available(*, deprecated, message: "Use IterableAPI.inAppManager.getMessages() method instead.")
    @objc(getInAppMessages:) public static func get(inAppMessages count: NSNumber) {
        internalImplementation?.getInAppMessages(count)
    }
    
    /**
     Deprecated. Gets the list of InAppMessages with optional additional fields and custom completion blocks
     
     This is deprecated in SDK version 6.1.0.
     In-App notifications are automatically shown via `IterableInAppDelegate` methods. The SDK takes care of getting messages automatically.
     See `IterableAPI.inAppManager.getMessages()` method to get messages already fetched from the server.

     - Parameters:
     - count:  the number of messages to fetch
     - onSuccess:   OnSuccessHandler to invoke if the get call succeeds
     - onFailure:   OnFailureHandler to invoke if the get call fails
     
     - seeAlso: OnSuccessHandler
     - seeAlso: OnFailureHandler
     */
    @available(*, deprecated, message: "Use IterableAPI.inAppManager.getMessages() method instead.")
    @objc(getInAppMessages:onSucess:onFailure:) public static func get(inAppMessages count: NSNumber, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.getInAppMessages(count, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Tracks a InAppOpen event with custom completion blocks
     - parameter messageId:       The messageId of the notification
     */
    @objc(trackInAppOpen:) public static func track(inAppOpen messageId: String) {
        internalImplementation?.trackInAppOpen(messageId)
    }
    
    /**
     Tracks a inAppClick event
     
     - parameter messageId:       The messageId of the notification
     - parameter buttonIndex:     The index of the button that was clicked
     */
    @objc(trackInAppClick:buttonIndex:) public static func track(inAppClick messageId: String, buttonIndex: String) {
        internalImplementation?.trackInAppClick(messageId, buttonIndex: buttonIndex)
    }
    
    /**
     Tracks a inAppClick event
     
     - parameter messageId:       The messageId of the notification
     - parameter buttonURL:     The url of the button that was clicked
     */
    @objc(trackInAppClick:buttonURL:) public static func track(inAppClick messageId: String, buttonURL: String) {
        internalImplementation?.trackInAppClick(messageId, buttonURL: buttonURL)
    }
    
    /**
     Consumes the notification and removes it from the list of inAppMessages
     
     - parameter messageId:       The messageId of the notification
     */
    @objc(inAppConsume:) public static func inAppConsume(messageId: String) {
        internalImplementation?.inAppConsume(messageId)
    }

    /**
     Displays a iOS system style notification with one button
     
     - parameters:
     - title:           the title of the notifiation
     - body:            the notification message body
     - button:          the text of the left button
     - callbackBlock:   the callback to send after a button on the notification is clicked
     
     - remark:            passes the string of the button clicked to the callbackBlock
     */
    public static func showSystemNotification(withTitle title: String, body: String, button: String?, callbackBlock: ITEActionBlock?) {
        internalImplementation?.showSystemNotification(title, body: body, button: button, callbackBlock: callbackBlock)
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
    public static func showSystemNotification(withTitle title: String, body: String, buttonLeft: String?, buttonRight:String?, callbackBlock: ITEActionBlock?) {
        internalImplementation?.showSystemNotification(title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }
    
    /**
     Tracks a link click and passes the redirected URL to the callback
     
     - parameter webpageURL:      the URL that was clicked
     - parameter callbackBlock:   the callback to send after the webpageURL is called
     */
    @objc(getAndTrackDeeplink:callbackBlock:) public static func getAndTrack(deeplink webpageURL: URL, callbackBlock: @escaping ITEActionBlock) {
        internalImplementation?.getAndTrackDeeplink(webpageURL: webpageURL, callbackBlock: callbackBlock)
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
    @objc(handleUniversalLink:) @discardableResult public static func handle(universalLink url: URL) -> Bool {
        return internalImplementation?.handleUniversalLink(url) ?? false
    }
    
    /// Use this property for getting and showing inApp Messages.
    /// This property has no meaning if IterableAPI has not been initialized using
    /// IterableAPI.initialize
    /// ```
    /// - IterableAPI.inAppManager.getMessages()
    /// - IterableAPI.inappManager.show(message: message, consume: true)
    /// ```
    @objc public static var inAppManager: IterableInAppManagerProtocol {
        guard let internalImplementation = internalImplementation else {
            ITBError("IterableAPI is not initialized yet. InApp will not work now.")
            return EmptyInAppManager()
        }
        return internalImplementation.inAppManager
    }
    
    // MARK: Private and Internal
    static var internalImplementation: IterableAPIInternal?
    private override init() {super.init()}
}
