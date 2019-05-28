//
//
//  Created by Tapash Majumder on 5/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

class FetchOperation : AsyncOperation {
    init(fetcher: InAppFetcherProtocol) {
        self.fetcher = fetcher
    }
    
    var result: Result<[IterableInAppMessage], Error>?
    
    override func start() {
        ITBDebug()
        isExecuting = true
        fetcher.fetch().onSuccess { (messages) in
            self.result = .success(messages)
            self.isExecuting = false
            self.isFinished = true
            }.onError { error in
                self.result = .failure(error)
                self.isExecuting = false
                self.isFinished = true
        }
    }
    
    private var fetcher: InAppFetcherProtocol
}

class ProcessMessagesOperation : AsyncOperation {
    init(inAppManager: InAppManager) {
        self.inAppManager = inAppManager
    }
    
    var result: Result<[IterableInAppMessage], Error>?
    
    override func start() {
        ITBDebug()
        isExecuting = true
        inAppManager.processMessages()
        self.isExecuting = false
        self.isFinished = true
    }
    
    private var inAppManager: InAppManager
}

class HandleMessagesObtainedOperation : AsyncOperation {
    init(inAppManager: InAppManager) {
        self.inAppManager = inAppManager
    }
    
    var inboxChanged = false
    
    override func start() {
        ITBDebug()
        isExecuting = true
        guard let messages = messages else {
            ITBError("Errored getting messages")
            isExecuting = false
            isFinished = true
            return
        }
        
        // Remove messages that are no present in server
        let deletedInboxCount = self.removeDeletedMessages(messagesFromServer: messages)
        
        // add new ones
        let addedInboxCount = self.addNewMessages(messagesFromServer: messages)
        
        if deletedInboxCount + addedInboxCount > 0 {
            inboxChanged = true
        }
        
        isExecuting = false
        isFinished = true
    }
    
    private var messages: [IterableInAppMessage]? {
        guard let fetchOperation = dependencies.first as? FetchOperation, let fetchResult = fetchOperation.result else {
            return nil
        }
        if case let Result.success(messages) = fetchResult {
            return messages
        } else {
            return nil
        }
    }
    
    private let inAppManager: InAppManager
    
    // return count of deleted inbox messages
    private func removeDeletedMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
        var inboxCount = 0
        let removedMessages = getRemovedMessages(messagesFromServer: messages)
        removedMessages.forEach {
            if $0.saveToInbox == true {
                inboxCount += 1
            }
            inAppManager.messagesMap.removeValue(forKey: $0.messageId)
        }
        return inboxCount
    }
    
    // given `messages` coming for server, find messages that need to be removed
    private func getRemovedMessages(messagesFromServer messages: [IterableInAppMessage]) -> [IterableInAppMessage] {
        return inAppManager.messagesMap.values.reduce(into: [IterableInAppMessage]()) { (result, message) in
            if !messages.contains(where: { $0.messageId == message.messageId }) {
                result.append(message)
            }
        }
    }
    
    // returns count of inbox messages (save to inbox)
    private func addNewMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
        var inboxCount = 0
        messages.forEach { message in
            if !inAppManager.messagesMap.contains(where: { $0.key == message.messageId }) {
                if message.saveToInbox == true {
                    inboxCount += 1
                }
                inAppManager.messagesMap[message.messageId] = message
            }
        }
        return inboxCount
    }
}

