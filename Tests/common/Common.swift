//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

struct TestConsts {
    static let userDefaultsSuiteName = "testUserDefaults"
}

/// Add Utility methods common to multiple targets here.
/// We can't use TestUtils in all tests because TestUtils targets Swift tests only.
struct TestHelper {
    static func getTestUserDefaults() -> UserDefaults {
        return UserDefaults(suiteName: TestConsts.userDefaultsSuiteName)!
    }
    
    static func clearTestUserDefaults() {
        getTestUserDefaults().removePersistentDomain(forName: TestConsts.userDefaultsSuiteName)
    }
}

class InAppPollingSynchronizer : InAppSynchronizerProtocol {
    weak var internalApi: IterableAPIInternal?
    weak var inAppSyncDelegate: InAppSynchronizerDelegate?
    
    init() {
        ITBInfo()
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] timer in
                self?.sync(timer: timer)
            }
        } else {
            // Fallback on earlier versions
            Timer.scheduledTimer(timeInterval: syncInterval, target: self, selector: #selector(sync(timer:)), userInfo: nil, repeats: true)
        }
    }
    
    func sync() {
        guard let internalApi = self.internalApi else {
            ITBError("Invalid state: expected InternalApi")
            return
        }
        
        InAppHelper.getInAppMessagesFromServer(internalApi: internalApi, number: numMessages).onSuccess {
            if $0.count > 0 {
                self.inAppSyncDelegate?.onInAppMessagesAvailable(messages: $0)
            }
            }.onError {
                ITBError($0.localizedDescription)
        }
    }
    
    func remove(messageId: String) {
        inAppSyncDelegate?.onInAppRemoved(messageId: messageId)
    }
    
    @objc private func sync(timer: Timer) {
        self.timer = timer
        
        sync()
    }
    
    deinit {
        ITBInfo()
        timer?.invalidate()
    }
    
    // in seconds
    private let syncInterval = 1.0
    private let numMessages = 10
    private var timer: Timer?
}

