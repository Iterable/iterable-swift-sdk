//
//  Copyright © 2025 Iterable. All rights reserved.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *)
public class IterableLiveActivityManager: NSObject {
    public static let shared = IterableLiveActivityManager()
    
    /// Currently active activities tracked by their ID
    private var activeActivities: [String: Activity<IterableLiveActivityAttributes>] = [:]
    
    private override init() {}
    
    /// Start a Live Activity and register its push token with Iterable
    /// - Parameters:
    ///   - vital: Vital information to display (e.g., "145 BPM")
    ///   - duration: Duration in seconds
    ///   - title: Activity title
    ///   - pushType: Push type for updates (default: .token)
    /// - Returns: The activity ID if started successfully
    @discardableResult
    public func start(
        vital: String,
        duration: TimeInterval,
        title: String,
        pushType: PushType? = nil
    ) -> String? {
        let attributes = IterableLiveActivityAttributes()
        let contentState = IterableLiveActivityAttributes.ContentState(
            vital: vital,
            duration: duration,
            title: title
        )
        
        do {
            let activity = try Activity<IterableLiveActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: pushType
            )
            
            let activityId = activity.id
            activeActivities[activityId] = activity
            
            ITBInfo("Live Activity started with ID: \(activityId)")
            
            // Observe push token updates
            Task {
                for await pushToken in activity.pushTokenUpdates {
                    await self.registerLiveActivityToken(pushToken, activityId: activityId)
                }
            }
            
            // Observe activity state changes
            Task {
                for await state in activity.activityStateUpdates {
                    self.handleActivityStateChange(activityId: activityId, state: state)
                }
            }
            
            return activityId
            
        } catch {
            ITBError("Error starting Live Activity: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Register a Live Activity push token with Iterable
    @MainActor
    private func registerLiveActivityToken(_ token: Data, activityId: String) {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        ITBInfo("Live Activity Token received for activity \(activityId): \(tokenString)")
        
        // Register the token with Iterable
        IterableAPI.registerLiveActivityToken(
            token,
            activityId: activityId,
            onSuccess: { _ in
                ITBInfo("Live Activity token registered successfully")
            },
            onFailure: { reason, _ in
                ITBError("Failed to register Live Activity token: \(reason ?? "unknown error")")
            }
        )
    }
    
    /// Handle activity state changes
    private func handleActivityStateChange(activityId: String, state: ActivityState) {
        switch state {
        case .active:
            ITBInfo("Live Activity \(activityId) is active")
        case .ended:
            ITBInfo("Live Activity \(activityId) ended")
            activeActivities.removeValue(forKey: activityId)
        case .dismissed:
            ITBInfo("Live Activity \(activityId) dismissed")
            activeActivities.removeValue(forKey: activityId)
        case .stale:
            ITBInfo("Live Activity \(activityId) is stale")
        @unknown default:
            ITBInfo("Live Activity \(activityId) unknown state")
        }
    }
    
    /// Update an existing Live Activity
    public func update(
        activityId: String,
        vital: String,
        duration: TimeInterval,
        title: String
    ) async {
        guard let activity = activeActivities[activityId] else {
            ITBError("No active Live Activity found with ID: \(activityId)")
            return
        }
        
        let contentState = IterableLiveActivityAttributes.ContentState(
            vital: vital,
            duration: duration,
            title: title
        )
        
        await activity.update(using: contentState)
        ITBInfo("Live Activity \(activityId) updated")
    }
    
    /// End a Live Activity
    public func end(activityId: String, dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        guard let activity = activeActivities[activityId] else {
            ITBError("No active Live Activity found with ID: \(activityId)")
            return
        }
        
        await activity.end(dismissalPolicy: dismissalPolicy)
        activeActivities.removeValue(forKey: activityId)
        ITBInfo("Live Activity \(activityId) ended")
    }
    
    /// End all active Live Activities
    public func endAll(dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        for (activityId, activity) in activeActivities {
            await activity.end(dismissalPolicy: dismissalPolicy)
            ITBInfo("Live Activity \(activityId) ended")
        }
        activeActivities.removeAll()
    }
    
    /// Get the push-to-start token if available (iOS 17.2+)
    @available(iOS 17.2, *)
    public func getPushToStartToken() -> Data? {
        return Activity<IterableLiveActivityAttributes>.pushToStartToken
    }
    
    /// Observe push-to-start token updates (iOS 17.2+)
    @available(iOS 17.2, *)
    public func observePushToStartTokenUpdates() {
        Task {
            for await token in Activity<IterableLiveActivityAttributes>.pushToStartTokenUpdates {
                let tokenString = token.map { String(format: "%02x", $0) }.joined()
                ITBInfo("Push-to-start token received: \(tokenString)")
                
                // Register the push-to-start token with Iterable
                await MainActor.run {
                    IterableAPI.registerLiveActivityToken(
                        token,
                        activityId: "push-to-start",
                        onSuccess: { _ in
                            ITBInfo("Push-to-start token registered successfully")
                        },
                        onFailure: { reason, _ in
                            ITBError("Failed to register push-to-start token: \(reason ?? "unknown error")")
                        }
                    )
                }
            }
        }
    }
    
    /// Get all active activity IDs
    public var activeActivityIds: [String] {
        Array(activeActivities.keys)
    }
}
#endif


