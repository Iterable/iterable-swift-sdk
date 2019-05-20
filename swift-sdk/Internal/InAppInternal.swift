//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

///
protocol InAppFetcherProtocol {
    // Fetch from server and sync
    func fetch() -> Future<[IterableInAppMessage], Error>
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
    init(apiClient: ApiClientProtocol) {
        ITBInfo()
        self.apiClient = apiClient
    }
    
    func fetch() -> Future<[IterableInAppMessage], Error> {
        ITBInfo()
        guard let apiClient = apiClient else {
            ITBError("Invalid state: expected ApiClient")
            return Promise(error: IterableError.general(description: "Invalid state: expected InternalApi"))
        }
        return InAppHelper.getInAppMessagesFromServer(apiClient: apiClient, number: numMessages).mapFailure {$0}
    }

    private weak var apiClient: ApiClientProtocol?
    
    deinit {
        ITBInfo()
    }
    
    // how many messages to fetch
    private let numMessages = 100
}
