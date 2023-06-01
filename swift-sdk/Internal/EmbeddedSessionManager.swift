//
//  EmbeddedSessionManager.swift
//  
//
//  Created by Andrew Nelson on 5/30/23.
//

import Foundation

public class EmbeddedSessionManager {
    public static let shared = EmbeddedSessionManager()
    public var currentSession: IterableEmbeddedSession?
    var currentlyTrackingImpressions: [String: (currentDisplayDuration: TimeInterval, startTime: Date, tracking: Bool)] = [:]

    public func startSession() {
        let startTime = Date()
        currentSession = IterableEmbeddedSession(embeddedSessionId: UUID().uuidString, embeddedSessionStart: startTime, impressions: [])
    }

    public func endSession() {
        guard let currentSession = currentSession else {
            ITBError("No current session.")
            return
        }
        
        for impressionId in currentlyTrackingImpressions.keys {
            pauseImpression(impressionId: impressionId)
        }
        currentSession.embeddedSessionEnd = Date()
        updateDisplayDurations()
        let _ = IterableAPI.embeddedMessagingManager.track(embeddedSession: currentSession)
    }
    
    public func pauseImpression(impressionId: String) {
        if var trackingImpression = currentlyTrackingImpressions[impressionId], trackingImpression.tracking {
            let currentTime = Date()
            let elapsedTime = currentTime.timeIntervalSince(trackingImpression.startTime)
            trackingImpression.currentDisplayDuration += elapsedTime
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
            if let index = currentSession?.impressions.firstIndex(where: { $0.messageId == impressionId }) {
                currentSession?.impressions[index].displayCount += 1
            }
        } else {
            let newImpression = IterableEmbeddedImpression(messageId: impressionId, displayCount: 1, displayDuration: 0)
            currentSession?.impressions.append(newImpression)
            currentlyTrackingImpressions[impressionId] = (currentDisplayDuration: 0, startTime: Date(), tracking: true)
        }
        
        resumeImpression(impressionId: impressionId)
    }
    
    private func updateDisplayDurations() {
        for (impressionId, impressionData) in currentlyTrackingImpressions {
            if let index = currentSession?.impressions.firstIndex(where: { $0.messageId == impressionId }) {
                let displayDuration = round(impressionData.currentDisplayDuration)
                currentSession?.impressions[index].displayDuration = displayDuration
            }
        }
    }
}
