//
//  File.swift
//  
//
//  Created by Andrew Nelson on 5/24/23.
//

import Foundation

/// Encapsulates an Embedded impression of a message
public class IterableEmbeddedImpression: NSObject, Codable {
    /// The message ID of message
    public let messageId: String
    
    /// How many times this message was displayed
    public var displayCount: Int
    
    /// Total duration this message was displayed
    public var displayDuration: TimeInterval
    
    public init(messageId: String,
                displayCount: Int,
                displayDuration: TimeInterval) {
        self.messageId = messageId
        self.displayCount = displayCount
        self.displayDuration = displayDuration
    }
}

/// Encapsulates an Embedded Session
final public class IterableEmbeddedSession: NSObject, Codable {
    /// UUID of the session
    public let embeddedSessionId: String
    
    /// Placement ID, optional
    public let placementId: String?
    
    /// Start time of the session
    public let embeddedSessionStart: Date?
    
    /// End time of the session
    public var embeddedSessionEnd: Date?
    
    /// Array of impressions for messages
    public var impressions: [IterableEmbeddedImpression]
    
    public init(embeddedSessionId: String = UUID().uuidString,
                placementId: String? = nil,
                embeddedSessionStart: Date,
                embeddedSessionEnd: Date? = nil,
                impressions: [IterableEmbeddedImpression]) {
        self.embeddedSessionId = embeddedSessionId
        self.placementId = placementId
        self.embeddedSessionStart = embeddedSessionStart
        self.embeddedSessionEnd = embeddedSessionEnd
        self.impressions = impressions
    }
}


