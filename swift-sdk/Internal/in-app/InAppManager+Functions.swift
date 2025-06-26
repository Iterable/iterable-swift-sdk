//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum MessagesProcessorResult {
    case show(message: IterableInAppMessage, messagesMap: OrderedDictionary<String, IterableInAppMessage>)
    case noShow(message: IterableInAppMessage?, messagesMap: OrderedDictionary<String, IterableInAppMessage>)
}

struct MessagesProcessor {
    init(inAppDelegate: IterableInAppDelegate,
         inAppDisplayChecker: InAppDisplayChecker,
         messagesMap: OrderedDictionary<String, IterableInAppMessage>) {
        ITBInfo()
        
        self.inAppDelegate = inAppDelegate
        self.inAppDisplayChecker = inAppDisplayChecker
        self.messagesMap = messagesMap
    }
    
    mutating func processMessages() -> MessagesProcessorResult {
        ITBDebug()
        
        switch processNextMessage() {
        case let .show(message):
            updateMessage(message, didProcessTrigger: true, consumed: !message.saveToInbox)
            return .show(message: message, messagesMap: messagesMap)
        case let .skip(message):
            updateMessage(message, didProcessTrigger: true)
            return processMessages()
        case let .skipAndConsume(message):
            updateMessage(message, didProcessTrigger: true, consumed: true)
            return .noShow(message: message, messagesMap: messagesMap)
        case .none, .wait:
            return .noShow(message: nil, messagesMap: messagesMap)
        }
    }
    
    private enum ProcessNextMessageResult {
        case show(IterableInAppMessage)
        case skip(IterableInAppMessage)
        case skipAndConsume(IterableInAppMessage)
        case none
        case wait
    }
    
    private func processNextMessage() -> ProcessNextMessageResult {
        ITBDebug()
        
        guard let message = getFirstProcessableTriggeredMessage() else {
            ITBDebug("No message to process, totalMessages: \(messagesMap.values.count)") // ttt
            return .none
        }
        
        ITBDebug("processing message with id: \(message.messageId)")
        
        guard inAppDisplayChecker.isOkToShowNow(message: message) else {
            ITBDebug("Not ok to show now")
            return .wait
        }
        
        ITBDebug("isOkToShowNow")
        
        let returnValue = inAppDelegate.onNew(message: message)
        if message.isJsonOnly {
            return .skipAndConsume(message)
        }
        if returnValue == .show {
            ITBDebug("delegate returned show")
            return .show(message)
        } else {
            ITBDebug("delegate returned skip")
            return .skip(message)
        }
    }
    
    private func getFirstProcessableTriggeredMessage() -> IterableInAppMessage? {
        messagesMap.values
            .filter(MessagesProcessor.isProcessableTriggeredMessage)
            .sorted { $0.priorityLevel < $1.priorityLevel }
            .first
    }
    
    private static func isProcessableTriggeredMessage(_ message: IterableInAppMessage) -> Bool {
        !message.didProcessTrigger && message.trigger.type == .immediate && !message.read
    }
    
    private mutating func updateMessage(_ message: IterableInAppMessage, didProcessTrigger: Bool? = nil, consumed: Bool? = nil) {
        ITBDebug()
        
        let toUpdate = message
        
        if let didProcessTrigger = didProcessTrigger {
            toUpdate.didProcessTrigger = didProcessTrigger
        }
        
        if let consumed = consumed {
            toUpdate.consumed = consumed
        }
        
        messagesMap.updateValue(toUpdate, forKey: message.messageId)
    }
    
    private let inAppDelegate: IterableInAppDelegate
    private let inAppDisplayChecker: InAppDisplayChecker
    private var messagesMap: OrderedDictionary<String, IterableInAppMessage>
}

struct MergeMessagesResult {
    let inboxChanged: Bool
    let messagesMap: OrderedDictionary<String, IterableInAppMessage>
    let deliveredMessages: [IterableInAppMessage]
}

/// Merges the results and determines whether inbox changed needs to be fired.
struct MessagesObtainedHandler {
    init(messagesMap: OrderedDictionary<String, IterableInAppMessage>, messages: [IterableInAppMessage]) {
        ITBInfo()
        self.messagesMap = messagesMap
        self.messages = messages
    }
    
    func handle() -> MergeMessagesResult {
        let removedMessages = messagesMap.values.filter { existingMessage in !messages.contains(where: { $0.messageId == existingMessage.messageId }) }
        
        let addedMessages = messages.filter { !messagesMap.keys.contains($0.messageId) }
        
        let removedInboxCount = removedMessages.reduce(0) { $1.saveToInbox ? $0 + 1 : $0 }
        let addedInboxCount = addedMessages.reduce(0) { $1.saveToInbox ? $0 + 1 : $0 }
        
        var messagesOverwritten = 0
        var newMessagesMap = OrderedDictionary<String, IterableInAppMessage>()
        messages.forEach { serverMessage in
            let messageId = serverMessage.messageId
            if let existingMessage = messagesMap[messageId] {
                if Self.shouldOverwrite(clientMessage: existingMessage, withServerMessage: serverMessage) {
                    newMessagesMap[messageId] = serverMessage
                    messagesOverwritten += 1
                } else {
                    newMessagesMap[messageId] = existingMessage
                }
            } else {
                newMessagesMap[messageId] = serverMessage
            }
        }
        
        let deliveredMessages = addedMessages.filter { $0.read != true }
        
        return MergeMessagesResult(inboxChanged: removedInboxCount + addedInboxCount + messagesOverwritten > 0,
                                   messagesMap: newMessagesMap,
                                   deliveredMessages: deliveredMessages)
    }
    
    private let messagesMap: OrderedDictionary<String, IterableInAppMessage>
    private let messages: [IterableInAppMessage]

    // We should only overwrite if the server is read and client is not read.
    // This is because some client changes may not have propagated to server yet.
    private static func shouldOverwrite(clientMessage: IterableInAppMessage,
                                        withServerMessage serverMessage: IterableInAppMessage) -> Bool {
        serverMessage.read && !clientMessage.read
    }
}
