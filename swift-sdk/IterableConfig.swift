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
 * This protocol allows you to override default behavior when new inApps arrive.
 */
@objc public protocol IterableInAppDelegate : class {
    /**
     * This method is called when new inApp message is available.
     * The default behavior is to `show` if you don't override this method.
     * - parameter message: `IterableInAppMessage` object containing information regarding inApp to display
     * - returns: Return `show` to show the inApp or `skip` to skip this.
     */
    @objc(onNewContent:) func onNew(message: IterableInAppMessage) -> ShowInApp
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
 Enum representing push platform; apple push notification service, production vs sandbox
 */
@objc public enum PushServicePlatform : Int {
    /** The sandbox push service */
    case sandbox
    /** The production push service */
    case production
    /** Detect automatically */
    case auto
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
    
    /// Implement this protocol to override default inApp behavior.
    /// By default, every single inApp will be shown as soon as it is available.
    /// If more than 1 inApp is available, we show the first.
    public var inAppDelegate: IterableInAppDelegate = DefaultInAppDelegate()

    /// How many seconds to wait before showing the next inApp, if there are more than one present
    public var newInAppMessageCallbackIntervalInSeconds: Double = 30.0
}
