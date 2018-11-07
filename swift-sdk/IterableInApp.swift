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
    /// - returns: A list of messages
    func getMessages() -> [IterableInAppMessage]

    /// - parameter content: The content to show.
    /// - parameter consume: Set to true to consume the event from the server queue. This should be default.
    func show(content: IterableInAppContent, consume: Bool)
}

/// By default, every single inApp will be shown as soon as it is available.
/// If more than 1 inApp is available, we show the first showable one.
@objcMembers
public class DefaultInAppDelegate : IterableInAppDelegate {
    public func onNew(content: IterableInAppContent) -> ShowInApp {
        ITBInfo()
        return .show
    }
    
    public func onNew(batch: [IterableInAppContent]) -> IterableInAppContent? {
        ITBInfo()
        for content in batch {
            if onNew(content: content) == .show {
                return content
            }
        }
        
        return nil
    }
}

/// This class encapsulates an inApp message content such as html etc.
@objcMembers
public class IterableInAppContent : NSObject {
    /// the id for the inApp message
    public let messageId: String
    /// Edge insets
    public let edgeInsets: UIEdgeInsets
    /// Background alpha setting
    public let backgroundAlpha: Double
    /// The html to display
    public let html: String
    
    // Internal
    init(
        messageId: String,
        edgeInsets: UIEdgeInsets,
        backgroundAlpha: Double,
        html: String) {
        self.messageId = messageId
        self.edgeInsets = edgeInsets
        self.backgroundAlpha = backgroundAlpha
        self.html = html
    }
}

/// A message is comprised of content and whether this message was skipped.
@objcMembers
public class IterableInAppMessage : NSObject {
    /// The content of the inApp message
    let content: IterableInAppContent
    /// Whether this message has been skipped (not shown)
    var skipped: Bool
    
    init(
        content: IterableInAppContent,
        skipped: Bool = false
        ) {
        self.content = content
        self.skipped = skipped
    }
}


