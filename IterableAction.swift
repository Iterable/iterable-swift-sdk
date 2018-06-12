//
//  IterableAction.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/**
 `IterableAction` represents an action defined as a response to user events.
 It is currently used in push notification actions (open push & action buttons).
 */
public class IterableAction : NSObject {
    /** Open the URL or deep link */
    @objc public static let actionTypeOpenUrl = "openUrl"
    /**
     * Action type
     *
     * If `IterableActionTypeOpenUrl`, the SDK will call `IterableURLDelegate` and then try to open the URL if
     * the delegate returned NO or was not set.
     *
     * For other types, `IterableCustomActionDelegate` will be called.
     */
    @objc public var type: String
    /**
     * Additional data, its content depends on the action type
     */
    @objc public var data: String?

    /** The text response typed by the user */
    @objc public var userInput: String?
    
    /**
     * Checks whether this action is of a specific type.
     * - parmeter type: Action type to match against
     * - returns: Bool indicating whether the action type matches the one passed to this method
     */
    @objc public func isOfType(_ type: String) -> Bool {
        return self.type == type
    }
    
    /**
     * Creates a new `IterableAction` from a dictionary
     * - parameter dictionary: Dictionary containing action data
     * - returns: `IterableAction` instance
     */
    @objc public static func action(fromDictionary dictionary: [AnyHashable : Any]) -> IterableAction? {
        return IterableAction(withDictionary: dictionary)
    }

    // Private
    private init?(withDictionary dictionary: [AnyHashable : Any]) {
        guard let typeFromDict = dictionary["type"] as? String else {
            return nil
        }
        self.type = typeFromDict
        self.data = dictionary["data"] as? String
    }
}
