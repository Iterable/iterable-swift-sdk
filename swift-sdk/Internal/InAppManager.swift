//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

protocol NotificationCenterProtocol {
    func addObserver(_ observer: Any, selector: Selector, name: Notification.Name?, object: Any?)
    func removeObserver(_ observer: Any)
}

extension NotificationCenter : NotificationCenterProtocol {
}

class InAppManager : NSObject, IterableInAppManagerProtocol {
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
         applicationStateProvider: ApplicationStateProviderProtocol,
         notificationCenter: NotificationCenterProtocol,
         dateProvider: DateProviderProtocol,
         retryInterval: Double) {
        ITBInfo()
        self.synchronizer = synchronizer
        self.displayer = displayer
        self.inAppDelegate = inAppDelegate
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
        self.applicationStateProvider = applicationStateProvider
        self.notificationCenter = notificationCenter
        self.dateProvider = dateProvider
        self.retryInterval = retryInterval
        
        super.init()
        
        self.synchronizer.inAppSyncDelegate = self

        self.notificationCenter.addObserver(self,
                                       selector: #selector(onAppEnteredForeground(notification:)),
                                       name: Notification.Name.UIApplicationDidBecomeActive,
                                       object: nil)
    }
    
    deinit {
        ITBInfo()
        notificationCenter.removeObserver(self)
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
        
        // This is public (via public protocol implementation), so make sure we call from Main Thread
        DispatchQueue.main.async {
            _ = self.showInternal(message: message, consume: consume, checkNext: false, callback: callback)
        }
    }

    @objc func onAppEnteredForeground(notification: Notification) {
        ITBInfo()
        processMessages()
    }
    
    // This must be called from MainThread
    private func showInternal(message: IterableInAppMessage,
                              consume: Bool,
                              checkNext: Bool,
                              callback: ITEActionBlock? = nil) -> Bool {
        ITBInfo()

        guard Thread.isMainThread else {
            ITBError("This must be called from the main thread")
            return false
        }
        
        // This is called when the user clicks on a link in the inAPP
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
            // This will be true when we are processing messagers from server and false
            // when called by clients directly
            if checkNext == true {
                self.queue.asyncAfter(deadline: .now() + self.retryInterval) {
                    self.processMessages()
                }
            }
        }
        
        // set processed, if not already set
        message.processed = true

        let showed = displayer.showInApp(message: message, callback: clickCallback)
        if showed {
            lastShowedTime = dateProvider.currentDate
        }

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
    
    private var synchronizer: InAppSynchronizerProtocol // this is mutable because we need to set internalApi
    private let displayer: InAppDisplayerProtocol
    private let inAppDelegate: IterableInAppDelegate
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    private let applicationStateProvider: ApplicationStateProviderProtocol
    private let notificationCenter: NotificationCenterProtocol
    
    private var messagesMap = [String: IterableInAppMessage]() // this is mutable
    private let queue = DispatchQueue(label: "InAppQueue")
    private let dateProvider: DateProviderProtocol
    private let retryInterval: Double // in seconds, if a message is already showing how long to wait?
    private var lastShowedTime: Date? = nil
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppMessagesAvailable(messages: [IterableInAppMessage]) {
        ITBDebug()

        // Remove messages that are no present in server
        removeDeletedMessages(messagesFromServer: messages)

        // add new ones
        addNewMessages(messagesFromServer: messages)

        // now process
        processMessages()
    }
    
    private func processMessages() {
        let waitTimeInterval = getWaitTimeInterval()
        guard waitTimeInterval <= 0 else {
            ITBInfo("Need to wait for: \(waitTimeInterval)")
            queue.asyncAfter(deadline: .now() + waitTimeInterval) {
                self.processMessages()
            }
            return
        }
        
        // We can only check applicationState from main queue so need to do the following
        DispatchQueue.main.async {
            if self.applicationStateProvider.applicationState == .active {
                self.queue.async {
                    self.processOneMessage()
                }
            } else {
                ITBInfo("Application is not active")
            }
        }
    }
    
    // How long do we have to wait before showing the message
    // > 0 means wait, otherwise we are good to show
    private func getWaitTimeInterval() -> Double {
        if let lastShowedTime = lastShowedTime {
            let nextShowingTime = Date(timeInterval: retryInterval, since: lastShowedTime)
            if dateProvider.currentDate >= nextShowingTime {
                return 0.0
            } else {
                return nextShowingTime.timeIntervalSinceReferenceDate - self.dateProvider.currentDate.timeIntervalSinceReferenceDate
            }
        } else {
            // we have not shown any messages
            return 0.0
        }
    }
    
    // go through one loop of client side messages, and show the first that is not processed
    private func processOneMessage() {
        ITBDebug()

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

