//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

protocol NotificationCenterProtocol {
    func addObserver(_ observer: Any, selector: Selector, name: Notification.Name?, object: Any?)
    func removeObserver(_ observer: Any)
    func post(name: Notification.Name, object: Any?, userInfo: [AnyHashable : Any]?)
}

extension NotificationCenter : NotificationCenterProtocol {
}

protocol IterableInAppManagerProtocolInternal : IterableInAppManagerProtocol {
    func synchronize()
}

class InAppManager : NSObject, IterableInAppManagerProtocolInternal {
    weak var internalApi: IterableAPIInternal? {
        didSet {
            self.synchronizer.internalApi = internalApi
        }
    }

    init(synchronizer: InAppSynchronizerProtocol,
         displayer: InAppDisplayerProtocol,
         persister: InAppPersistenceProtocol,
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
        self.persister = persister
        self.inAppDelegate = inAppDelegate
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
        self.applicationStateProvider = applicationStateProvider
        self.notificationCenter = notificationCenter
        self.dateProvider = dateProvider
        self.retryInterval = retryInterval
        
        super.init()
        
        self.initializeMessagesMap()

        self.synchronizer.inAppSyncDelegate = self
        
        self.notificationCenter.addObserver(self,
                                       selector: #selector(onAppEnteredForeground(notification:)),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
        self.notificationCenter.addObserver(self,
                                            selector: #selector(onAppReady(notification:)),
                                            name: .iterableAppReady,
                                            object: nil)

    }
    
    deinit {
        ITBInfo()
        notificationCenter.removeObserver(self)
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        
        var messages = [IterableInAppMessage] ()
        updateQueue.sync {
            messages = Array(self.messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: dateProvider.currentDate)})
        }
        return messages
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        ITBInfo()
        var messages = [IterableInAppMessage] ()
        updateQueue.sync {
            messages = Array(self.messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: dateProvider.currentDate) && $0.saveToInbox == true})
        }
        return messages
    }
    
    func getUnreadInboxMessages() -> [IterableInAppMessage] {
        return getInboxMessages().filter { $0.read == false }
    }
    
    func getUnreadInboxMessagesCount() -> Int {
        return getUnreadInboxMessages().count
    }
    
    func createInboxMessageViewController(for message: IterableInAppMessage) -> UIViewController? {
        guard let content = message.content as? IterableHtmlInAppContent else {
            ITBError("Invalid Content in message")
            return nil
        }
        
        let clickCallback = { (urlOrAction: String?) in
            ITBInfo()
            
            // in addition perform action or url delegate task
            if let urlOrAction = urlOrAction {
                self.handleUrlOrAction(urlOrAction: urlOrAction, forMessage: message)
            } else {
                ITBError("No name for clicked button/link in inApp")
            }
        }
        let parameters = IterableHtmlMessageViewController.Parameters(html: content.html,
                                                            callback: clickCallback,
                                                            trackParams: IterableNotificationMetadata.metadata(fromInAppOptions: message.messageId),
                                                            isModal: false)
        return IterableHtmlMessageViewController(parameters: parameters)
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

        removePrivate(message: message)
    }
    
    func synchronize() {
        ITBInfo()
        syncQueue.async {
            self.synchronizer.sync()
            self.lastSyncTime = self.dateProvider.currentDate
        }
    }
    
    func set(read: Bool, forMessage message: IterableInAppMessage) {
        updateQueue.sync {
            let toUpdate = message
            toUpdate.read = read
            self.messagesMap.updateValue(toUpdate, forKey: message.messageId)
            persister.persist(self.messagesMap.values)
        }
        self.callbackQueue.async {
            self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
        }

    }

    @objc private func onAppReady(notification: Notification) {
        ITBInfo()
        if self.messagesMap.values.filter({$0.saveToInbox == true}).count > 0 {
            self.callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        synchronize()
    }


    @objc private func onAppEnteredForeground(notification: Notification) {
        ITBInfo()
        let waitTime = InAppManager.getWaitTimeInterval(fromLastTime: lastSyncTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval)
        if waitTime <= 0 {
            synchronize()
        } else {
            ITBInfo("can't sync now, need to wait: \(waitTime)")
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
        let clickCallback = { (urlOrAction: String?) in
            ITBInfo()
            
            // call the client callback, if present
            callback?(urlOrAction)
            
            // in addition perform action or url delegate task
            if let urlOrAction = urlOrAction {
                self.handleUrlOrAction(urlOrAction: urlOrAction, forMessage: message)
            } else {
                ITBError("No name for clicked button/link in inApp")
            }
            
            // set the dismiss time
            self.lastDismissedTime = self.dateProvider.currentDate
            
            // check if we need to process more inApps
            self.scheduleNextInAppMessage()
        }
        
        let showed = displayer.showInApp(message: message, withCallback: clickCallback)
        let shouldConsume = showed && consume
        if shouldConsume {
            internalApi?.inAppConsume(message.messageId)
        }
        
        // set read
        set(read: true, forMessage: message)

        updateMessage(message, didProcessTrigger: true, consumed: shouldConsume)
    }

    private func handleUrlOrAction(urlOrAction: String, forMessage message: IterableInAppMessage) {
        guard let action = createAction(fromUrlOrAction: urlOrAction) else {
            ITBError("Could not create action from: \(urlOrAction)")
            return
        }
        guard handleIterableCustomAction(forAction: action, andMessage: message) == false else {
            ITBInfo("handled iterable custom action")
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
    
    private func handleIterableCustomAction(forAction action: IterableAction, andMessage message: IterableInAppMessage) -> Bool {
        guard let iterableCustomAction = IterableInAppCustomActionName(rawValue: action.type) else {
            return false
        }
        
        switch iterableCustomAction {
        case .dismiss:
            ITBInfo("dismissed")
        case .delete:
            ITBInfo("deleted")
            remove(message: message)
        }

        return true
    }
    
    private func createAction(fromUrlOrAction urlOrAction: String) -> IterableAction? {
        if let parsedUrl = URL(string: urlOrAction), let _ = parsedUrl.scheme {
            return IterableAction.actionOpenUrl(fromUrlString: urlOrAction)
        } else {
            return IterableAction.action(fromDictionary: ["type" : urlOrAction])
        }
    }
    
    private func initializeMessagesMap() {
        let messages = persister.getMessages()
        for message in messages {
            messagesMap[message.messageId] = message
        }
    }

    private func removePrivate(message: IterableInAppMessage) {
        ITBInfo()
        
        updateMessage(message, didProcessTrigger: true, consumed: true)
        self.internalApi?.inAppConsume(message.messageId)
        self.callbackQueue.async {
            self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
        }
    }

    private static func isExpired(message: IterableInAppMessage, currentDate: Date) -> Bool {
        guard let expiresAt = message.expiresAt else {
            return false
        }
        
        return currentDate >= expiresAt
    }
    
    fileprivate static func isValid(message: IterableInAppMessage, currentDate: Date) -> Bool {
        return message.consumed == false && isExpired(message: message, currentDate: currentDate) == false
    }
    
    private var synchronizer: InAppSynchronizerProtocol // this is mutable because we need to set internalApi
    private let displayer: InAppDisplayerProtocol
    private let inAppDelegate: IterableInAppDelegate
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    private let applicationStateProvider: ApplicationStateProviderProtocol
    private let notificationCenter: NotificationCenterProtocol
    
    private let persister: InAppPersistenceProtocol
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>() // This is mutable
    private let dateProvider: DateProviderProtocol
    private let retryInterval: TimeInterval // in seconds, if a message is already showing how long to wait?
    private var lastDismissedTime: Date? = nil
    private let updateQueue = DispatchQueue(label: "UpdateQueue")
    private let scheduleQueue = DispatchQueue(label: "ScheduleQueue")
    private let syncQueue = DispatchQueue(label: "SyncQueue")
    private let callbackQueue = DispatchQueue(label: "CallbackQueue")
    private var lastSyncTime: Date? = nil
    private let moveToForegroundSyncInterval: Double = 1.0 * 60.0 // don't sync within sixty seconds
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppMessagesAvailable(messages: [IterableInAppMessage]) {
        ITBDebug()

        updateQueue.async {
            // Remove messages that are no present in server
            let deletedInboxCount = self.removeDeletedMessages(messagesFromServer: messages)
            
            // add new ones
            let addedInboxCount = self.addNewMessages(messagesFromServer: messages)
            
            self.persister.persist(self.messagesMap.values)
            
            if deletedInboxCount + addedInboxCount > 0 {
                self.callbackQueue.async {
                    self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
                }
            }
            
            // now process in app messages
            self.processNextTriggeredMessage()
        }
    }
    
    func onInAppRemoved(messageId: String) {
        ITBInfo()
        
        updateQueue.async {
            if let _ = self.messagesMap.filter({$0.key == messageId}).first {
                self.messagesMap.removeValue(forKey: messageId)
                self.persister.persist(self.messagesMap.values)
            }
        }
    }
    
    // This method schedules next triggered message after showing a message
    private func scheduleNextInAppMessage() {
        ITBDebug()
        
        scheduleQueue.async {
            let waitTimeInterval = self.getInAppShowingWaitTimeInterval()
            if waitTimeInterval > 0 {
                ITBDebug("Need to wait for: \(waitTimeInterval)")
                self.scheduleQueue.asyncAfter(deadline: .now() + waitTimeInterval) {
                    self.processNextTriggeredMessage()
                }
            } else {
                self.processNextTriggeredMessage()
            }
        }
    }
    
    private func processNextTriggeredMessage() {
        ITBDebug()

        guard let message = getFirstProcessableTriggeredMessage() else {
            ITBDebug("No message to process")
            return
        }
        
        ITBDebug("processing message with id: \(message.messageId)")
        
        // We can only check applicationState from main queue so need to do the following
        DispatchQueue.main.async {
            if self.isOkToShowNow(message: message) {
                self.updateMessage(message, didProcessTrigger: true)

                if self.inAppDelegate.onNew(message: message) == .show {
                    ITBDebug("delegate returned show")
                    let consume = !message.saveToInbox
                    self.showInternal(message: message, consume: consume, callback: nil)
                } else {
                    ITBDebug("delegate returned skip, continue processing")
                    self.scheduleQueue.async {
                        self.processNextTriggeredMessage()
                    }
                }
            } else {
                ITBInfo("Cannot show inApp with id: \(message.messageId) now.")
            }
        }
    }
    
    private func getFirstProcessableTriggeredMessage() -> IterableInAppMessage? {
        return messagesMap.values.filter(InAppManager.isProcessableTriggeredMessage).first
    }
    
    private static func isProcessableTriggeredMessage(_ message: IterableInAppMessage) -> Bool {
        return message.didProcessTrigger == false && message.trigger.type == .immediate
    }
    
    private func updateMessage(_ message: IterableInAppMessage,
                               didProcessTrigger: Bool? = false,
                               consumed: Bool = false) {
        ITBDebug()
        updateQueue.sync {
            let toUpdate = message
            if let didProcessTrigger = didProcessTrigger {
                toUpdate.didProcessTrigger = didProcessTrigger
            }
            toUpdate.consumed = consumed
            self.messagesMap.updateValue(toUpdate, forKey: message.messageId)
            persister.persist(self.messagesMap.values)
        }
    }
    
    private func isOkToShowNow(message: IterableInAppMessage) -> Bool {
        guard applicationStateProvider.applicationState == .active else {
            ITBInfo("not active")
            return false
        }
        guard displayer.isShowingInApp() == false else {
            ITBInfo("showing another")
            return false
        }
        guard message.didProcessTrigger == false else {
            ITBInfo("message with id: \(message.messageId) is already processed")
            return false
        }
        guard getInAppShowingWaitTimeInterval() <= 0 else {
            ITBInfo("can't display within retryInterval window")
            return false
        }
        
        return true
    }
    
    // How long do we have to wait before showing the message
    // > 0 means wait, otherwise we are good to show
    private func getInAppShowingWaitTimeInterval() -> TimeInterval {
        return InAppManager.getWaitTimeInterval(fromLastTime: lastDismissedTime, currentTime: dateProvider.currentDate, gap: retryInterval)
    }
    
    // How long do we have to wait?
    // > 0 means wait, otherwise we are good to show
    private static func getWaitTimeInterval(fromLastTime lastTime: Date?, currentTime: Date, gap: TimeInterval) -> TimeInterval {
        if let lastTime = lastTime {
            // if it has been shown once
            let nextShowingTime = Date(timeInterval: gap + 0.1, since: lastTime)
            if currentTime >= nextShowingTime {
                return 0.0
            } else {
                return nextShowingTime.timeIntervalSinceReferenceDate - currentTime.timeIntervalSinceReferenceDate
            }
        } else {
            // we have not shown any messages
            return 0.0
        }
    }

    // returns count of inbox messages (save to inbox)
    private func addNewMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
        var inboxCount = 0
        messages.forEach { message in
            if !messagesMap.contains(where: { $0.key == message.messageId }) {
                if message.saveToInbox == true {
                    inboxCount += 1
                }
                messagesMap[message.messageId] = message
            }
        }
        return inboxCount
    }
    
    // return count of deleted inbox messages
    private func removeDeletedMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
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
}

class EmptyInAppManager : IterableInAppManagerProtocol {
    func createInboxMessageViewController(for message: IterableInAppMessage) -> UIViewController? {
        ITBError("Can't create VC")
        return nil
    }
    
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func getUnreadInboxMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func show(message: IterableInAppMessage) {
    }
    
    func show(message: IterableInAppMessage, consume: Bool, callback: ITEActionBlock?) {
    }

    func remove(message: IterableInAppMessage) {
    }

    func set(read: Bool, forMessage message: IterableInAppMessage) {
    }

    func getUnreadInboxMessagesCount() -> Int {
        return 0
    }
}

