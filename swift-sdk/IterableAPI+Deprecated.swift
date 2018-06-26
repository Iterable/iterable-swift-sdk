//
//  IterableAPI+Deprecated.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/1/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public extension IterableAPI {
    @available(*, deprecated, message: "use IterableAPI.instance instead.")
    @objc public static func sharedInstance() -> IterableAPI? {
        if _sharedInstance == nil {
            ITBError("sharedInstance called before createSharedInstanceWithApiKey")
        }
        return _sharedInstance
    }
    
    @available(*, deprecated, message: "use IterableAPI.clearInstance() instead.")
    @objc public static func clearSharedInstance() {
        queue.sync {
            _sharedInstance = nil
        }
    }

    //MARK: Initializers, should not be used, deprecated
    @available(*, deprecated, message: "Don't call init. Use initialize method instead.")
    @objc public convenience init(withApiKey apiKey: String, email: String, launchOptions: Dictionary<AnyHashable, Any>?, useCustomLaunchOptions: Bool) {
        self.init(apiKey:apiKey, launchOptions:IterableAPI.createIterableLaunchOptions(launchOptions: launchOptions, useCustomLaunchOptions: useCustomLaunchOptions), email:email)
    }
    
    @available(*, deprecated, message: "Don't call init. Use initialize method instead.")
    @objc public convenience init(withApiKey apiKey: String, andUserId userId: String) {
        self.init(apiKey: apiKey, userId: userId)
    }
    
    @available(*, deprecated, message: "Don't call init. Use initialize method instead.")
    @objc public convenience init(withApiKey apiKey: String, andUserId userId: String, launchOptions: Dictionary<AnyHashable, Any>?) {
        self.init(apiKey:apiKey, launchOptions:IterableAPI.createIterableLaunchOptions(launchOptions: launchOptions, useCustomLaunchOptions: false), userId:userId)
    }
    
    @available(*, deprecated, message: "Don't call init. Use initialize method instead.")
    @objc public convenience init(withApiKey apiKey: String, andUserId userId: String, launchOptions: Dictionary<AnyHashable, Any>?, useCustomLaunchOptions: Bool) {
        self.init(apiKey:apiKey, launchOptions:IterableAPI.createIterableLaunchOptions(launchOptions: launchOptions, useCustomLaunchOptions: useCustomLaunchOptions), userId:userId)
    }

    //MARK: Shared instance initializers, deprecated
    @available(*, deprecated, message: "Don't call init. Use initialize method instead.")
    @objc public static func sharedInstance(withApiKey apiKey: String, andUserId userId: String, launchOptions: Dictionary<AnyHashable, Any>?) -> IterableAPI {
        return IterableAPI.initialize(apiKey:apiKey, launchOptions:IterableAPI.createIterableLaunchOptions(launchOptions: launchOptions, useCustomLaunchOptions: false), userId:userId)
    }
    
    @available(*, deprecated, message: "Don't call init. Use initialize method instead.")
    @objc public static func sharedInstance(withApiKey apiKey: String, andEmail email: String, launchOptions: Dictionary<AnyHashable, Any>?) -> IterableAPI {
        return IterableAPI.initialize(apiKey:apiKey, launchOptions:IterableAPI.createIterableLaunchOptions(launchOptions: launchOptions, useCustomLaunchOptions: false), email:email)
    }
    
    private static func createIterableLaunchOptions(launchOptions: [AnyHashable : Any]?, useCustomLaunchOptions: Bool) -> [UIApplicationLaunchOptionsKey : Any]? {
        guard let launchOptions = launchOptions else {
            return nil
        }
        
        if useCustomLaunchOptions == true {
            return [UIApplicationLaunchOptionsKey.remoteNotification : launchOptions]
        } else {
            return launchOptions as? [UIApplicationLaunchOptionsKey : Any]
        }
    }
    
}
