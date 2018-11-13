//
//
//  Created by Tapash Majumder on 11/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/// `show` to show the inApp otherwise `skip` to skip.
@objc public enum ShowInApp : Int {
    case show
    case skip
}

@objc
public protocol IterableInAppManagerProtocol {
    /// - returns: A list of all messages
    @objc(getMessages) func getMessages() -> [IterableInAppMessage]

    /// - parameter message: The message to show.
    /// - parameter consume: Set to true to consume the event from the server queue if the message is shown. This should be default.
    /// - parameter callback: block of code to execute once the user clicks on a link or button in the inApp notification.
    @objc(showContent:consume:callbackBlock:) func show(message: IterableInAppMessage, consume: Bool, callback:ITEActionBlock?)
}

/// By default, every single inApp will be shown as soon as it is available.
/// If more than 1 inApp is available, we show the first showable one.
@objcMembers
public class DefaultInAppDelegate : IterableInAppDelegate {
    public func onNew(message: IterableInAppMessage) -> ShowInApp {
        ITBInfo()
        return .show
    }
    
    public func onNew(batch: [IterableInAppMessage]) -> IterableInAppMessage? {
        ITBInfo()
        for message in batch {
            if onNew(message: message) == .show {
                return message
            }
        }
        
        return nil
    }
}

@objc
public enum IterableInAppContentType : Int {
    case html
    case unknown
}

@objc
public protocol IterableInAppContent {
    var contentType: IterableInAppContentType {get}
}

@objcMembers
public class IterableHtmlInAppContent : NSObject, IterableInAppContent {
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

/// A message is comprised of content and whether this message was skipped.
@objcMembers
public class IterableInAppMessage : NSObject {
    /// the id for the inApp message
    public let messageId: String

    /// the campaign id for this message
    public let campaignId: String
    
    /// the name of channelFor this message
    public let channelName: String
    
    /// The type of content
    public let contentType: IterableInAppContentType

    /// The content of the inApp message
    public let content: IterableInAppContent

    /// Whether this message has been skipped (not shown)
    public var skipped: Bool = false

    // Internal, don't let others create
    init(
        messageId: String,
        campaignId: String,
        channelName: String = "reserved",
        contentType: IterableInAppContentType = .html,
        content: IterableInAppContent
        ) {
        self.messageId = messageId
        self.campaignId = campaignId
        self.channelName = channelName
        self.contentType = contentType
        self.content = content
    }
}


