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
    
    /// Timer for mock updates
    private var mockUpdateTimer: Timer?
    private var mockElapsedSeconds: TimeInterval = 0
    private var currentMockActivityId: String?
    private var currentOpponent: RecordedRun?
    
    private override init() {}
    
    // MARK: - Start Run Comparison Live Activity
    
    /// Start a run comparison Live Activity
    /// - Parameters:
    ///   - runner: The runner to compare against
    ///   - paceLevel: The pace level of the opponent's run
    ///   - pushType: Push type for updates (default: .token)
    /// - Returns: The activity ID if started successfully
    @discardableResult
    public func startRunComparison(
        against runner: RunnerName,
        at paceLevel: PaceLevel,
        pushType: PushType? = nil
    ) -> String? {
        let opponent = RunDataStore.getRecordedRun(runner: runner, pace: paceLevel)
        return startRunComparison(opponent: opponent, pushType: pushType)
    }
    
    /// Start a run comparison Live Activity with a pre-configured opponent
    @discardableResult
    public func startRunComparison(
        opponent: RecordedRun,
        pushType: PushType? = nil
    ) -> String? {
        let attributes = IterableLiveActivityAttributes(opponent: opponent)
        let initialState = createContentState(elapsedSeconds: 0, opponent: opponent)
        
        do {
            let activity = try Activity<IterableLiveActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: pushType
            )
            
            let activityId = activity.id
            activeActivities[activityId] = activity
            currentOpponent = opponent
            
            ITBInfo("Run comparison Live Activity started with ID: \(activityId), opponent: \(opponent.runnerName.rawValue) at \(opponent.paceLevel.rawValue)")
            
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
    
    // MARK: - Mock Updates
    
    /// Start mock updates for demo purposes
    /// - Parameters:
    ///   - activityId: The activity to update
    ///   - updateInterval: Time between updates in seconds (default: 1.0)
    public func startMockUpdates(activityId: String, updateInterval: TimeInterval = 1.0) {
        stopMockUpdates()
        
        currentMockActivityId = activityId
        mockElapsedSeconds = 0
        
        mockUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.mockElapsedSeconds += updateInterval
            
            Task {
                await self.updateWithMockData(activityId: activityId)
            }
        }
    }
    
    /// Stop mock updates
    public func stopMockUpdates() {
        mockUpdateTimer?.invalidate()
        mockUpdateTimer = nil
        currentMockActivityId = nil
        mockElapsedSeconds = 0
    }
    
    private func updateWithMockData(activityId: String) async {
        guard let opponent = currentOpponent else { return }
        
        let contentState = createContentState(elapsedSeconds: mockElapsedSeconds, opponent: opponent)
        await update(activityId: activityId, contentState: contentState)
    }
    
    // MARK: - Content State Creation
    
    private func createContentState(elapsedSeconds: TimeInterval, opponent: RecordedRun) -> IterableLiveActivityAttributes.ContentState {
        let currentPace = RunDataStore.currentRunnerPaceSecondsPerKm
        let currentDistance = RunDataStore.distanceForPace(currentPace, elapsedSeconds: elapsedSeconds)
        let opponentDistance = RunDataStore.distanceForPace(opponent.paceSecondsPerKm, elapsedSeconds: elapsedSeconds)
        
        // Add slight BPM variation for realism
        let bpmVariation = Int.random(in: -3...3)
        let currentBpm = RunDataStore.currentRunnerBaseBpm + bpmVariation
        
        return IterableLiveActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            currentDistanceMeters: currentDistance,
            currentPaceSecondsPerKm: currentPace,
            currentBpm: currentBpm,
            opponentDistanceMeters: opponentDistance,
            distanceDifferenceMeters: currentDistance - opponentDistance
        )
    }
    
    // MARK: - Update & End
    
    /// Update an existing Live Activity with new content state
    public func update(activityId: String, contentState: IterableLiveActivityAttributes.ContentState) async {
        guard let activity = activeActivities[activityId] else {
            ITBError("No active Live Activity found with ID: \(activityId)")
            return
        }
        
        await activity.update(using: contentState)
        ITBInfo("Live Activity \(activityId) updated - elapsed: \(contentState.formattedElapsedTime), diff: \(contentState.formattedDistanceDifference)")
    }
    
    /// End a Live Activity
    public func end(activityId: String, dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        stopMockUpdates()
        
        guard let activity = activeActivities[activityId] else {
            ITBError("No active Live Activity found with ID: \(activityId)")
            return
        }
        
        await activity.end(dismissalPolicy: dismissalPolicy)
        activeActivities.removeValue(forKey: activityId)
        currentOpponent = nil
        ITBInfo("Live Activity \(activityId) ended")
    }
    
    /// End all active Live Activities
    public func endAll(dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        stopMockUpdates()
        
        for (activityId, activity) in activeActivities {
            await activity.end(dismissalPolicy: dismissalPolicy)
            ITBInfo("Live Activity \(activityId) ended")
        }
        activeActivities.removeAll()
        currentOpponent = nil
    }
    
    // MARK: - Token Management
    
    @MainActor
    private func registerLiveActivityToken(_ token: Data, activityId: String) {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        ITBInfo("Live Activity Token received for activity \(activityId): \(tokenString)")
        
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
    
    // MARK: - Push-to-Start (iOS 17.2+)
    
    @available(iOS 17.2, *)
    public func getPushToStartToken() -> Data? {
        return Activity<IterableLiveActivityAttributes>.pushToStartToken
    }
    
    @available(iOS 17.2, *)
    public func observePushToStartTokenUpdates() {
        Task {
            for await token in Activity<IterableLiveActivityAttributes>.pushToStartTokenUpdates {
                let tokenString = token.map { String(format: "%02x", $0) }.joined()
                ITBInfo("Push-to-start token received: \(tokenString)")
                
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
    
    // MARK: - Accessors
    
    public var activeActivityIds: [String] {
        Array(activeActivities.keys)
    }
}
#endif
