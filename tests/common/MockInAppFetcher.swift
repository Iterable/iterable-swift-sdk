//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockInAppFetcher: InAppFetcherProtocol {
    var syncCallback: (() -> Void)?
    
    init(messages: [IterableInAppMessage] = []) {
        ITBInfo()
        for message in messages {
            messagesMap[message.messageId] = message
        }
    }
    
    deinit {
        ITBInfo()
    }
    
    func fetch() -> Pending<[IterableInAppMessage], Error> {
        ITBInfo()
        
        syncCallback?()
        
        return Fulfill(value: messagesMap.values)
    }
    
    @discardableResult func mockMessagesAvailableFromServer(internalApi: InternalIterableAPI?, messages: [IterableInAppMessage]) -> Pending<Int, Error> {
        ITBInfo()
        
        messagesMap = OrderedDictionary<String, IterableInAppMessage>()
        
        messages.forEach {
            messagesMap[$0.messageId] = $0
        }
        
        let result = Fulfill<Int, Error>()
        
        let inAppManager = internalApi?.inAppManager
        inAppManager?.scheduleSync().onSuccess { [weak inAppManager = inAppManager] _ in
            result.resolve(with: inAppManager?.getMessages().count ?? 0)
        }
        
        return result
    }
    
    @discardableResult func mockInAppPayloadFromServer(internalApi: InternalIterableAPI?, _ payload: [AnyHashable: Any]) -> Pending<Int, Error> {
        ITBInfo()
        return mockMessagesAvailableFromServer(internalApi: internalApi, messages: InAppTestHelper.inAppMessages(fromPayload: payload))
    }
    
    func add(message: IterableInAppMessage) {
        messagesMap[message.messageId] = message
    }
    
    var messages: [IterableInAppMessage] {
        messagesMap.values
    }
    
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>()
}
