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
    
    /// The placement ID of message
    public let placementId: Double
    
    /// How many times this message was displayed
    public var displayCount: Int
    
    /// Total duration this message was displayed
    public var displayDuration: TimeInterval
    
    public init(messageId: String,
                placementId: Double,
                displayCount: Int,
                displayDuration: TimeInterval) {
        self.messageId = messageId
        self.placementId = placementId
        self.displayCount = displayCount
        self.displayDuration = displayDuration
    }
}

protocol EmbeddedNotifiable: AnyObject {
    func syncMessages(completion: @escaping () -> Void)
}

/// Encapsulates an Embedded Session
final public class IterableEmbeddedSession: NSObject, Codable {
    /// UUID of the session
    public let embeddedSessionId: String
    
    /// Start time of the session
    public let embeddedSessionStart: Date?
    
    /// End time of the session
    public var embeddedSessionEnd: Date?
    
    /// Array of impressions for messages
    public var impressions: [IterableEmbeddedImpression]
    
    public var isActive: Bool
    
    public init(embeddedSessionId: String = UUID().uuidString,
                embeddedSessionStart: Date,
                embeddedSessionEnd: Date? = nil,
                impressions: [IterableEmbeddedImpression],
                isActive: Bool = false) {
        self.embeddedSessionId = embeddedSessionId
        self.embeddedSessionStart = embeddedSessionStart
        self.embeddedSessionEnd = embeddedSessionEnd
        self.impressions = impressions
        self.isActive = isActive
    }
}


