//
//  Created by Tapash Majumder on 9/12/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

class InboxImpressionTracker {
    struct Impression {
        let messageId: String
        let silentInbox: Bool
        let displayCount: Int
        let duration: TimeInterval
        
        func toIterableInboxImpression() -> IterableInboxImpression {
            return IterableInboxImpression(messageId: messageId, silentInbox: silentInbox, displayCount: displayCount, displayDuration: duration)
        }
    }
    
    struct RowInfo {
        let messageId: String
        let silentInbox: Bool
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
    func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
    }
}

extension InboxImpressionTracker.RowInfo: Equatable {
    static func == (lhs: InboxImpressionTracker.RowInfo, rhs: InboxImpressionTracker.RowInfo) -> Bool {
        return lhs.messageId == rhs.messageId
    }
}
