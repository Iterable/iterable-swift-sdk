//
//  Created by Jay Kim on 12/3/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxImpressionTrackerTests: XCTestCase {
    func testToIterableInboxImpression() {
        let messageId = IterableUtil.generateUUID()
        let silentInbox = true
        let displayCount = 5
        let duration = 7.31
        
        let inboxImpression = IterableInboxImpression(messageId: messageId,
                                                      silentInbox: silentInbox,
                                                      displayCount: displayCount,
                                                      displayDuration: duration)
        
        let convertedImpression = InboxImpressionTracker.Impression(messageId: messageId,
                                                                    silentInbox: silentInbox,
                                                                    displayCount: displayCount,
                                                                    duration: duration).toIterableInboxImpression()
        
        XCTAssertEqual(inboxImpression.messageId, convertedImpression.messageId)
        XCTAssertEqual(inboxImpression.silentInbox, convertedImpression.silentInbox)
        XCTAssertEqual(inboxImpression.displayCount, convertedImpression.displayCount)
        XCTAssertEqual(inboxImpression.displayDuration, convertedImpression.displayDuration)
    }
    
    func testUpdateVisibleRows() {
        let rowInfo1 = InboxImpressionTracker.RowInfo(messageId: IterableUtil.generateUUID(), silentInbox: false)
        let rowInfo2 = InboxImpressionTracker.RowInfo(messageId: IterableUtil.generateUUID(), silentInbox: true)
        let rowInfo3 = InboxImpressionTracker.RowInfo(messageId: IterableUtil.generateUUID(), silentInbox: false)
        
        let tracker = InboxImpressionTracker()
        
        tracker.updateVisibleRows(visibleRows: [rowInfo1])
        
        usleep(500_000)
        
        tracker.updateVisibleRows(visibleRows: [rowInfo2])
        
        usleep(500_000)
        
        tracker.updateVisibleRows(visibleRows: [rowInfo1, rowInfo2])
        
        usleep(500_000)
        
        tracker.updateVisibleRows(visibleRows: [rowInfo1, rowInfo2, rowInfo3])
        
        usleep(100_000)
        
        let impressions = tracker.endSession()
        
        XCTAssertTrue(impressions.contains(where: { $0.messageId == rowInfo1.messageId }))
        XCTAssertTrue(impressions.contains(where: { $0.messageId == rowInfo2.messageId }))
    }
    
    func testRowInfoHashableEquatable() {
        let messageId = IterableUtil.generateUUID()
        
        let randomValue = 6894
        
        let rowInfo = InboxImpressionTracker.RowInfo(messageId: messageId, silentInbox: true)
        
        let dict = [rowInfo: randomValue]
        
        XCTAssertEqual(randomValue, dict[InboxImpressionTracker.RowInfo(messageId: messageId, silentInbox: true)])
    }
}
