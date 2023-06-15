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
        print("starting session...")
        let startTime = Date()
        session = IterableEmbeddedSession(embeddedSessionId: UUID().uuidString, embeddedSessionStart: startTime, impressions: [])
    }

    public func endSession() {
        print("ending session...")
        guard let session = session else {
            ITBError("No current session.")
            return
        }
        
        for impressionId in currentlyTrackingImpressions.keys {
            pauseImpression(impressionId: impressionId)
        }
        session.embeddedSessionEnd = Date()
        updateDisplayDurations()
        
        if session.impressions.isEmpty {
                ITBInfo("No impressions in the session. Skipping tracking.")
                return
            }
        let _ = IterableAPI.embeddedMessagingManager.track(embeddedSession: session)
    }
    
    public func pauseImpression(impressionId: String) {
        if var trackingImpression = currentlyTrackingImpressions[impressionId], trackingImpression.tracking {
            let currentTime = Date()
            let elapsedTime = currentTime.timeIntervalSince(trackingImpression.startTime)
            trackingImpression.totalDisplayDuration += elapsedTime
            trackingImpression.tracking = false
            currentlyTrackingImpressions[impressionId] = trackingImpression
        }
    }

    public func resumeImpression(impressionId: String) {
        if var trackingImpression = currentlyTrackingImpressions[impressionId], !trackingImpression.tracking {
            trackingImpression.startTime = Date()
            trackingImpression.tracking = true
            currentlyTrackingImpressions[impressionId] = trackingImpression
        }
    }

    public func createOrUpdateImpression(impressionId: String) {
        if let _ = currentlyTrackingImpressions[impressionId] {
            if let index = session?.impressions.firstIndex(where: { $0.messageId == impressionId }) {
                session?.impressions[index].displayCount += 1
            }
        } else {
            let newImpression = IterableEmbeddedImpression(messageId: impressionId, displayCount: 1, displayDuration: 0)
            session?.impressions.append(newImpression)
            currentlyTrackingImpressions[impressionId] = (totalDisplayDuration: 0, startTime: Date(), tracking: true)
        }
        
        resumeImpression(impressionId: impressionId)
    }
    
    private func updateDisplayDurations() {
        for (impressionId, impressionData) in currentlyTrackingImpressions {
            if let index = session?.impressions.firstIndex(where: { $0.messageId == impressionId }) {
                let displayDuration = round(impressionData.totalDisplayDuration)
                session?.impressions[index].displayDuration = displayDuration
            }
        }
    }
}
