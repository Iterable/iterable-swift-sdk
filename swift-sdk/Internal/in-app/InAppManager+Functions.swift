//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum MessagesProcessorResult {
    case show(message: IterableInAppMessage, messagesMap: OrderedDictionary<String, IterableInAppMessage>)
    case noShow(message: IterableInAppMessage?, messagesMap: OrderedDictionary<String, IterableInAppMessage>)
    case jsonOnly(message: IterableInAppMessage, messagesMap: OrderedDictionary<String, IterableInAppMessage>)
}

struct MessagesProcessor {
    init(inAppDelegate: IterableInAppDelegate,
         inAppDisplayChecker: InAppDisplayChecker,
         messagesMap: OrderedDictionary<String, IterableInAppMessage>,
         currentDate: Date,
         isContextCurrent: @escaping () -> Bool) {
        ITBInfo()
        
        self.inAppDelegate = inAppDelegate
        self.inAppDisplayChecker = inAppDisplayChecker
        self.messagesMap = messagesMap
        self.currentDate = currentDate
        self.isContextCurrent = isContextCurrent
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
        case let .jsonOnly(message):
            return .jsonOnly(message: message, messagesMap: messagesMap)
        case .none, .wait:
            return .noShow(message: nil, messagesMap: messagesMap)
        }
    }
    
    private enum ProcessNextMessageResult {
        case show(IterableInAppMessage)
        case skip(IterableInAppMessage)
        case jsonOnly(IterableInAppMessage)
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
        
        // JSON-only availability intentionally bypasses the HTML display pause and cooldown.
        if message.isJsonOnly {
            return .jsonOnly(message)
        }

        guard isContextCurrent() else { return .none }

        guard inAppDisplayChecker.isOkToShowNow(message: message) else {
            ITBDebug("Not ok to show now")
            return .wait
        }
        
        ITBDebug("isOkToShowNow")

        guard isContextCurrent() else { return .none }

        let returnValue = inAppDelegate.onNew(message: message)
        if returnValue == .show {
            ITBDebug("delegate returned show")
            return .show(message)
        } else {
            ITBDebug("delegate returned skip")
            return .skip(message)
        }
    }
    
    private func getFirstProcessableTriggeredMessage() -> IterableInAppMessage? {
        let processableMessages = messagesMap.values.filter(isProcessableTriggeredMessage)
        // Select JSON-only records before applying HTML priority ordering.
        return processableMessages.first(where: { $0.isJsonOnly })
            ?? processableMessages.sorted { $0.priorityLevel < $1.priorityLevel }.first
    }
    
    private func isProcessableTriggeredMessage(_ message: IterableInAppMessage) -> Bool {
        !message.didProcessTrigger &&
            message.trigger.type == .immediate &&
            !message.read &&
            (message.expiresAt.map { $0 > currentDate } ?? true)
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
    private let currentDate: Date
    private let isContextCurrent: () -> Bool
}

struct MergeMessagesResult {
    let inboxChanged: Bool
    let messagesMap: OrderedDictionary<String, IterableInAppMessage>
    let deliveredMessages: [IterableInAppMessage]
}

/// Merges the results and determines whether inbox changed needs to be fired.
struct MessagesObtainedHandler {
    init(messagesMap: OrderedDictionary<String, IterableInAppMessage>,
         messages: [IterableInAppMessage],
         acknowledgedJsonOnlyMessageIds: Set<String> = [],
         readmittedJsonOnlyMessageIds: Set<String> = []) {
        ITBInfo()
        self.messagesMap = messagesMap
        self.messages = messages
        self.acknowledgedJsonOnlyMessageIds = acknowledgedJsonOnlyMessageIds
        self.readmittedJsonOnlyMessageIds = readmittedJsonOnlyMessageIds
    }
    
