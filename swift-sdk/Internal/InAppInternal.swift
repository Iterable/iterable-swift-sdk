//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

protocol InAppFetcherProtocol {
    // Fetch from server and sync
    func fetch() -> Future<[IterableInAppMessage], Error>
}

/// For callbacks when silent push notifications arrive
protocol InAppNotifiable {
    func scheduleSync() -> Future<Bool, Error>
    func onInAppRemoved(messageId: String)
}

extension IterableInAppTriggerType {
    static let defaultTriggerType = IterableInAppTriggerType.immediate // default is what is chosen by default
    static let undefinedTriggerType = IterableInAppTriggerType.never // undefined is what we select if payload has new trigger type
}

class InAppFetcher: InAppFetcherProtocol {
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
        
        return InAppHelper.getInAppMessagesFromServer(apiClient: apiClient, number: numMessages).mapFailure { $0 }
    }
    
    private weak var apiClient: ApiClientProtocol?
    
    deinit {
        ITBInfo()
    }
    
    // how many messages to fetch
    private let numMessages = 100
}

public struct InAppMessageContext {
    let message: IterableInAppMessage
    let location: InAppLocation?
    let deviceMetadata: DeviceMetadata
    
    func toDictionary() -> [AnyHashable: Any] {
        var context = [AnyHashable: Any]()
        
        context.setValue(for: .saveToInbox, value: message.saveToInbox)
        
        context.setValue(for: .silentInbox, value: message.saveToInbox && message.trigger.type == .never)
        
        if let location = location {
            context.setValue(for: .inAppLocation, value: location)
        }
        
        context.setValue(for: .deviceInfo, value: InAppMessageContext.translateDeviceMetadata(metadata: deviceMetadata))
        
        return context
    }
    
    private static func translateDeviceMetadata(metadata: DeviceMetadata) -> [AnyHashable: Any] {
        var dict = [AnyHashable: Any]()
        
        dict.setValue(for: .deviceId, value: metadata.deviceId)
        dict.setValue(for: .platform, value: metadata.platform)
        dict.setValue(for: .appPackageName, value: metadata.appPackageName)
        
        return dict
    }
}
