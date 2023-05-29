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
    @objc(removeMessage:) func remove(message: IterableInAppMessage)
    
    /// - parameter message: The message to remove.
    /// - parameter successHandler: The callback which returns `success.
    /// - parameter failureHandler: The callback which returns `failure.
    @objc(removeMessage:successHandler:failureHandler:) func remove(message: IterableInAppMessage, successHandler: OnSuccessHandler?, failureHandler: OnFailureHandler?)
    
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    @objc(removeMessage:location:) func remove(message: IterableInAppMessage, location: InAppLocation)
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter successHandler: The callback which returns `success.
    /// - parameter failureHandler: The callback which returns `failure.
    @objc(removeMessage:location:successHandler:failureHandler:) func remove(message: IterableInAppMessage, location: InAppLocation, successHandler: OnSuccessHandler?, failureHandler: OnFailureHandler?)
    
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    @objc(removeMessage:location:source:) func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource)
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    /// - parameter successHandler: The callback which returns `success.
    /// - parameter failureHandler: The callback which returns `failure.
    @objc(removeMessage:location:source:successHandler:failureHandler:) func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, successHandler: OnSuccessHandler?, failureHandler: OnFailureHandler?)
    
    /// - parameter read: Whether this inbox message was read
    /// - parameter message: The inbox message
    @objc(setRead:forMessage:) func set(read: Bool, forMessage message: IterableInAppMessage)
    
    /// - parameter read: Whether this inbox message was read
    /// - parameter message: The inbox message
    /// - parameter successHandler: The callback which returns `success.
    /// - parameter failureHandler: The callback which returns `failure.
    @objc(setRead:forMessage:successHandler:failureHandler:) func set(read: Bool, forMessage message: IterableInAppMessage, successHandler: OnSuccessHandler?, failureHandler: OnFailureHandler?)
    
    /// - parameter id: The id of the message
    /// - returns: IterableInAppMessage with the id, if it exists.
    @objc(getMessageWithId:) func getMessage(withId id: String) -> IterableInAppMessage?
}