    func handle() -> MergeMessagesResult {
        let removedMessages = messagesMap.values.filter { existingMessage in !messages.contains(where: { $0.messageId == existingMessage.messageId }) }
        
        let addedMessages = messages.filter { !messagesMap.keys.contains($0.messageId) }
        
        let removedInboxCount = removedMessages.reduce(0) { $1.saveToInbox ? $0 + 1 : $0 }
        let addedInboxCount = addedMessages.reduce(0) { $1.saveToInbox ? $0 + 1 : $0 }
        
        var messagesOverwritten = 0
        var readmittedMessages = [IterableInAppMessage]()
        var newMessagesMap = OrderedDictionary<String, IterableInAppMessage>()
        
        // Mark messages that have been removed from the server response as consumed
        // This ensures recalled campaigns won't be shown
        removedMessages.forEach { message in
            var mutableMessage = message
            mutableMessage.consumed = true
            newMessagesMap[message.messageId] = mutableMessage
        }
        
        messages.forEach { serverMessage in
            let messageId = serverMessage.messageId
            if let existingMessage = messagesMap[messageId] {
                // Handle acknowledged HTML-to-JSON transitions before generic type replacement to avoid readmission.
                if !existingMessage.isJsonOnly,
                   serverMessage.isJsonOnly,
                   acknowledgedJsonOnlyMessageIds.contains(messageId) {
                    serverMessage.consumed = true
                    serverMessage.didProcessTrigger = true
                    newMessagesMap[messageId] = serverMessage
                    if existingMessage.saveToInbox {
                        messagesOverwritten += 1
                    }
                } else if existingMessage.isJsonOnly != serverMessage.isJsonOnly {
                    newMessagesMap[messageId] = serverMessage
                    readmittedMessages.append(serverMessage)
                    if existingMessage.saveToInbox || serverMessage.saveToInbox {
                        messagesOverwritten += 1
                    }
                } else if serverMessage.isJsonOnly && readmittedJsonOnlyMessageIds.contains(messageId) {
                    newMessagesMap[messageId] = serverMessage
                    readmittedMessages.append(serverMessage)
                } else if serverMessage.isJsonOnly && acknowledgedJsonOnlyMessageIds.contains(messageId) {
                    existingMessage.consumed = true
                    existingMessage.didProcessTrigger = true
                    newMessagesMap[messageId] = existingMessage
                } else if Self.shouldOverwrite(clientMessage: existingMessage, withServerMessage: serverMessage) {
                    serverMessage.consumed = existingMessage.consumed
                    serverMessage.didProcessTrigger = existingMessage.didProcessTrigger
                    newMessagesMap[messageId] = serverMessage
                    messagesOverwritten += 1
                } else {
                    newMessagesMap[messageId] = existingMessage
                }
            } else {
                if serverMessage.isJsonOnly && acknowledgedJsonOnlyMessageIds.contains(messageId) {
                    serverMessage.consumed = true
                    serverMessage.didProcessTrigger = true
                }
                newMessagesMap[messageId] = serverMessage
            }
        }
        
        let deliveredMessages = (addedMessages + readmittedMessages).filter {
            !$0.read && !acknowledgedJsonOnlyMessageIds.contains($0.messageId)
        }
        
        return MergeMessagesResult(inboxChanged: removedInboxCount + addedInboxCount + messagesOverwritten > 0,
                                   messagesMap: newMessagesMap,
                                   deliveredMessages: deliveredMessages)
    }
    
    private let messagesMap: OrderedDictionary<String, IterableInAppMessage>
    private let messages: [IterableInAppMessage]
    private let acknowledgedJsonOnlyMessageIds: Set<String>
    private let readmittedJsonOnlyMessageIds: Set<String>

    // We should only overwrite if the server is read and client is not read.
    // This is because some client changes may not have propagated to server yet.
    private static func shouldOverwrite(clientMessage: IterableInAppMessage,
                                        withServerMessage serverMessage: IterableInAppMessage) -> Bool {
        serverMessage.read && !clientMessage.read
    }
}
