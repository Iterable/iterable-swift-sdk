//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

class InAppManager : IterableInAppManagerProtocol {
    weak var internalApi: IterableAPIInternal? {
        didSet {
            self.synchronizer.internalApi = internalApi
        }
    }

    init(synchronizer: InAppSynchronizerProtocol,
         displayer: InAppDisplayerProtocol,
         inAppDelegate: IterableInAppDelegate,
         urlDelegate: IterableURLDelegate?,
         customActionDelegate: IterableCustomActionDelegate?,
         urlOpener: UrlOpenerProtocol) {
        self.synchronizer = synchronizer
        self.displayer = displayer
        self.inAppDelegate = inAppDelegate
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
        
        self.synchronizer.inAppSyncDelegate = self
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        return Array(messagesMap.values)
    }
    
    func show(message: IterableInAppMessage, consume: Bool = true, callback: ITEActionBlock? = nil) {
        ITBInfo()
        
        // Handle url and call the client with callback provided
        let clickCallback = {(urlOrAction: String?) in
            // call the client callback, if present
            callback?(urlOrAction)
            // in addition perform action or url delegate task
            if let urlOrAction = urlOrAction {
                self.handleUrlOrAction(urlOrAction: urlOrAction)
            } else {
                ITBError("No name for clicked button/link in inApp")
            }
        }
        
        displayer.showInApp(message: message, callback: clickCallback).onSuccess { (showed) in // showed boolean value gets set when inApp is showed in UI
            if showed && consume {
                self.internalApi?.inAppConsume(message.messageId)
                self.messagesMap.removeValue(forKey: message.messageId)
            } else {
                message.skipped = true
                self.messagesMap.updateValue(message, forKey: message.messageId)
            }
        }
    }

    private func handleUrlOrAction(urlOrAction: String) {
        guard let action = createAction(fromUrlOrAction: urlOrAction) else {
            ITBError("Could not create action from: \(urlOrAction)")
            return
        }
        
        let context = IterableActionContext(action: action, source: .inApp)
        DispatchQueue.main.async {
            IterableActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self.urlDelegate, inContext: context),
                                         customActionHandler: IterableUtil.customActionHandler(fromCustomActionDelegate: self.customActionDelegate, inContext: context),
                                         urlOpener: self.urlOpener)
        }
    }
    
    private func createAction(fromUrlOrAction urlOrAction: String) -> IterableAction? {
        if let parsedUrl = URL(string: urlOrAction), let _ = parsedUrl.scheme {
            return IterableAction.actionOpenUrl(fromUrlString: urlOrAction)
        } else {
            return IterableAction.action(fromDictionary: ["type" : urlOrAction])
        }
    }
    
    private var synchronizer: InAppSynchronizerProtocol
    private var displayer: InAppDisplayerProtocol
    private var inAppDelegate: IterableInAppDelegate
    private var urlDelegate: IterableURLDelegate?
    private var customActionDelegate: IterableCustomActionDelegate?
    private var urlOpener: UrlOpenerProtocol
    
    private var messagesMap: [String: IterableInAppMessage] = [:]
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppMessagesAvailable(messages: [IterableInAppMessage]) {
        ITBDebug()

        // Remove messages that are no present in server
        removeDeletedMessages(messages: messages)
        
        let newMessages = mergeAndGetNewMessages(messages: messages)

        ITBDebug("\(newMessages.count) new messages arrived.")
        if newMessages.count == 1 {
            let message = newMessages[0]
            if inAppDelegate.onNew(message: message) == .show {
                self.show(message: message, consume: true)
            } else {
                ITBInfo("skipping inApp")
                markAsSkipped(message: message)
            }
        } else if newMessages.count > 1 {
            if let message = inAppDelegate.onNew(batch: newMessages) {
                // found content to show
                self.show(message: message, consume: true)
                
                newMessages.filter { $0.messageId != message.messageId }.forEach { markAsSkipped(message: $0) }
            } else {
                ITBInfo("skipping inApp batch")
                newMessages.forEach {markAsSkipped(message: $0)}
            }
        }
    }
    
    private func markAsSkipped(message: IterableInAppMessage) {
        if let message = messagesMap[message.messageId] {
            message.skipped = true
            messagesMap.updateValue(message, forKey: message.messageId)
        } else {
            // Should never happen
            ITBError("Did not find message")
        }
    }

    // Adds new messages to map and returns the new messages
    private func mergeAndGetNewMessages(messages: [IterableInAppMessage]) -> [IterableInAppMessage] {
        return messages.reduce(into: [IterableInAppMessage]()) { (result, message) in
            if !messagesMap.contains(where: { $0.key == message.messageId}) {
                messagesMap[message.messageId] = message
                result.append(message)
            }
        }
    }

    private func removeDeletedMessages(messages: [IterableInAppMessage]) {
        getRemovedMessags(messages: messages).forEach {
            messagesMap.removeValue(forKey: $0.messageId)
        }
    }
    
    // given `messages` coming for server, find messages that need to be removed
    private func getRemovedMessags(messages: [IterableInAppMessage]) -> [IterableInAppMessage] {
        return messagesMap.values.reduce(into: [IterableInAppMessage]()) { (result, message) in
            if !messages.contains(where: { $0.messageId == message.messageId }) {
                result.append(message)
            }
        }
    }
}

class EmptyInAppManager : IterableInAppManagerProtocol {
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func show(message: IterableInAppMessage, consume: Bool, callback: ITEActionBlock?) {
    }
    
}

