//
//  Copyright © 2025 Iterable. All rights reserved.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Run Data Models

/// Available runners to compare against
public enum RunnerName: String, CaseIterable, Codable {
    case alex = "Alex"
    case jamie = "Jamie"
    case taylor = "Taylor"
    case sam = "Sam"
}

/// Pace levels for pre-recorded runs
public enum PaceLevel: String, CaseIterable, Codable {
    case easy = "Easy"
    case normal = "Normal"
    case fast = "Fast"
    case extreme = "Extreme"
}

/// Pre-recorded run data for comparison
public struct RecordedRun: Codable, Hashable {
    public let runnerName: RunnerName
    public let paceLevel: PaceLevel
    /// Pace in seconds per kilometer
    public let paceSecondsPerKm: Int
    /// Heart rate in BPM
    public let bpm: Int
    
    public init(runnerName: RunnerName, paceLevel: PaceLevel, paceSecondsPerKm: Int, bpm: Int) {
        self.runnerName = runnerName
        self.paceLevel = paceLevel
        self.paceSecondsPerKm = paceSecondsPerKm
        self.bpm = bpm
    }
    
    /// Formatted pace string (e.g., "5:30/km")
    public var formattedPace: String {
        let minutes = paceSecondsPerKm / 60
        let seconds = paceSecondsPerKm % 60
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

/// Static data store for pre-recorded runs
public struct RunDataStore {
    
    // MARK: - Pre-recorded Run Data
    // Pace in seconds/km, BPM for each runner at each pace level
    
    private static let runData: [RunnerName: [PaceLevel: (pace: Int, bpm: Int)]] = [
        .alex: [
            .easy: (pace: 390, bpm: 125),     // 6:30/km
            .normal: (pace: 330, bpm: 145),   // 5:30/km
            .fast: (pace: 285, bpm: 165),     // 4:45/km
            .extreme: (pace: 240, bpm: 185)   // 4:00/km
        ],
        .jamie: [
            .easy: (pace: 420, bpm: 120),     // 7:00/km
            .normal: (pace: 360, bpm: 140),   // 6:00/km
            .fast: (pace: 300, bpm: 160),     // 5:00/km
            .extreme: (pace: 255, bpm: 180)   // 4:15/km
        ],
        .taylor: [
            .easy: (pace: 375, bpm: 130),     // 6:15/km
            .normal: (pace: 315, bpm: 150),   // 5:15/km
            .fast: (pace: 270, bpm: 170),     // 4:30/km
            .extreme: (pace: 225, bpm: 190)   // 3:45/km
        ],
        .sam: [
            .easy: (pace: 405, bpm: 122),     // 6:45/km
            .normal: (pace: 345, bpm: 142),   // 5:45/km
            .fast: (pace: 292, bpm: 162),     // 4:52/km
            .extreme: (pace: 248, bpm: 182)   // 4:08/km
        ]
    ]
    
    /// Our fixed pace for the mocked current run (5:20/km = 320 seconds/km)
    public static let currentRunnerPaceSecondsPerKm: Int = 320
    public static let currentRunnerBaseBpm: Int = 148
    
    /// Get a pre-recorded run for a runner at a specific pace level
    public static func getRecordedRun(runner: RunnerName, pace: PaceLevel) -> RecordedRun {
        let data = runData[runner]![pace]!
        return RecordedRun(
            runnerName: runner,
            paceLevel: pace,
            paceSecondsPerKm: data.pace,
            bpm: data.bpm
        )
    }
    
    /// Calculate distance covered at a given pace over elapsed time
    /// - Parameters:
    ///   - paceSecondsPerKm: Pace in seconds per kilometer
    ///   - elapsedSeconds: Total elapsed time in seconds
    /// - Returns: Distance in meters
    public static func distanceForPace(_ paceSecondsPerKm: Int, elapsedSeconds: TimeInterval) -> Double {
        guard paceSecondsPerKm > 0 else { return 0 }
        return (elapsedSeconds / Double(paceSecondsPerKm)) * 1000.0
    }
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
/// Attributes for the Iterable Live Activity - Run Tracking with Comparison
public struct IterableLiveActivityAttributes: ActivityAttributes, Codable {
    
    /// The opponent's pre-recorded run we're comparing against
    public let opponent: RecordedRun
    
    public struct ContentState: Codable, Hashable {
        // Current runner stats
        public let elapsedSeconds: TimeInterval
        public let currentDistanceMeters: Double
        public let currentPaceSecondsPerKm: Int
        public let currentBpm: Int
        
        // Comparison stats
        public let opponentDistanceMeters: Double
        /// Positive = ahead, negative = behind
        public let distanceDifferenceMeters: Double
        
        public init(
            elapsedSeconds: TimeInterval,
            currentDistanceMeters: Double,
            currentPaceSecondsPerKm: Int,
            currentBpm: Int,
            opponentDistanceMeters: Double,
            distanceDifferenceMeters: Double
        ) {
            self.elapsedSeconds = elapsedSeconds
            self.currentDistanceMeters = currentDistanceMeters
            self.currentPaceSecondsPerKm = currentPaceSecondsPerKm
            self.currentBpm = currentBpm
            self.opponentDistanceMeters = opponentDistanceMeters
            self.distanceDifferenceMeters = distanceDifferenceMeters
        }
        
        // MARK: - Formatted Values
        
        public var formattedElapsedTime: String {
            let minutes = Int(elapsedSeconds) / 60
            let seconds = Int(elapsedSeconds) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
        
        public var formattedCurrentPace: String {
            let minutes = currentPaceSecondsPerKm / 60
            let seconds = currentPaceSecondsPerKm % 60
            return String(format: "%d:%02d/km", minutes, seconds)
        }
        
        public var formattedCurrentDistance: String {
            if currentDistanceMeters >= 1000 {
                return String(format: "%.2f km", currentDistanceMeters / 1000)
            }
            return String(format: "%.0f m", currentDistanceMeters)
        }
        
        public var formattedDistanceDifference: String {
            let absDistance = abs(distanceDifferenceMeters)
            let prefix = distanceDifferenceMeters >= 0 ? "+" : "-"
            if absDistance >= 1000 {
                return String(format: "%@%.2f km", prefix, absDistance / 1000)
            }
            return String(format: "%@%.0f m", prefix, absDistance)
        }
        
        public var isAhead: Bool {
            distanceDifferenceMeters >= 0
        }
    }
    
    public init(opponent: RecordedRun) {
        self.opponent = opponent
    }
}
#endif
