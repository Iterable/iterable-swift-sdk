//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

///
protocol InAppSynchronizerProtocol {
    // Fetch from server and sync
    func sync() -> Future<[IterableInAppMessage]>
}

/// For callbacks when silent push notifications arrive
protocol InAppNotifiable {
    func onInAppSyncNeeded()
    func onInAppRemoved(messageId: String)
}

extension IterableInAppTriggerType {
    static let defaultTriggerType = IterableInAppTriggerType.immediate // default is what is chosen by default
    static let undefinedTriggerType = IterableInAppTriggerType.never // undefined is what we select if payload has new trigger type
}

class InAppSynchronizer : InAppSynchronizerProtocol {
    init() {
        ITBInfo()
    }
    
    func sync() -> Future<[IterableInAppMessage]> {
        ITBInfo()
        guard let internalApi = IterableAPI.internalImplementation else {
            ITBError("Invalid state: expected InternalApi")
            return Promise(error: IterableError.general(description: "Invalid state: expected InternalApi"))
        }

        return InAppHelper.getInAppMessagesFromServer(internalApi: internalApi, number: numMessages)
    }

    deinit {
        ITBInfo()
    }
    
    // how many messages to fetch
    private let numMessages = 100
}
