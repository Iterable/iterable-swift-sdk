//
//  Created by Tapash Majumder on 11/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

// This file contains In-app and Inbox messaging classes.

import Foundation
import UIKit

/// `show` to show the in-app otherwise `skip` to skip.
@objc public enum InAppShowResponse: Int {
    case show
    case skip
}

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
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    @objc(removeMessage:location:) func remove(message: IterableInAppMessage, location: InAppLocation)
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    @objc(removeMessage:location:source:) func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource)
    
    /// - parameter read: Whether this inbox message was read
    /// - parameter message: The inbox message
    @objc(setRead:forMessage:) func set(read: Bool, forMessage message: IterableInAppMessage)
    
    /// - parameter id: The id of the message
    /// - returns: IterableInAppMessage with the id, if it exists.
    @objc(getMessageWithId:) func getMessage(withId id: String) -> IterableInAppMessage?
}

/// Iterable Notification names
public extension Notification.Name {
    /// This is fired when in app inbox changes.
    static let iterableInboxChanged = Notification.Name(rawValue: "itbl_inbox_changed")
}

@objcMembers open class DefaultInAppDelegate: IterableInAppDelegate {
    public init() {}
    
    /// By default, every single in-app will be shown as soon as it is available.
    /// If more than 1 in-app is available, we show the first showable one.
    open func onNew(message _: IterableInAppMessage) -> InAppShowResponse {
        ITBInfo()
        return .show
    }
}

@objc public enum IterableInAppContentType: Int, Codable {
    case html
    case alert
    case banner
}

@objc public protocol IterableInAppContent {
    var type: IterableInAppContentType { get }
}

@objcMembers public final class IterableHtmlInAppContent: NSObject, IterableInAppContent {
    public let type = IterableInAppContentType.html
    
    /// Edge insets
    public let edgeInsets: UIEdgeInsets
    /// Background alpha setting
    public let backgroundAlpha: Double
    /// The HTML to display
    public let html: String
    
    // Internal
    init(edgeInsets: UIEdgeInsets,
         backgroundAlpha: Double,
         html: String) {
        self.edgeInsets = edgeInsets
        self.backgroundAlpha = backgroundAlpha
        self.html = html
    }
}

@objcMembers public final class IterableInboxMetadata: NSObject {
    public let title: String?
    public let subtitle: String?
    public let icon: String?
    
    // Internal
    init(title: String? = nil,
         subtitle: String? = nil,
         icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

/// `immediate` will try to display the in-app automatically immediately
/// `event` is used for Push to in-app
/// `never` will not display the in-app automatically via the SDK
@objc public enum IterableInAppTriggerType: Int, Codable {
    case immediate
    case event
    case never
}

@objcMembers public final class IterableInAppTrigger: NSObject {
    public let type: IterableInAppTriggerType
    
    // Internal
    let dict: [AnyHashable: Any]
    
    // Internal
    init(dict: [AnyHashable: Any]) {
        self.dict = dict
        if let typeString = dict[JsonKey.InApp.type] as? String {
            type = IterableInAppTriggerType.from(string: typeString)
        } else {
            type = IterableInAppTriggerType.immediate
        }
    }
}

/// A message is comprised of content and whether this message was skipped.
@objcMembers public final class IterableInAppMessage: NSObject {
    /// the ID for the in-app message
    public let messageId: String
    
    /// the campaign ID for this message
    public let campaignId: NSNumber?
    
    /// when to trigger this in-app
    public let trigger: IterableInAppTrigger
    
    /// when was this message created
    public let createdAt: Date?
    
    /// when to expire this in-app (nil means do not expire)
    public let expiresAt: Date?
    
    /// The content of the in-app message
    public let content: IterableInAppContent
    
    /// Whether to save this message to inbox
    public let saveToInbox: Bool
    
    /// Metadata such as title, subtitle etc. needed to display this in-app message in inbox.
    public let inboxMetadata: IterableInboxMetadata?
    
    /// Custom Payload for this message.
    public let customPayload: [AnyHashable: Any]?
    
    /// Whether we have processed the trigger for this message.
    /// Note: This is internal and not public
    internal var didProcessTrigger = false
    
    /// Mark this message to be removed from server queue.
    /// Note: This is internal and not public
    internal var consumed: Bool = false
    
    /// Whether this inbox message has been read
    public var read: Bool = false
    
    /// Whether this message will be delivered silently to inbox
    public var silentInbox: Bool {
        return saveToInbox && trigger.type == .never
    }
    
    // Internal, don't let others create
    init(messageId: String,
         campaignId: NSNumber?,
         trigger: IterableInAppTrigger = .defaultTrigger,
         createdAt: Date? = nil,
         expiresAt: Date? = nil,
         content: IterableInAppContent,
         saveToInbox: Bool = false,
         inboxMetadata: IterableInboxMetadata? = nil,
         customPayload: [AnyHashable: Any]? = nil,
         read: Bool = false) {
        self.messageId = messageId
        self.campaignId = campaignId
        self.trigger = trigger
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.content = content
        self.saveToInbox = saveToInbox
        self.inboxMetadata = inboxMetadata
        self.customPayload = customPayload
        self.read = read
    }
}
