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
    
    /// When set to true, IterableSDK will automatically register and deregister for
    /// notification tokens.
    public var autoPushRegistration = true
}
