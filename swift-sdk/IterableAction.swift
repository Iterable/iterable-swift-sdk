//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/// `IterableAction` represents an action defined as a response to user events.
/// It is currently used in push notification actions (open push & action buttons).
@objcMembers public class IterableAction: NSObject {
    /// Open the URL or deep link
    public static let actionTypeOpenUrl = "openUrl"
    
    /// If the type is `openUrl`, the SDK will call `IterableURLDelegate` and then try to open the URL if the delegate returned false or was not set.
    /// For other types, `IterableCustomActionDelegate` will be called.
    public var type: String
    
    /// Additional data, its content depends on the action type
    public var data: String?
    
    /// The text response typed by the user
    public var userInput: String?
    
    public func isOpenUrl() -> Bool {
        type == IterableAction.actionTypeOpenUrl
    }
    
    /// Creates a new `IterableAction` from a dictionary
    /// - Parameters:
    ///     - dictionary: Dictionary containing action data
    ///
    /// - Returns: An `IterableAction` instance
    @objc(actionFromDictionary:)
    public static func action(fromDictionary dictionary: [AnyHashable: Any]) -> IterableAction? {
        IterableAction(withDictionary: dictionary)
    }
    
    @objc(actionOpenUrl:)
    public static func actionOpenUrl(fromUrlString: String) -> IterableAction? {
        IterableAction(withDictionary: ["type": IterableAction.actionTypeOpenUrl, "data": fromUrlString])
    }
    
    // MARK: - Private
    
    private init?(withDictionary dictionary: [AnyHashable: Any]) {
        guard let typeFromDict = dictionary["type"] as? String else {
            return nil
        }
        
        type = typeFromDict
        data = dictionary["data"] as? String
    }
}
