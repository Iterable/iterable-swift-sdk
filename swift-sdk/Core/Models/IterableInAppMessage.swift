//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

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
        saveToInbox && trigger.type == .never
    }
    
    /// the urgency level of this message (nil will be treated as `unassigned` when displaying this message)
    public var priorityLevel: Double
	
    /// Whether this message is a JSON-only message
    public let jsonOnly: Bool
    
    // MARK: - Private/Internal
    
    init(messageId: String,
         campaignId: NSNumber?,
         trigger: IterableInAppTrigger = .defaultTrigger,
         createdAt: Date? = nil,
         expiresAt: Date? = nil,
         content: IterableInAppContent,
         saveToInbox: Bool = false,
         inboxMetadata: IterableInboxMetadata? = nil,
         customPayload: [AnyHashable: Any]? = nil,
         read: Bool = false,
         priorityLevel: Double = Const.PriorityLevel.unassigned,
         jsonOnly: Bool = false) {
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
        self.priorityLevel = priorityLevel
        self.jsonOnly = jsonOnly
    }
}
