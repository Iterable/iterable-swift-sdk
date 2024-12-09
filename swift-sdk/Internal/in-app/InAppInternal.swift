//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

protocol InAppFetcherProtocol {
    func fetch() -> Pending<[IterableInAppMessage], Error>
}

/// For callbacks when silent push notifications arrive
protocol InAppNotifiable: AnyObject {
    func scheduleSync() -> Pending<Bool, Error>
    func onInAppRemoved(messageId: String)
    func reset() -> Pending<Bool, Error>
}

extension IterableInAppTriggerType {
    static let defaultTriggerType = IterableInAppTriggerType.immediate // default is what is chosen by default
    static let undefinedTriggerType = IterableInAppTriggerType.never // undefined is what we select if payload has new trigger type
}

struct IterableInAppMessageMetadata {
    let message: IterableInAppMessage
    let location: InAppLocation
}

class InAppFetcher: InAppFetcherProtocol {
    init(apiClient: ApiClientProtocol) {
        ITBInfo()
        self.apiClient = apiClient
    }
    
    deinit {
        ITBInfo()
    }
    
    func fetch() -> Pending<[IterableInAppMessage], Error> {
        ITBInfo()
        
        guard let apiClient = apiClient else {
            ITBError("Invalid state: expected ApiClient")
            return Fulfill(error: IterableError.general(description: "Invalid state: expected InternalApi"))
        }
        
        return InAppHelper.getInAppMessagesFromServer(apiClient: apiClient, number: numMessages).mapFailure { $0 }
    }
    
    // MARK: - Private/Internal
    
    private weak var apiClient: ApiClientProtocol?
    
    private let numMessages = 100
}

struct InAppMessageContext {
    let messageId: String
    let saveToInbox: Bool
    let silentInbox: Bool
    let location: InAppLocation?
    
    /// the inbox session ID associated with this in-app message (nil if standalone)
    var inboxSessionId: String?
    
    static func from(message: IterableInAppMessage, location: InAppLocation?, inboxSessionId: String? = nil) -> InAppMessageContext {
        InAppMessageContext(messageId: message.messageId,
                            saveToInbox: message.saveToInbox,
                            silentInbox: message.silentInbox,
                            location: location,
                            inboxSessionId: inboxSessionId)
    }
    
    /// For backward compatibility, assume .inApp
    static func from(messageId: String, deviceMetadata _: DeviceMetadata) -> InAppMessageContext {
        InAppMessageContext(messageId: messageId,
                            saveToInbox: false,
                            silentInbox: false,
                            location: .inApp,
                            inboxSessionId: nil)
    }
    
    func toMessageContextDictionary() -> [AnyHashable: Any] {
        var context = [AnyHashable: Any]()
        
        context.setValue(for: JsonKey.saveToInbox, value: saveToInbox)
        context.setValue(for: JsonKey.silentInbox, value: silentInbox)
        
        if let location = location {
            context.setValue(for: JsonKey.inAppLocation, value: location)
        }
        
        return context
    }
}
