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
    // These variables are used for callbacks
    var internalApi: IterableAPIInternal? {get set}
    var inAppSyncDelegate: InAppSynchronizerDelegate? {get set}
    
    // These methods are called on new messages arrive etc.
    func sync()
    func remove(messageId: String)
}

extension IterableInAppTriggerType {
    static let defaultTriggerType = IterableInAppTriggerType.immediate // default is what is chosen by default
    static let undefinedTriggerType = IterableInAppTriggerType.never // undefined is what we select if payload has new trigger type
}

class InAppSilentPushSynchronizer : InAppSynchronizerProtocol {
    weak var internalApi: IterableAPIInternal?
    weak var inAppSyncDelegate: InAppSynchronizerDelegate?
    
    init() {
        ITBInfo()
    }
    
    func sync() {
        ITBInfo()
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
        ITBInfo()
        inAppSyncDelegate?.onInAppRemoved(messageId: messageId)
    }
    
    deinit {
        ITBInfo()
    }
    
    // how many messages to fetch
    private let numMessages = 10
}
