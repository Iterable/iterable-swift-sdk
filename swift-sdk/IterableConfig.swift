//
//  Created by Tapash Majumder on 6/15/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/**
 * Custom URL handling delegate
 */
@objc public protocol IterableURLDelegate: AnyObject {
    /**
     * Callback called for a deep link action. Return true to override default behavior
     * - parameter url:     Deep link URL
     * - parameter context:  Metadata containing the original action and the source: push or universal link.
     * - returns: Boolean value. Return true if the URL was handled to override default behavior.
     */
    @objc(handleIterableURL:context:)
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool
}

/**
 * Custom action handling delegate
 */
@objc public protocol IterableCustomActionDelegate: AnyObject {
    /**
     * Callback called for custom actions from push notifications
     * - parameter action:  `IterableAction` object containing action payload
     * - parameter context:  Metadata containing the original action and the source: push or universal link.
     * - returns: Boolean value. Reserved for future use.
     */
    @objc(handleIterableCustomAction:context:)
    func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool
}

/**
 * This protocol allows you to override default behavior when new in-app messages arrive.
 */
@objc public protocol IterableInAppDelegate: AnyObject {
    /**
     * This method is called when new in-app message is available.
     * The default behavior is to `show` if you don't override this method.
     * - parameter message: `IterableInAppMessage` object containing information regarding in-app to display
     * - returns: Return `show` to show the in-app or `skip` to skip this.
     */
    @objc(onNewMessage:)
    func onNew(message: IterableInAppMessage) -> InAppShowResponse
}

/**
 * Logging Delegate.
 */
@objc public protocol IterableLogDelegate: AnyObject {
    /**
     * Log a message.
     * - parameter level: The log level.
     * - parameter message: The message to log. The message will include file, method and line of the call.
     */
    @objc(log:message:)
    func log(level: LogLevel, message: String)
}

/**
 Iterable Configuration Object. Use this when initializing the API.
 */
@objcMembers
public class IterableConfig: NSObject {
    /**
     * You don't have to set this variable. Set this value only if you are an existing Iterable customer who has already setup mobile integrations in Iterable Web UI.
     * In that case, set this variable to the push integration name that you have set for 'APNS' in Iterable Web UI.
     * To view your existing integrations, navigate to Settings > Mobile Apps
     */
    public var pushIntegrationName: String?
    
    /**
     * You don't have to set this variable. Set this value only if you are an existing Iterable customer who has already setup mobile integrations in Iterable Web UI.
     * In that case, set this variable to the push integration name that you have set for 'APNS_SANDBOX' in Iterable Web UI.
     * To view your existing integrations, navigate to Settings > Mobile Apps
     */
    public var sandboxPushIntegrationName: String?
    
    /**
     * APNS (Apple Push Notification Service) environment for the current build of the app.
     * Possible values: `production`, `sandbox`, `auto`
     * Defaults to `auto` and detects the APNS environment automatically
     */
    public var pushPlatform: PushServicePlatform = .auto
    
    /// Handles Iterable actions of type 'openUrl'
    public weak var urlDelegate: IterableURLDelegate?
    
    /// How to handle IterableActions which are other than 'openUrl'
    public weak var customActionDelegate: IterableCustomActionDelegate?
    
    /// When set to true, IterableSDK will automatically register and deregister
    /// notification tokens.
    public var autoPushRegistration = true
    
    /// When set to true, it will check for deferred deep links on first time app launch
    /// after installation from the App Store.
    public var checkForDeferredDeeplink = false
    
    /// Implement the protocol IterableLogDelegate and set it here to change logging.
    /// Out of the box you have the following
    /// 1. DefaultLogDelegate. It will use OsLog for .error, cosole for .info and no logging for debug.
    /// 2. NoneLogDelegate. No logging messages will be output.
    /// 3. AllLogDelegate. It will log everything to console.
    /// The default value is `DefaultLogDelegate`.
    /// It will log everything >= minLogLevel
    public var logDelegate: IterableLogDelegate = DefaultLogDelegate()
    
    /// Implement this protocol to override default in-app behavior.
    /// By default, every single in-app will be shown as soon as it is available.
    /// If more than 1 in-app is available, we show the first.
    public var inAppDelegate: IterableInAppDelegate = DefaultInAppDelegate()
    
    /// How many seconds to wait before showing the next in-app, if there are more than one present
    public var inAppDisplayInterval: Double = 30.0
    
    /// These are internal. Do not change
    internal var apiEndpoint = Endpoint.api
    internal var linksEndpoint = Endpoint.links
}
