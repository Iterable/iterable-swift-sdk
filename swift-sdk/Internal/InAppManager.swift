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
         urlOpener: UrlOpenerProtocol) {
        self.synchronizer = synchronizer
        self.displayer = displayer
        self.inAppDelegate = inAppDelegate
        self.urlDelegate = urlDelegate
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
        let clickCallback = {(urlString: String?) in
            callback?(urlString)
            if let urlString = urlString {
                self.handleUrl(urlString: urlString, fromSource: .inApp)
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

    private var synchronizer: InAppSynchronizerProtocol
    private var displayer: InAppDisplayerProtocol
    private var inAppDelegate: IterableInAppDelegate
    private var urlDelegate: IterableURLDelegate?
    private var urlOpener: UrlOpenerProtocol
    
    private var messagesMap: [String: IterableInAppMessage] = [:]
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppMessagesAvailable(messages: [IterableInAppMessage]) {
        ITBDebug()
        
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

    private func handleUrl(urlString: String, fromSource source: IterableActionSource) {
        guard let action = IterableAction.actionOpenUrl(fromUrlString: urlString) else {
            ITBError("Could not create action from: \(urlString)")
            return
        }
        
        let context = IterableActionContext(action: action, source: source)
        DispatchQueue.main.async {
            IterableActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self.urlDelegate, inContext: context),
                                         urlOpener: self.urlOpener)
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
}

class EmptyInAppManager : IterableInAppManagerProtocol {
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func show(message: IterableInAppMessage, consume: Bool, callback: ITEActionBlock?) {
    }
    
}

