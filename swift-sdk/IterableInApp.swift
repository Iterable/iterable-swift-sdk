//
//
//  Created by Tapash Majumder on 11/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/// `show` to show the inApp otherwise `skip` to skip.
@objc public enum InAppShowResponse : Int {
    case show
    case skip
}

@objc
public protocol IterableInAppManagerProtocol {
    /// - returns: A list of all messages
    @objc(getMessages) func getMessages() -> [IterableInAppMessage]

    /// - parameter message: The message to show.
    @objc(showMessage:) func show(message: IterableInAppMessage)

    /// - parameter message: The message to show.
    /// - parameter consume: Set to true to consume the event from the server queue if the message is shown. This should be default.
    /// - parameter callback: block of code to execute once the user clicks on a link or button in the inApp notification.
    ///   Note that this callback is called in addition to calling `IterableCustomActionDelegate` or `IterableUrlDelegate` on the button action.
    @objc(showMessage:consume:callbackBlock:) func show(message: IterableInAppMessage, consume: Bool, callback:ITEActionBlock?)
    
    /// - parameter message: The message to remove.
    @objc(removeMessage:) func remove(message: IterableInAppMessage)
}

/// By default, every single inApp will be shown as soon as it is available.
/// If more than 1 inApp is available, we show the first showable one.
@objcMembers
open class DefaultInAppDelegate : IterableInAppDelegate {
    public init() {}
    
    open func onNew(message: IterableInAppMessage) -> InAppShowResponse {
        ITBInfo()
        return .show
    }
}

@objc
public enum IterableInAppContentType : Int, Codable {
    case html
    case unknown
}

@objc
public protocol IterableInAppContent {
    var contentType: IterableInAppContentType {get}
}

@objcMembers
public class IterableHtmlInAppContent : NSObject, IterableInAppContent, Codable {
    public let contentType = IterableInAppContentType.html
    
    /// Edge insets
    public let edgeInsets: UIEdgeInsets
    /// Background alpha setting
    public let backgroundAlpha: Double
    /// The html to display
    public let html: String
    
    // Internal
    init(
        edgeInsets: UIEdgeInsets,
        backgroundAlpha: Double,
        html: String) {
        self.edgeInsets = edgeInsets
        self.backgroundAlpha = backgroundAlpha
        self.html = html
    }
}

/// `immediate` will try to display the inApp automatically immediately
/// `event` is used for Push to InApp
/// `never` will not display the inApp automatically via the SDK
@objc public enum IterableInAppTriggerType: Int, Codable {
    case immediate
    case event
    case never
}

/// A message is comprised of content and whether this message was skipped.
@objcMembers
public final class IterableInAppMessage : NSObject {
    /// the id for the inApp message
    public let messageId: String

    /// the campaign id for this message
    public let campaignId: String
    
    /// the name of channelFor this message
    public let channelName: String
    
    /// The type of content
    public let contentType: IterableInAppContentType

    /// when to trigger this in-app
    public let trigger: IterableInAppTriggerType
    
    /// when to expire this in-app, nil means do not expire
    public let expiresAt: Date?
    
    /// The content of the inApp message
    public let content: IterableInAppContent
    
    /// Extra Information from the 'payload' section of message.
    public let extraInfo: [AnyHashable : Any]?

    /// Whether we have processed this message.
    /// Note: This is internal and not public
    var processed: Bool = false
    
    /// Mark this message to be removed from server queue.
    /// Note: This is internal and not public
    var consumed: Bool = false

    // Internal, don't let others create
    init(
        messageId: String,
        campaignId: String,
        channelName: String = "reserved",
        contentType: IterableInAppContentType = .html,
        trigger: IterableInAppTriggerType = .defaultTriggerType,
        expiresAt: Date? = nil,
        content: IterableInAppContent,
        extraInfo: [AnyHashable : Any]? = nil
        ) {
        self.messageId = messageId
        self.campaignId = campaignId
        self.channelName = channelName
        self.contentType = contentType
        self.trigger = trigger
        self.expiresAt = expiresAt
        self.content = content
        self.extraInfo = extraInfo
    }
}


