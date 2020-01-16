//
//  Created by Tapash Majumder on 1/14/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockInAppFetcher: InAppFetcherProtocol {
    init() {
        ITBInfo()
    }
    
    func fetch() -> Future<[IterableInAppMessage], Error> {
        ITBInfo()
        
        return Promise(value: messagesMap.values)
    }
    
    @discardableResult func loadMessages(from file: String, withExtension ext: String) -> Future<Void, Error> {
        ITBInfo()
        let data = DataManager.loadData(from: file, withExtension: ext)
        let payload = try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
        let messages = InAppMessageParser.parse(payload: payload).compactMap(MockInAppFetcher.parseResultToOptionalMessage)
        
        messagesMap = OrderedDictionary<String, IterableInAppMessage>()
        
        messages.forEach {
            messagesMap[$0.messageId] = $0
        }
        
        let result = Promise<Void, Error>()
        
        let inAppManager = (IterableAPI.inAppManager as! IterableInAppManagerProtocolInternal)
        inAppManager.scheduleSync().onSuccess { _ in
            result.resolve(with: ())
        }
        
        return result
    }
    
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>()
    
    private static func parseResultToOptionalMessage(result: IterableResult<IterableInAppMessage, InAppMessageParser.ParseError>) -> IterableInAppMessage? {
        switch result {
        case .failure:
            return nil
        case let .success(message):
            return message
        }
    }
}
