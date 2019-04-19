//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

/// Callbacks from the synchronizer
protocol InAppSynchronizerDelegate : class {
    func onInAppRemoved(messageId: String)
    func onInAppMessagesAvailable(messages: [IterableInAppMessage])
}

///
protocol InAppSynchronizerProtocol {
    var inAppSyncDelegate: InAppSynchronizerDelegate? {get set}
    
    // Fetch from server and sync
    func sync()
}

extension IterableInAppTriggerType {
    static let defaultTriggerType = IterableInAppTriggerType.immediate // default is what is chosen by default
    static let undefinedTriggerType = IterableInAppTriggerType.never // undefined is what we select if payload has new trigger type
}

class InAppSynchronizer : InAppSynchronizerProtocol {
    weak var inAppSyncDelegate: InAppSynchronizerDelegate?
    
    init() {
        ITBInfo()
    }
    
    func sync() {
        ITBInfo()
        guard let internalApi = IterableAPI.internalImplementation else {
            ITBError("Invalid state: expected InternalApi")
            return
        }
        
        InAppHelper.getInAppMessagesFromServer(internalApi: internalApi, number: numMessages).onSuccess {
            self.inAppSyncDelegate?.onInAppMessagesAvailable(messages: $0)
        }.onError {
            ITBError($0.localizedDescription)
        }
    }
    
    deinit {
        ITBInfo()
    }
    
    // how many messages to fetch
    private let numMessages = 10
}
