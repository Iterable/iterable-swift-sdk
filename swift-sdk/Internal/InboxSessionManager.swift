//
//  Created by Tapash Majumder on 9/12/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

class InboxSessionManager {
    struct SessionInfo {
        let startInfo: SessionStartInfo
        let impressions: [InboxImpressionTracker.Impression]
    }
    
    struct SessionStartInfo {
        let id: String
        let startTime: Date
        let totalMessageCount: Int
        let unreadMessageCount: Int
    }
    
    var sessionStartInfo: SessionStartInfo?
    var impressionTracker: InboxImpressionTracker?
    var startSessionWhenAppMovesToForeground = false
    
    var isTracking: Bool {
        return sessionStartInfo != nil
    }
    
    func updateVisibleRows(visibleRows: [InboxImpressionTracker.RowInfo]) {
        guard let impressionTracker = impressionTracker else {
            ITBError("Expecting impressionTracker here.")
            return
        }
        
        impressionTracker.updateVisibleRows(visibleRows: visibleRows)
    }
    
    func startSession(visibleRows: [InboxImpressionTracker.RowInfo]) {
        ITBInfo()
        
        guard isTracking == false else {
            ITBError("Session started twice")
            return
        }
        
        ITBInfo("Session Start")
        
        sessionStartInfo = SessionStartInfo(id: IterableUtil.generateUUID(),
                                            startTime: Date(),
                                            totalMessageCount: IterableAPI.inAppManager.getInboxMessages().count,
                                            unreadMessageCount: IterableAPI.inAppManager.getUnreadInboxMessagesCount())
        impressionTracker = InboxImpressionTracker()
        updateVisibleRows(visibleRows: visibleRows)
    }
    
    func endSession() -> SessionInfo? {
        guard let sessionStartInfo = sessionStartInfo, let impressionTracker = impressionTracker else {
            ITBError("Session ended without start")
            return nil
        }
        
        ITBInfo("Session End")
        
        let sessionInfo = SessionInfo(startInfo: sessionStartInfo, impressions: impressionTracker.endSession())
        self.sessionStartInfo = nil
        self.impressionTracker = nil
        
        return sessionInfo
    }
}
