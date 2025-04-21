//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

/// Use this protocol to override the default inbox display behavior.
/// Please note that almost properties are `optional` which means that you don't have to
/// implement them if the default behavior works for you.
@objc public protocol IterableInboxViewControllerViewDelegate: AnyObject {
    /// View delegate must have a public `required` initializer.
    @objc init()
    
    /// By default, all messages are shown.
    /// If you want to control which messages are to be shown, return a filter here.
    /// You can see an example of how to set a custom filter in our `inbox-customization` sample app.
    @objc optional var filter: (IterableInAppMessage) -> Bool { get }
    
    /// By default, messages are sorted chronologically.
    /// If you don't want inbox messages to be sorted chronologically, return a relevant comparator here.
    /// For example, if you want the latest messages to be displayed you can do so by setting
    /// `comparator = IterableInboxViewController.DefaultComparator.descending`,
    /// You may also return any other custom comparator as per your need.
    @objc optional var comparator: (IterableInAppMessage, IterableInAppMessage) -> Bool { get }
    
    /// If you want to have multiple sections for your inbox, use a mapper which returns the section number for an inbox message.
    /// Please note that there is no need to worry about actual section numbers, section numbers are *relative*, not absolute.
    /// As long as all messages in a section are mapped to the same number things will be fine.
    /// For example, your mapper can return `4` for message1 and message2 and `5` for message3. In this case message1 and message2 will be in section 0
    /// and message3 will be in section 1 eventhough the mappings are for `4` and `5`.
    /// You can see an example of how to set a custom section mapper in our `inbox-customization` sample app.
    @objc optional var messageToSectionMapper: (IterableInAppMessage) -> Int { get }
    
    /// By default message creation time is shown as medium date and short time.
    /// Use this method to override the default display for message creation time.
    /// Return nil if you don't want to display time.
    /// For example, set `dateMapper = IterableInboxViewController.DefaultDateMapper.localizedShortDateShortTime`
    /// if you want show short date and time.
    @objc optional var dateMapper: (IterableInAppMessage) -> String? { get }
    
    /// Use this property only when you have more than one type of custom table view cells.
    /// For example, if you have inbox cells of one type to show  informational mesages,
    /// and inbox cells of another type to show discount messages.
    /// Please note that you must declare all custom nib names here.
    /// - returns: a list of all custom nib names.
    @objc optional var customNibNames: [String] { get }
    
    /// A mapper that maps an inbox message to a custom nib.
    /// This goes hand in hand with `customNibNames` property above.
    /// You can see an example of how to set a custom nib name mapper in our `inbox-customization` sample app.
    @objc optional var customNibNameMapper: (IterableInAppMessage) -> String? { get }
    
    /// Use this method to render any additional custom fields other than title, subtitle and createAt.
    /// - parameter cell: The table view cell to render
    /// - parameter message: IterableInAppMessage
    @objc optional func renderAdditionalFields(forCell cell: IterableInboxCell, withMessage message: IterableInAppMessage)
}
