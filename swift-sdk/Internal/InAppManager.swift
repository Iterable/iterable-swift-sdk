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
         urlOpener: UrlOpenerProtocol,
         retryInterval: Double) {
        self.synchronizer = synchronizer
        self.displayer = displayer
        self.inAppDelegate = inAppDelegate
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
        self.retryInterval = retryInterval
        
        self.synchronizer.inAppSyncDelegate = self
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        return Array(messagesMap.values.filter { $0.consumed == false })
    }

    func show(message: IterableInAppMessage) {
        ITBInfo()
        show(message: message, consume: true, callback: nil)
    }
    
    func show(message: IterableInAppMessage, consume: Bool = true, callback: ITEActionBlock? = nil) {
        ITBInfo()
        
        // This is public, so make sure we call from Main Thread
        DispatchQueue.main.async {
            _ = self.showInternal(message: message, consume: consume, checkNext: false, callback: callback)
        }
    }
    
    // This must be called from MainThread
    private func showInternal(message: IterableInAppMessage,
                              consume: Bool,
                              checkNext: Bool,
                              callback: ITEActionBlock? = nil) -> Bool {
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
            
            // check if we need to check for more inApps after showing this
            if checkNext == true {
                self.queue.asyncAfter(deadline: .now() + self.retryInterval) {
                    self.process()
                }
            }
        }
        
        // set processed, if not already set
        message.processed = true

        let showed = displayer.showInApp(message: message, callback: clickCallback)

        if showed && consume {
            message.consumed = true // mark for removal
            self.internalApi?.inAppConsume(message.messageId)
        }

        self.messagesMap.updateValue(message, forKey: message.messageId)
        
        return showed
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
    private var queue = DispatchQueue(label: "InAppQueue")
    private var retryInterval: Double // in seconds, if a message is already showing how long to wait?
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppMessagesAvailable(messages: [IterableInAppMessage]) {
        ITBInfo()

        // Remove messages that are no present in server
        removeDeletedMessages(messagesFromServer: messages)

        // add new ones
        addNewMessages(messagesFromServer: messages)

        // now process
        queue.async {
            self.process()
        }
    }
    
    // go through one loop of client side messages, and show the first that is not processed
    private func process() {
        ITBInfo()

        for message in messagesMap.values.filter({ $0.processed == false }) {
            message.processed = true
            if inAppDelegate.onNew(message: message) == .show {
                showOneMessage(message: message)
                break
            }
        }
    }
    
    // Display one message in the queue, if one is already showing
    // it will retry
    private func showOneMessage(message: IterableInAppMessage) {
        ITBInfo()
        
        DispatchQueue.main.async {
            if !self.showInternal(message: message, consume: true, checkNext: true, callback: nil) {
                // If we failed to show, wait and try again
                self.queue.asyncAfter(deadline: .now() + self.retryInterval) {
                    self.showOneMessage(message: message)
                }
            }
        }
    }

    private func addNewMessages(messagesFromServer messages: [IterableInAppMessage]) {
        messages.forEach { message in
            if !messagesMap.contains(where: { $0.key == message.messageId }) {
                messagesMap[message.messageId] = message
            }
        }
    }
    
    private func removeDeletedMessages(messagesFromServer messages: [IterableInAppMessage]) {
        getRemovedMessags(messagesFromServer: messages).forEach {
            messagesMap.removeValue(forKey: $0.messageId)
        }
    }
    
    // given `messages` coming for server, find messages that need to be removed
    private func getRemovedMessags(messagesFromServer messages: [IterableInAppMessage]) -> [IterableInAppMessage] {
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
    
    func show(message: IterableInAppMessage) {
    }
    
    func show(message: IterableInAppMessage, consume: Bool, callback: ITEActionBlock?) {
    }
}

