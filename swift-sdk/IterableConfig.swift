//
//  IterableConfig.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 6/15/18.
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
     * - parameter context:  Metadata containing the original action and the source: push or universal link.
     * - returns: Boolean value. Return true if the URL was handled to override default behavior.
     */
    @objc(handleIterableURL:context:) func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool
}

/**
 * Custom action handling delegate
 */
@objc public protocol IterableCustomActionDelegate: class {
    /**
     * Callback called for custom actions from push notifications
     * - parameter action:  `IterableAction` object containing action payload
     * - parameter context:  Metadata containing the original action and the source: push or universal link.
     * - returns: Boolean value. Reserved for future use.
     */
    @objc(handleIterableCustomAction:context:) func handle(iterableCustomAction action:IterableAction, inContext context: IterableActionContext) -> Bool
}

/**
 * Lowest level that will be logged. By default the LogLevel is set to LogLevel.info.
 */
@objc public enum LogLevel : Int {
    case debug = 1
    case info
    case error
}

/**
 * Logging Delegate.
 */
@objc public protocol IterableLogDelegate: class {
    /**
     * Log a message.
     * - parameter level: The log level.
     * - parameter message: The message to log. The message will include file, method and line of the call.
     */
    @objc(log:Message:) func log(level: LogLevel, message: String)
}

/**
 Iterable Configuration Object. Use this when initializing the API.
 */
@objcMembers
public class IterableConfig : NSObject {
    /**
     * Push integration name – used for token registration.
     * Make sure the name of this integration matches the one set up in Iterable console.
     */
    public var pushIntegrationName: String?
    
    /**
     * Push integration name for development builds – used for token registration.
     * Make sure the name of this integration matches the one set up in Iterable console.
     */
    public var sandboxPushIntegrationName: String?
    
    /**
     * APNS environment for the current build of the app.
     * Possible values: `APNS_SANDBOX`, `APNS_SANDBOX`, `AUTO`
     * Defaults to `AUTO` and detects the APNS environment automatically
     */
    public var pushPlatform: PushServicePlatform = .AUTO
    
    /// Handles Iterable actions of type 'openUrl'
    public weak var urlDelegate: IterableURLDelegate?

    /// How to handle IterableActions which are other than 'openUrl'
    public weak var customActionDelegate: IterableCustomActionDelegate?
    
    /// When set to true, IterableSDK will automatically register and deregister 
    /// notification tokens.
    public var autoPushRegistration = true
    
    /// When set to true, it will check for deferred deeplinks on first time app launch
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
}
