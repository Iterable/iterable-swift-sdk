//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxSessionManagerTests: XCTestCase {
    override class func setUp() {
        super.setUp()
    }
    
    func testSessionIsTracking() {
        let inboxSessionManager = InboxSessionManager()
        
        XCTAssertNil(inboxSessionManager.sessionStartInfo)
        XCTAssertFalse(inboxSessionManager.isTracking)
        
        inboxSessionManager.startSession(visibleRows: [])
        
        XCTAssertNotNil(inboxSessionManager.sessionStartInfo)
        XCTAssertTrue(inboxSessionManager.isTracking)
        
        _ = inboxSessionManager.endSession()
        
        XCTAssertNil(inboxSessionManager.sessionStartInfo)
        XCTAssertFalse(inboxSessionManager.isTracking)
    }
    
    func testSessionInfoStartAndEnd() {
        let inboxSessionManager = InboxSessionManager()
        
        inboxSessionManager.startSession(visibleRows: [])
        
        guard let sessionStartInfo = inboxSessionManager.sessionStartInfo else {
            XCTFail("SessionStartInfo doesn't exist")
            return
        }
        
        XCTAssertNotNil(sessionStartInfo.id)
        XCTAssertNotNil(sessionStartInfo.startTime)
        XCTAssertEqual(sessionStartInfo.totalMessageCount, 0)
        XCTAssertEqual(sessionStartInfo.unreadMessageCount, 0)
        
        let sessionStartId = sessionStartInfo.id
        let sessionStartTime = sessionStartInfo.startTime
        let sessionTotalMessageCount = sessionStartInfo.totalMessageCount
        let sessionUnreadMessageCount = sessionStartInfo.unreadMessageCount
        
        guard let sessionTrackingInfo = inboxSessionManager.endSession() else {
            XCTFail("No SessionInfo from finishing session")
            return
        }
        
        XCTAssertEqual(sessionStartId, sessionTrackingInfo.startInfo.id)
        XCTAssertEqual(sessionStartTime, sessionTrackingInfo.startInfo.startTime)
        XCTAssertEqual(sessionTotalMessageCount, sessionTrackingInfo.startInfo.totalMessageCount)
        XCTAssertEqual(sessionUnreadMessageCount, sessionTrackingInfo.startInfo.unreadMessageCount)
    }
    
    func testUpdateRowTracking() {
        let rowInfo1 = InboxImpressionTracker.RowInfo(messageId: IterableUtil.generateUUID(), silentInbox: false)
        let rowInfo2 = InboxImpressionTracker.RowInfo(messageId: IterableUtil.generateUUID(), silentInbox: true)
        
        let inboxSessionManager = InboxSessionManager()
        
        let initialVisibleImpressions = [rowInfo1]
        
        inboxSessionManager.startSession(visibleRows: initialVisibleImpressions)
        
        usleep(500_000)
        
        inboxSessionManager.updateVisibleRows(visibleRows: [rowInfo1, rowInfo2])
        
        usleep(500_000)
        
        guard let sessionTrackingInfo = inboxSessionManager.endSession() else {
            XCTFail("No SessionInfo from finishing session")
            return
        }
        
        XCTAssertEqual(sessionTrackingInfo.impressions.count, 2)
    }
}
