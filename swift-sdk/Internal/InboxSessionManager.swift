//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
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
        sessionStartInfo != nil
    }
    
    init(provideInAppManager: @escaping @autoclosure () -> IterableInAppManagerProtocol = IterableAPI.inAppManager) {
        self.provideInAppManager = provideInAppManager
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
                                            totalMessageCount: provideInAppManager().getInboxMessages().count,
                                            unreadMessageCount: provideInAppManager().getUnreadInboxMessagesCount())
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
    
    private let provideInAppManager: () -> IterableInAppManagerProtocol
}
