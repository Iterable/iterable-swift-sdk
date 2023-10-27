//
//  EmbeddedSessionManager.swift
//  
//
//  Created by Andrew Nelson on 5/30/23.
//

import Foundation

public class EmbeddedSessionManager {
    public static let shared = EmbeddedSessionManager()
    public var session: IterableEmbeddedSession?
    var currentlyTrackingImpressions: [String: (totalDisplayDuration: TimeInterval, startTime: Date, tracking: Bool)] = [:]

    public func startSession() {
        if session?.isActive == true {
            return
        }
        let startTime = Date()
        currentlyTrackingImpressions = [:]
        session = IterableEmbeddedSession(embeddedSessionId: UUID().uuidString, embeddedSessionStart: startTime, impressions: [], isActive: true)
    }

    public func endSession() {
        guard session?.isActive == true else {
            return
        }
        guard let session = session else {
            ITBError("No current session.")
            return
        }
        
        for messageId in currentlyTrackingImpressions.keys {
            pauseImpression(messageId: messageId)
        }
        session.embeddedSessionEnd = Date()
        updateDisplayDurations()
        

        
        if session.impressions.isEmpty {
                ITBInfo("No impressions in the session. Skipping tracking.")
                return
            }
        
        for index in session.impressions.indices {
            let displayDuration = session.impressions[index].displayDuration
            let displayDurationStr = String(format: "%.2f", displayDuration)
            session.impressions[index].displayDuration = Double(displayDurationStr) ?? 0
        }
        let _ = IterableAPI.track(embeddedSession: session)
        session.isActive = false
    }
    
    public func pauseImpression(messageId: String) {
        if var trackingImpression = currentlyTrackingImpressions[messageId], trackingImpression.tracking {
            let currentTime = Date()
            let elapsedTime = currentTime.timeIntervalSince(trackingImpression.startTime)
            trackingImpression.totalDisplayDuration += elapsedTime
            trackingImpression.tracking = false
            currentlyTrackingImpressions[messageId] = trackingImpression
        }
    }

    public func startImpression(messageId: String, placementId: Double) {
        if let trackingImpression = currentlyTrackingImpressions[messageId], trackingImpression.tracking {
            return
        }
        if let _ = currentlyTrackingImpressions[messageId] {
            if let index = session?.impressions.firstIndex(where: { $0.messageId == messageId }) {
                session?.impressions[index].displayCount += 1
            }
        } else {
            let newImpression = IterableEmbeddedImpression(messageId: messageId, placementId: placementId, displayCount: 1, displayDuration: 0)
            session?.impressions.append(newImpression)
            currentlyTrackingImpressions[messageId] = (totalDisplayDuration: 0, startTime: Date(), tracking: true)
        }
        
        resumeImpression(messageId: messageId)
    }
    
    private func resumeImpression(messageId: String) {
        if var trackingImpression = currentlyTrackingImpressions[messageId], !trackingImpression.tracking {
            trackingImpression.startTime = Date()
            trackingImpression.tracking = true
            currentlyTrackingImpressions[messageId] = trackingImpression
        }
    }
    
    private func updateDisplayDurations() {
        for (messageId, impressionData) in currentlyTrackingImpressions {
            if let index = session?.impressions.firstIndex(where: { $0.messageId == messageId }) {
                let displayDuration = impressionData.totalDisplayDuration
                session?.impressions[index].displayDuration = displayDuration
            }
        }
    }
}
