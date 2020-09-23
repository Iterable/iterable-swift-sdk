//
//  Created by Ilya Brin on 11/19/14.
//  Ported to Swift by Tapash Majumder on 7/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

@objcMembers public final class IterableAPI: NSObject {
    // Current SDK Version.
    public static let sdkVersion = "6.2.11"
    
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
    
    /// An SDK initializer taking in the Iterable Mobile API key to be utilized and the
    /// `launchOptions` passed on from the app delegate, using default SDK settings
    ///
    /// - Parameters:
    ///    - apiKey: The Iterable Mobile API key to be used with the SDK
    ///    - launchOptions: The `launchOptions` coming from `application(_:didFinishLaunchingWithOptions:)`
    ///
    /// - SeeAlso: IterableConfig
    public static func initialize(apiKey: String,
                                  launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        initialize(apiKey: apiKey, launchOptions: launchOptions, config: IterableConfig())
    }
    
    /// The big daddy of initialization. You should call this method and not call the init method directly.
    /// - parameter apiKey: Iterable API Key. This is the only required parameter.
    /// - parameter launchOptions: The launchOptions coming from application:didLaunching:withOptions
    /// - parameter config: Iterable config object.
    public static func initialize(apiKey: String,
                                  launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                                  config: IterableConfig = IterableConfig()) {
        internalImplementation = IterableAPIInternal(apiKey: apiKey, launchOptions: launchOptions, config: config)
        _ = internalImplementation?.start()
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
    public static var lastPushPayload: [AnyHashable: Any]? {
        return internalImplementation?.lastPushPayload
    }
    
    /**
     Attribution info (campaignId, messageId etc.) for last push open or app link click from an email.
     */
    public static var attributionInfo: IterableAttributionInfo? {
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
    @objc(registerToken:)
    public static func register(token: Data) {
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
    @objc(registerToken:onSuccess:OnFailure:)
    public static func register(token: Data, onSuccess: OnSuccessHandler? = nil, onFailure: OnFailureHandler? = nil) {
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
    @objc(updateUser:mergeNestedObjects:onSuccess:onFailure:)
    public static func updateUser(_ dataFields: [AnyHashable: Any],
                                  mergeNestedObjects: Bool,
                                  onSuccess: OnSuccessHandler? = nil,
                                  onFailure: OnFailureHandler? = nil) {
        internalImplementation?.updateUser(dataFields,
                                           mergeNestedObjects: mergeNestedObjects,
                                           onSuccess: onSuccess,
                                           onFailure: onFailure)
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
    @objc(updateEmail:onSuccess:onFailure:)
    public static func updateEmail(_ newEmail: String, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        internalImplementation?.updateEmail(newEmail, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Tracks a purchase
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter withTotal:       total purchase amount
     - parameter items:       list of purchased items
     
     - seeAlso: CommerceItem
     */
    @objc(trackPurchase:items:)
    public static func track(purchase withTotal: NSNumber, items: [CommerceItem]) {
        internalImplementation?.trackPurchase(withTotal, items: items)
    }
    
    /**
     Tracks a purchase with additional data.
     
     - remark: Pass in the total purchase amount and an `NSArray` of `CommerceItem`s
     
     - parameter withTotal:       total purchase amount
     - parameter items:       list of purchased items
     - parameter dataFields:  an `Dictionary` containing any additional information to save along with the event
     
     - seeAlso: CommerceItem
     */
    @objc(trackPurchase:items:dataFields:)
    public static func track(purchase withTotal: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) {
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
    @objc(trackPurchase:items:dataFields:onSuccess:onFailure:)
    public static func track(purchase withTotal: NSNumber,
                             items: [CommerceItem],
                             dataFields: [AnyHashable: Any]?,
                             onSuccess: OnSuccessHandler?,
                             onFailure: OnFailureHandler?) {
        internalImplementation?.trackPurchase(withTotal,
                                              items: items,
                                              dataFields: dataFields,
                                              onSuccess: onSuccess,
                                              onFailure: onFailure)
    }
    
    /**
     Tracks a pushOpen event with a push notification payload
     
     - remark: Pass in the `userInfo` from the push notification payload
     
     - parameter userInfo:    the push notification payload
     */
    @objc(trackPushOpen:)
    public static func track(pushOpen userInfo: [AnyHashable: Any]) {
        internalImplementation?.trackPushOpen(userInfo)
    }
    
    /**
     Tracks a pushOpen event with a push notification and optional additional data
     
     - remark: Pass in the `userInfo` from the push notification payload
     
     - parameter userInfo:    the push notification payload
     - parameter dataFields:  a `Dictionary` containing any additional information to save along with the event
     */
    @objc(trackPushOpen:dataFields:)
    public static func track(pushOpen userInfo: [AnyHashable: Any], dataFields: [AnyHashable: Any]?) {
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
    @objc(trackPushOpen:dataFields:onSuccess:onFailure:)
    public static func track(pushOpen userInfo: [AnyHashable: Any],
                             dataFields: [AnyHashable: Any]?,
                             onSuccess: OnSuccessHandler?,
                             onFailure: OnFailureHandler?) {
        internalImplementation?.trackPushOpen(userInfo,
                                              dataFields: dataFields,
                                              onSuccess: onSuccess,
                                              onFailure: onFailure)
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
    @objc(trackPushOpen:templateId:messageId:appAlreadyRunning:dataFields:)
    public static func track(pushOpen campaignId: NSNumber,
                             templateId: NSNumber?,
                             messageId: String?,
                             appAlreadyRunning: Bool,
                             dataFields: [AnyHashable: Any]?) {
        internalImplementation?.trackPushOpen(campaignId,
                                              templateId: templateId,
                                              messageId: messageId,
                                              appAlreadyRunning: appAlreadyRunning,
                                              dataFields: dataFields)
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
    @objc(trackPushOpen:templateId:messageId:appAlreadyRunning:dataFields:onSuccess:onFailure:)
    public static func track(pushOpen campaignId: NSNumber,
                             templateId: NSNumber?,
                             messageId: String?,
                             appAlreadyRunning: Bool,
                             dataFields: [AnyHashable: Any]?,
                             onSuccess: OnSuccessHandler?,
                             onFailure: OnFailureHandler?) {
        internalImplementation?.trackPushOpen(campaignId,
                                              templateId: templateId,
                                              messageId: messageId,
                                              appAlreadyRunning: appAlreadyRunning,
                                              dataFields: dataFields,
                                              onSuccess: onSuccess,
                                              onFailure: onFailure)
    }
    
    /**
     Tracks a custom event.
     
     - remark: Pass in the custom event data.
     
     - parameter eventName:   Name of the event
     */
    @objc(track:)
    public static func track(event eventName: String) {
        internalImplementation?.track(eventName)
    }
    
    /**
     Tracks a custom event.
     
     - remark: Pass in the custom event data.
     
     - parameter eventName:   Name of the event
     - parameter dataFields:  A `Dictionary` containing any additional information to save along with the event
     */
    @objc(track:dataFields:)
    public static func track(event eventName: String, dataFields: [AnyHashable: Any]?) {
        internalImplementation?.track(eventName, dataFields: dataFields)
    }
    
    /**
     Tracks a custom event.
     
     - remark: Pass in the custom event data.
     - parameters:
     - eventName:   Name of the event
     - dataFields:  A `Dictionary` containing any additional information to save along with the event
     - onSuccess:           OnSuccessHandler to invoke if the open is tracked successfully
     - onFailure:           OnFailureHandler to invoke if tracking the open fails
     */
    @objc(track:dataFields:onSuccess:onFailure:)
    public static func track(event eventName: String,
                             dataFields: [AnyHashable: Any]?,
                             onSuccess: OnSuccessHandler?,
                             onFailure: OnFailureHandler?) {
        internalImplementation?.track(eventName,
                                      dataFields: dataFields,
                                      onSuccess: onSuccess,
                                      onFailure: onFailure)
    }
    
    /**
     Updates a user's subscription preferences
     
     - Parameters:
     - emailListIds:                Email lists to subscribe to
     - unsubscribedChannelIds:      List of channels to unsubscribe from
     - unsubscribedMessageTypeIds:  List of message types to unsubscribe from
     
     - remark: passing in an empty array will clear subscription list, passing in nil will not modify the list
     */
    @objc(updateSubscriptions:unsubscribedChannelIds:unsubscribedMessageTypeIds:subscribedMessageTypeIds:campaignId:templateId:)
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
    
    // MARK: In-App Notifications
    
    /**
     Tracks an `InAppOpen` event.
     - parameter messageId:       The messageId of the notification
     */
    
    // deprecated - will be removed in version 6.3.x or above
    @available(*, deprecated, message: "Use IterableAPI.track(inAppOpen:location:) method instead.")
    @objc(trackInAppOpen:)
    public static func track(inAppOpen messageId: String) {
        internalImplementation?.trackInAppOpen(messageId)
    }
    
    /**
     Tracks an `InAppOpen` event.
     Usually you don't need to call this method explicitly. IterableSDK will call this automatically.
     Call this method only if you are using a custom view controller to render IterableInAppMessages.
     
     - parameter message:       The Iterable in-app message
     - parameter location:      The location from where this message was shown. `inbox` or `inApp`.
     */
    @objc(trackInAppOpen:location:)
    public static func track(inAppOpen message: IterableInAppMessage, location: InAppLocation = .inApp) {
        internalImplementation?.trackInAppOpen(message, location: location)
    }
    
    /**
     Tracks an `InAppClick` event
     
     - parameter messageId:       The messageId of the notification
     - parameter buttonURL:     The url of the button that was clicked
     */
    
    // deprecated - will be removed in version 6.3.x or above
    @available(*, deprecated, message: "Use IterableAPI.track(inAppClick:location:clickedUrl) instead.")
    @objc(trackInAppClick:buttonURL:)
    public static func track(inAppClick messageId: String, buttonURL: String) {
        internalImplementation?.trackInAppClick(messageId, clickedUrl: buttonURL)
    }
    
    /**
     Tracks an `InAppClick` event.
     Usually you don't need to call this method explicitly. IterableSDK will call this automatically.
     Call this method only if you are using a custom view controller to render IterableInAppMessages.
     
     - parameter message:       The message of the notification
     - parameter location:      The location from where this message was shown. `inbox` or `inApp`.
     - parameter clickedUrl:     The url of the button or link that was clicked
     */
    @objc(trackInAppClick:location:clickedUrl:)
    public static func track(inAppClick message: IterableInAppMessage, location: InAppLocation = .inApp, clickedUrl: String) {
        internalImplementation?.trackInAppClick(message, location: location, clickedUrl: clickedUrl)
    }
    
    /**
     Tracks an `InAppClose` event
     - parameter message:       The in-app message
     - parameter clickedUrl:    The url that was clicked to close the in-app. It will be `nil` when message is closed on clicking `back`.
     */
    @objc(trackInAppClose:clickedUrl:)
    public static func track(inAppClose message: IterableInAppMessage, clickedUrl: String?) {
        internalImplementation?.trackInAppClose(message, clickedUrl: clickedUrl)
    }
    
    /**
     Tracks an `InAppClose` event
     - parameter message:       The in-app message
     - parameter location:      The location from where this message was shown. `inbox` or `inApp`.
     - parameter clickedUrl:    The url that was clicked to close the in-app. It will be `nil` when message is closed on clicking `back`.
     */
    @objc(trackInAppClose:location:clickedUrl:)
    public static func track(inAppClose message: IterableInAppMessage, location: InAppLocation, clickedUrl: String?) {
        internalImplementation?.trackInAppClose(message, location: location, clickedUrl: clickedUrl)
    }
    
    /**
     Tracks an `InAppClose` event
     - parameter message:       The in-app message
     - parameter location:      The location from where this message was shown. `inbox` or `inApp`.
     - parameter source:        Source is `back` if back button was clicked to dismiss in-app message. Otherwise source is `link`.
     - parameter clickedUrl:    The url that was clicked to close the in-app. It will be `nil` when message is closed on clicking `back`.
     */
    @objc(trackInAppClose:location:source:clickedUrl:)
    public static func track(inAppClose message: IterableInAppMessage, location: InAppLocation, source: InAppCloseSource, clickedUrl: String?) {
        internalImplementation?.trackInAppClose(message, location: location, source: source, clickedUrl: clickedUrl)
    }
    
    /**
     Consumes the notification and removes it from the list of in-app messages
     
     - parameter messageId:       The messageId of the notification
     */
    
    // deprecated - will be removed in version 6.3.x or above
    @available(*, deprecated, message: "Use IterableAPI.inAppConsume(message:location:source:) instead.")
    @objc(inAppConsume:)
    public static func inAppConsume(messageId: String) {
        internalImplementation?.inAppConsume(messageId)
    }
    
    /**
     Consumes the notification and removes it from the list of in-app messages
     
     - parameter message:       The Iterable message that is being consumed
     - parameter location:      The location from where this message was shown. `inbox` or `inApp`.
     */
    @objc(inAppConsume:location:)
    public static func inAppConsume(message: IterableInAppMessage, location: InAppLocation = .inApp) {
        internalImplementation?.inAppConsume(message: message, location: location)
    }
    
    /**
     Consumes the notification and removes it from the list of in-app messages
     
     - parameter message:       The Iterable message that is being consumed
     - parameter location:      The location from where this message was shown. `inbox` or `inApp`.
     - parameter source:        The source of deletion `inboxSwipe` or `deleteButton`.
     */
    @objc(inAppConsume:location:source:)
    public static func inAppConsume(message: IterableInAppMessage, location: InAppLocation = .inApp, source: InAppDeleteSource) {
        internalImplementation?.inAppConsume(message: message, location: location, source: source)
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
    
    // deprecated - will be removed in version 6.3.x or above
    @available(*, deprecated, message: "Please use UIAlertController to show system notifications.")
    public static func showSystemNotification(withTitle title: String, body: String, button: String?, callbackBlock: ITEActionBlock?) {
        internalImplementation?.showSystemNotification(withTitle: title, body: body, buttonLeft: button, callbackBlock: callbackBlock)
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
    
    // deprecated - will be removed in version 6.3.x or above
    @available(*, deprecated, message: "Please use UIAlertController to show system notifications.")
    public static func showSystemNotification(withTitle title: String, body: String, buttonLeft: String?, buttonRight: String?, callbackBlock: ITEActionBlock?) {
        internalImplementation?.showSystemNotification(withTitle: title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }
    
    /**
     Tracks a link click and passes the redirected URL to the callback
     
     - parameter webpageURL:      the URL that was clicked
     - parameter callbackBlock:   the callback to send after the webpageURL is called
     */
    
    // deprecated - will be removed in version 6.3.x or above
    @available(*, deprecated, message: "Please use IterableAPI.handle(universalLink:) instead.")
    @objc(getAndTrackDeeplink:callbackBlock:)
    public static func getAndTrack(deeplink webpageURL: URL, callbackBlock: @escaping ITEActionBlock) {
        internalImplementation?.getAndTrack(deepLink: webpageURL, callbackBlock: callbackBlock)
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
    @objc(handleUniversalLink:)
    @discardableResult
    public static func handle(universalLink url: URL) -> Bool {
        return internalImplementation?.handleUniversalLink(url) ?? false
    }
    
    /// This will send the device attribute to the back end when registering the device.
    ///
    /// - Parameters:
    /// - name: The device attribute name
    /// - value:    The device attribute value
    @objc(setDeviceAttribute:value:)
    public static func setDeviceAttribute(name: String, value: String) {
        internalImplementation?.setDeviceAttribute(name: name, value: value)
    }
    
    /// Remove a device attribute set earlier.
    ///
    /// - Parameters:
    /// - name: The device attribute name
    @objc(removeDeviceAttribute:)
    public static func removeDeviceAttribute(name: String) {
        internalImplementation?.removeDeviceAttribute(name: name)
    }
    
    /// Use this property for getting and showing in-app messages.
    /// This property has no meaning if IterableAPI has not been initialized using
    /// IterableAPI.initialize
    /// ```
    /// - IterableAPI.inAppManager.getMessages()
    /// - IterableAPI.inAppManager.show(message: message, consume: true)
    /// ```
    public static var inAppManager: IterableInAppManagerProtocol {
        guard let internalImplementation = internalImplementation else {
            ITBError("IterableAPI is not initialized yet. In-apps will not work now.")
            assertionFailure("IterableAPI is not initialized yet. In-apps will not work now.")
            return EmptyInAppManager()
        }
        
        return internalImplementation.inAppManager
    }
    
    // MARK: Private and Internal
    
    static var internalImplementation: IterableAPIInternal?
    private override init() { super.init() }
}
