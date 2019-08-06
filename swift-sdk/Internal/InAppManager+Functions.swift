//
//
//  Created by Tapash Majumder on 5/30/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum ProcessMessagesResult {
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
    
    mutating func processMessages() -> ProcessMessagesResult {
        ITBDebug()
        switch (processNextMessage()) {
        case .show(let message):
            updateMessage(message, didProcessTrigger: true, consumed: !message.saveToInbox)
            return .show(message: message, messagesMap: messagesMap)
        case .skip(let message):
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
                ITBDebug("delegete returned show")
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
        
        self.messagesMap.updateValue(toUpdate, forKey: message.messageId)
    }
    
    private let inAppDelegate: IterableInAppDelegate
    private var inAppDisplayChecker: InAppDisplayChecker
    private var messagesMap: OrderedDictionary<String, IterableInAppMessage>
}

struct MergeMessagesResult {
    let inboxChanged: Bool
    let messagesMap: OrderedDictionary<String, IterableInAppMessage>
}

/// Merges the results and determines whether inbox changed needs to be fired.
struct MessagesObtainedHandler {
    init(messagesMap: OrderedDictionary<String, IterableInAppMessage>, messages: [IterableInAppMessage]) {
        ITBInfo()
        self.messagesMap = messagesMap
        self.messages = messages
    }
    
    mutating func handle() -> MergeMessagesResult {
        // Remove messages that are no present in server
        let deletedInboxCount = self.removeDeletedMessages(messagesFromServer: messages)
        
        // add new ones
        let addedInboxCount = self.addNewMessages(messagesFromServer: messages)
        
        return MergeMessagesResult(inboxChanged: deletedInboxCount + addedInboxCount > 0,
                                            messagesMap: self.messagesMap)
    }
    
    // return count of deleted inbox messages
    private mutating func removeDeletedMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
        var inboxCount = 0
        let removedMessages = getRemovedMessages(messagesFromServer: messages)
        removedMessages.forEach {
            if $0.saveToInbox == true {
                inboxCount += 1
            }
            
            messagesMap.removeValue(forKey: $0.messageId)
        }
        
        return inboxCount
    }
    
    // given `messages` coming for server, find messages that need to be removed
    private func getRemovedMessages(messagesFromServer messages: [IterableInAppMessage]) -> [IterableInAppMessage] {
        return messagesMap.values.reduce(into: [IterableInAppMessage]()) { (result, message) in
            if !messages.contains(where: { $0.messageId == message.messageId }) {
                result.append(message)
            }
        }
    }
    
    // returns count of inbox messages (save to inbox)
    private mutating func addNewMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
        var inboxCount = 0
        messages.forEach { message in
            if !messagesMap.contains(where: { $0.key == message.messageId }) {
                if message.saveToInbox == true {
                    inboxCount += 1
                }
                
                messagesMap[message.messageId] = message
                
                IterableAPI.track(inAppDelivery: message.messageId,
                                  saveToInbox: message.saveToInbox,
                                  silentInbox: message.saveToInbox && message.trigger.type == .never)
            }
        }
        
        return inboxCount
    }
    
    private var messagesMap: OrderedDictionary<String, IterableInAppMessage>
    private let messages: [IterableInAppMessage]
}
