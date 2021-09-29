//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

public class InboxImpressionTracker {
    public struct Impression {
        let messageId: String
        let silentInbox: Bool
        let displayCount: Int
        let duration: TimeInterval
        
        public func toIterableInboxImpression() -> IterableInboxImpression {
            IterableInboxImpression(messageId: messageId, silentInbox: silentInbox, displayCount: displayCount, displayDuration: duration)
        }
        
        public init(messageId: String, silentInbox: Bool, displayCount: Int, duration: TimeInterval) {
            self.messageId = messageId
            self.silentInbox = silentInbox
            self.displayCount = displayCount
            self.duration = duration
        }
    }
    
    public struct RowInfo {
        let messageId: String
        let silentInbox: Bool
        
        public init(messageId: String, silentInbox: Bool) {
            self.messageId = messageId
            self.silentInbox = silentInbox
        }
    }
    
    func updateVisibleRows(visibleRows: [RowInfo]) {
        let diff = Dwifft.diff(lastVisibleRows, visibleRows)
        guard diff.count > 0 else {
            return
        }
        
        diff.forEach {
            switch $0 {
            case let .insert(_, row):
                startImpression(for: row)
            case let .delete(_, row):
                endImpression(for: row)
            }
        }
        
        lastVisibleRows = visibleRows
    }
    
    func endSession() -> [Impression] {
        startTimes.forEach { endImpression(for: $0.key) }
        return Array(impressions.values)
    }
    
    private func startImpression(for row: RowInfo) {
        assert(startTimes[row] == nil, "Did not expect start time for row: \(row)")
        startTimes[row] = Date()
    }
    
    private func endImpression(for row: RowInfo) {
        guard let startTime = startTimes[row] else {
            ITBError("Could not find startTime for row: \(row)")
            return
        }
        
        startTimes.removeValue(forKey: row)
        
        let duration = Date().timeIntervalSince1970 - startTime.timeIntervalSince1970
        guard duration > minDuration else {
            ITBInfo("duration less than min, not counting impression for row: \(row)")
            return
        }
        
        let impression: Impression
        
        if let existing = impressions[row] {
            impression = Impression(messageId: row.messageId, silentInbox: row.silentInbox, displayCount: existing.displayCount + 1, duration: existing.duration + duration)
        } else {
            impression = Impression(messageId: row.messageId, silentInbox: row.silentInbox, displayCount: 1, duration: duration)
        }
        
        impressions[row] = impression
    }
    
    private let minDuration: TimeInterval = 0.5
    private var lastVisibleRows = [RowInfo]()
    private var startTimes = [RowInfo: Date]()
    private var impressions = [RowInfo: Impression]()
}

extension InboxImpressionTracker.RowInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
    }
}

extension InboxImpressionTracker.RowInfo: Equatable {
    public static func == (lhs: InboxImpressionTracker.RowInfo, rhs: InboxImpressionTracker.RowInfo) -> Bool {
        lhs.messageId == rhs.messageId
    }
}
