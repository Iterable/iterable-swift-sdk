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
    @available(*, deprecated, message: "Don't initialize IterableAPI instance. Use createSharedInstance method instead.")
    @objc public convenience init(withApiKey apiKey: String, email: String, launchOptions: Dictionary<AnyHashable, Any>?, useCustomLaunchOptions: Bool) {
        self.init(apiKey: apiKey, email: email, userId: nil, launchOptions: launchOptions, useCustomLaunchOptions: useCustomLaunchOptions)
    }
    
    @available(*, deprecated, message: "Don't initialize IterableAPI instance. Use createSharedInstance method instead.")
    @objc public convenience init(withApiKey apiKey: String, andUserId userId: String) {
        self.init(apiKey: apiKey, userId: userId)
    }
    
    @available(*, deprecated, message: "Don't initialize IterableAPI instance. Use createSharedInstance method instead.")
    @objc public convenience init(withApiKey apiKey: String, andUserId userId: String, launchOptions: Dictionary<AnyHashable, Any>?) {
        self.init(apiKey: apiKey, userId: userId, launchOptions: launchOptions)
    }
    
    @available(*, deprecated, message: "Don't initialize IterableAPI instance. Use createSharedInstance method instead.")
    @objc public convenience init(withApiKey apiKey: String, andUserId userId: String, launchOptions: Dictionary<AnyHashable, Any>?, useCustomLaunchOptions: Bool) {
        self.init(apiKey: apiKey, userId: userId, launchOptions: launchOptions, useCustomLaunchOptions: useCustomLaunchOptions)
    }

    //MARK: Shared instance initializers, deprecated
    @available(*, deprecated, message: "Use createSharedInstance method instead.")
    @objc public static func sharedInstance(withApiKey apiKey: String, andUserId userId: String, launchOptions: Dictionary<AnyHashable, Any>?) -> IterableAPI {
        return createSharedInstance(withApiKey: apiKey, userId: userId, launchOptions: launchOptions)
    }
    
    @available(*, deprecated, message: "Use createSharedInstance method instead.")
    @objc public static func sharedInstance(withApiKey apiKey: String, andEmail email: String, launchOptions: Dictionary<AnyHashable, Any>?) -> IterableAPI {
        return createSharedInstance(withApiKey: apiKey, email: email, launchOptions: launchOptions)
    }
    
}
