//  Created by Tapash Majumder on 2/10/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// Encapsulates an Inbox impression of a message
class IterableInboxImpression: NSObject, Codable {
    /// The message ID of message
    public let messageId: String
    
    /// Whether the message was silently delivered to inbox
    public let silentInbox: Bool
    
    /// How many times this message was displayed in inbox
    public let displayCount: Int
    
    /// Total duration this message was displayed
    public let displayDuration: TimeInterval
    
    public init(messageId: String,
                silentInbox: Bool,
                displayCount: Int,
                displayDuration: TimeInterval) {
        self.messageId = messageId
        self.silentInbox = silentInbox
        self.displayCount = displayCount
        self.displayDuration = displayDuration
    }
}

/// Encapsulates Inbox Session
final class IterableInboxSession: NSObject, Codable {
    /// UUID of the session
    public let id: String?
    
    /// Start time of session
    public let sessionStartTime: Date?
    
    /// End time of session
    public let sessionEndTime: Date?
    
    /// Total messages at start of session
    public let startTotalMessageCount: Int
    
    /// Unread messages at start of session
    public let startUnreadMessageCount: Int
    
    /// Total messages at end of session
    public let endTotalMessageCount: Int
    
    /// Unread messages at end of session
    public let endUnreadMessageCount: Int
    
    /// Array of impressions for inbox messages
    public let impressions: [IterableInboxImpression]
    
    public init(id: String? = nil,
                sessionStartTime: Date? = nil,
                sessionEndTime: Date? = nil,
                startTotalMessageCount: Int = 0,
                startUnreadMessageCount: Int = 0,
                endTotalMessageCount: Int = 0,
                endUnreadMessageCount: Int = 0,
                impressions: [IterableInboxImpression] = []) {
        self.id = id
        self.sessionStartTime = sessionStartTime
        self.sessionEndTime = sessionEndTime
        self.startTotalMessageCount = startTotalMessageCount
        self.startUnreadMessageCount = startUnreadMessageCount
        self.endTotalMessageCount = endTotalMessageCount
        self.endUnreadMessageCount = endUnreadMessageCount
        self.impressions = impressions
    }
}
