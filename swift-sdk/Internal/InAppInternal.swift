//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

///
protocol InAppFetcherProtocol {
    // Fetch from server and sync
    func fetch() -> Future<[IterableInAppMessage]>
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

class InAppFetcher : InAppFetcherProtocol {
    init(internalApi: IterableAPIInternal) {
        ITBInfo()
        self.internalApi = internalApi
    }
    
    func fetch() -> Future<[IterableInAppMessage]> {
        ITBInfo()
        guard let internalApi = internalApi else {
            ITBError("Invalid state: expected InternalApi")
            return Promise(error: IterableError.general(description: "Invalid state: expected InternalApi"))
        }

        return InAppHelper.getInAppMessagesFromServer(internalApi: internalApi, number: numMessages)
    }

    private weak var internalApi: IterableAPIInternal?
    
    deinit {
        ITBInfo()
    }
    
    // how many messages to fetch
    private let numMessages = 100
}
