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
            _ = self.showInternal(message: message, consume: consume, callback: callback)
        }
    }

    func remove(message: IterableInAppMessage) {
        ITBInfo()

        queue.async {
            message.consumed = true
            self.internalApi?.inAppConsume(message.messageId)
            
            self.messagesMap.updateValue(message, forKey: message.messageId)
        }
    }

    @objc func onAppEnteredForeground(notification: Notification) {
        ITBInfo()
        queue.async {
            self.processMessages()
        }
    }
    
    // This must be called from MainThread
    private func showInternal(message: IterableInAppMessage,
                              consume: Bool,
                              callback: ITEActionBlock? = nil) {
        ITBInfo()

        guard Thread.isMainThread else {
            ITBError("This must be called from the main thread")
            return
        }
        
        // This is called when the user clicks on a link in the inAPP
        let clickCallback = {(urlOrAction: String?) in
            ITBInfo()
            // call the client callback, if present
            callback?(urlOrAction)
            
            // in addition perform action or url delegate task
            if let urlOrAction = urlOrAction {
                self.handleUrlOrAction(urlOrAction: urlOrAction)
            } else {
                ITBError("No name for clicked button/link in inApp")
            }
            
            // set the dismiss time
            self.lastDismissedTime = self.dateProvider.currentDate
            
            // check if we need to process more inApps
            self.queue.asyncAfter(deadline: .now() + self.retryInterval) {
                self.processMessages()
            }
        }
        
        // set processed, if not already set
        message.processed = true

        let showed = displayer.showInApp(message: message, callback: clickCallback)

        if showed && consume {
            message.consumed = true // mark for removal
            internalApi?.inAppConsume(message.messageId)
        }

        queue.async {
            self.messagesMap.updateValue(message, forKey: message.messageId)
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
    
    private var synchronizer: InAppSynchronizerProtocol // this is mutable because we need to set internalApi
    private let displayer: InAppDisplayerProtocol
    private let inAppDelegate: IterableInAppDelegate
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    private let applicationStateProvider: ApplicationStateProviderProtocol
    private let notificationCenter: NotificationCenterProtocol
    
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>() // This is mutable
    private let queue = DispatchQueue(label: "InAppQueue")
    private let dateProvider: DateProviderProtocol
    private let retryInterval: Double // in seconds, if a message is already showing how long to wait?
    private var lastDismissedTime: Date? = nil
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppMessagesAvailable(messages: [IterableInAppMessage]) {
        ITBDebug()

        queue.async {
            // Remove messages that are no present in server
            self.removeDeletedMessages(messagesFromServer: messages)
            
            // add new ones
            self.addNewMessages(messagesFromServer: messages)
            
            // now process
            self.processMessages()
        }
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
            if self.applicationStateProvider.applicationState == .active && !self.displayer.isShowingInApp() {
                self.processOneMessage()
            } else {
                ITBInfo("Cannot show inApp, application is not active or showing another inApp.")
            }
        }
    }
    
    // How long do we have to wait before showing the message
    // > 0 means wait, otherwise we are good to show
    private func getWaitTimeInterval() -> Double {
        if let lastDismissedTime = lastDismissedTime {
            let nextShowingTime = Date(timeInterval: retryInterval, since: lastDismissedTime)
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

        queue.async {
            for message in self.messagesMap.values.filter({ $0.processed == false }) {
                ITBDebug("campaignId: \(message.campaignId)")
                message.processed = true
                if self.inAppDelegate.onNew(message: message) == .show {
                    self.showOneMessage(message: message)
                    break
                }
            }
        }
    }
    
    // Display one message in the queue, if one is already showing
    private func showOneMessage(message: IterableInAppMessage) {
        ITBInfo()
        
        DispatchQueue.main.async {
            self.showInternal(message: message, consume: true, callback: nil)
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

    func remove(message: IterableInAppMessage) {
    }
}

