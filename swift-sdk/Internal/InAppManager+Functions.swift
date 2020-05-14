//
//  Created by Tapash Majumder on 5/30/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum MessagesProcessorResult {
    case show(message: IterableInAppMessage, messagesMap: OrderedDictionary<String, IterableInAppMessage>)
    case noShow(messagesMap: OrderedDictionary<String, IterableInAppMessage>)
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
        case .none, .wait:
            return .noShow(messagesMap: messagesMap)
        }
    }
    
    private enum ProcessNextMessageResult {
        case show(IterableInAppMessage)
        case skip(IterableInAppMessage)
        case none
        case wait
    }
    
    private func processNextMessage() -> ProcessNextMessageResult {
        ITBDebug()
        
        guard let message = getFirstProcessableTriggeredMessage() else {
            ITBDebug("No message to process, totalMessages: \(messagesMap.values.count)") //ttt
            return .none
        }
        
        ITBDebug("processing message with id: \(message.messageId)")
        
        if inAppDisplayChecker.isOkToShowNow(message: message) {
            ITBDebug("isOkToShowNow")
            if inAppDelegate.onNew(message: message) == .show {
                ITBDebug("delegate returned show")
                return .show(message)
            } else {
                ITBDebug("delegate returned skip")
                return .skip(message)
            }
        } else {
            ITBDebug("Not ok to show now")
            
            return .wait
        }
    }
    
    private func getFirstProcessableTriggeredMessage() -> IterableInAppMessage? {
        return messagesMap.values.filter(MessagesProcessor.isProcessableTriggeredMessage).first
    }
    
    private static func isProcessableTriggeredMessage(_ message: IterableInAppMessage) -> Bool {
        return message.didProcessTrigger == false && message.trigger.type == .immediate
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
        
        let removedInboxCount = removedMessages.reduce(0) { $1.saveToInbox == true ? $0 + 1 : $0 }
        let addedInboxCount = addedMessages.reduce(0) { $1.saveToInbox == true ? $0 + 1 : $0 }
        
        var newMessagesMap = OrderedDictionary<String, IterableInAppMessage>()
        messages.forEach {
            if let existingMessage = messagesMap[$0.messageId] {
                newMessagesMap[$0.messageId] = existingMessage
            } else {
                newMessagesMap[$0.messageId] = $0
            }
        }
        
        return MergeMessagesResult(inboxChanged: removedInboxCount + addedInboxCount > 0,
                                   messagesMap: newMessagesMap,
                                   deliveredMessages: addedMessages)
    }
    
    private let messagesMap: OrderedDictionary<String, IterableInAppMessage>
    private let messages: [IterableInAppMessage]
}
