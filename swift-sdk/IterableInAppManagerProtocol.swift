//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableInAppManagerProtocol {
    /// Turn on/off automatic displaying of in-apps
    /// - remark: the default value is `false`
    /// - remark: if auto displaying is turned on, the SDK will also immediately retrieve and process in-apps
    var isAutoDisplayPaused: Bool { get set }
    
    /// - returns: A list of all in-app messages
    @objc func getMessages() -> [IterableInAppMessage]
    
    /// - returns: A list of all inbox messages
    @objc func getInboxMessages() -> [IterableInAppMessage]
    
    /// - returns: A count of unread inbox messages
    @objc func getUnreadInboxMessagesCount() -> Int
    
    /// - parameter message: The message to show.
    @objc(showMessage:) func show(message: IterableInAppMessage)
    
    /// - parameter message: The message to show.
    /// - parameter consume: Set to true to consume the event from the server queue if the message is shown. This should be default.
    /// - parameter callback: block of code to execute once the user clicks on a link or button in the in-app notification.
    ///   Note that this callback is called in addition to calling `IterableCustomActionDelegate` or `IterableUrlDelegate` on the button action.
    @objc(showMessage:consume:callbackBlock:) func show(message: IterableInAppMessage, consume: Bool, callback: ITBURLCallback?)
    
    /// - parameter message: The message to remove.
    /// - parameter onCompletion: The callback which returns `success` or `failure`.
    @objc(removeMessage:onCompletion:) func remove(message: IterableInAppMessage, onCompletion: OnCompletionHandler?)
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter onCompletion: The callback which returns `success` or `failure`.
    @objc(removeMessage:location:onCompletion:) func remove(message: IterableInAppMessage, location: InAppLocation, onCompletion: OnCompletionHandler?)
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    /// - parameter onCompletion: The callback which returns `success` or `failure`.
    @objc(removeMessage:location:source:onCompletion:) func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, onCompletion: OnCompletionHandler?)
    
    /// - parameter read: Whether this inbox message was read
    /// - parameter message: The inbox message
    /// - parameter onCompletion: The callback which returns `success` or `failure`.
    @objc(setRead:forMessage:onCompletion:) func set(read: Bool, forMessage message: IterableInAppMessage, onCompletion: OnCompletionHandler?)
    
    /// - parameter id: The id of the message
    /// - returns: IterableInAppMessage with the id, if it exists.
    @objc(getMessageWithId:) func getMessage(withId id: String) -> IterableInAppMessage?
}
