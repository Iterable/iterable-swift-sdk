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
    private var messageTimers: [String: Timer] = [:]
    var pauseTimestamps: [String: Date] = [:]


    public func startSession() {
        let startTime = Date()
        currentSession = IterableEmbeddedSession(embeddedSessionId: UUID().uuidString, embeddedSessionStart: startTime, impressions: [])
    }

    public func endSession() {
        currentSession?.embeddedSessionEnd = Date()
        for timer in messageTimers.values {
            timer.invalidate()
        }
        messageTimers.removeAll()
        
        if let session = currentSession {
            let _ = IterableAPI.embeddedMessagingManager.track(embeddedSession: session)
        }
    }

    public func stopTimerForImpression(impressionId: String) {
        messageTimers[impressionId]?.invalidate()
        messageTimers[impressionId] = nil
    }
    
    public func pauseTimerForImpression(impressionId: String) {
        messageTimers[impressionId]?.invalidate()
        pauseTimestamps[impressionId] = Date()
    }

    public func resumeTimerForImpression(impressionId: String) {
        if let timer = messageTimers[impressionId], timer.isValid {
            return
        }
        if pauseTimestamps.removeValue(forKey: impressionId) != nil {
            if let index = currentSession?.impressions.firstIndex(where: { $0.messageId == impressionId }) {
                let newDisplayDuration = currentSession!.impressions[index].displayDuration
                currentSession?.impressions[index].displayDuration = newDisplayDuration
            }
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateDisplayDurationForImpression(impressionId: impressionId)
            }
            messageTimers[impressionId] = timer
        }
    }


    
    public func createOrUpdateImpression(impressionId: String) {
        if let index = currentSession?.impressions.firstIndex(where: { $0.messageId == impressionId }) {
            currentSession?.impressions[index].displayCount += 1
        } else {
            let newImpression = IterableEmbeddedImpression(messageId: impressionId, displayCount: 1, displayDuration: 0)
            currentSession?.impressions.append(newImpression)
        }

        if messageTimers[impressionId] == nil {
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateDisplayDurationForImpression(impressionId: impressionId)
            }
            messageTimers[impressionId] = timer
        }
        
        resumeTimerForImpression(impressionId: impressionId)
    }

    private func updateDisplayDurationForImpression(impressionId: String) {
        if let index = currentSession?.impressions.firstIndex(where: { $0.messageId == impressionId }) {
            currentSession?.impressions[index].displayDuration += 1
        }
    }
}
