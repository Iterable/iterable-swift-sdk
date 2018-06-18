//
//  IterableAPIConfig.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 6/15/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/**
 Iterable Configuration Object. Use this when initializing the API.
 */
@objc public class IterableAPIConfig : NSObject {
    /// How to handle IterableActions which are other than 'openUrl'
    @objc public weak var customActionDelegate: IterableCustomActionDelegate?
    
    /// Handles Iterable actions of type 'openUrl'
    @objc public weak var urlDelegate: IterableURLDelegate?
}
