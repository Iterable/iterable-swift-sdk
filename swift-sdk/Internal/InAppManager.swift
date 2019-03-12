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

protocol IterableInAppManagerProtocolInternal : IterableInAppManagerProtocol {
    func synchronize()
}

class InAppManager : NSObject, IterableInAppManagerProtocolInternal, IterableInboxManagerProtocol {
    weak var internalApi: IterableAPIInternal? {
        didSet {
            self.synchronizer.internalApi = internalApi
        }
    }

    init(synchronizer: InAppSynchronizerProtocol,
         displayer: IterableMessageDisplayerProtocol,
         persister: IterableMessagePersistenceProtocol,
         inAppDelegate: IterableInAppDelegate,
         inboxDelegate: IterableInboxDelegate?,
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
        self.inboxDelegate = inboxDelegate
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
        
        inboxDelegate?.onReady(messages: getMessages())
    }
    
    deinit {
        ITBInfo()
        notificationCenter.removeObserver(self)
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        
        var messages = [IterableInAppMessage] ()
        updateQueue.sync {
            messages = Array(self.messagesMap.values.compactMap { InAppManager.asValidInApp(message: $0, currentDate: dateProvider.currentDate)})
        }
        return messages
    }
    
    func getMessages() -> [IterableInboxMessage] {
        ITBInfo()
        
        var messages = [IterableInboxMessage] ()
        updateQueue.sync {
            messages = Array(self.messagesMap.values.compactMap { InAppManager.asValidInbox(message: $0, currentDate: dateProvider.currentDate)})
        }
        return messages
    }
    
    func getUnreadMessages() -> [IterableInboxMessage] {
        return getMessages().filter { $0.read == false }
    }
    
    func getUnreadCount() -> Int {
        return getUnreadMessages().count
    }
    
    func remove(message: IterableInboxMessage) {
        removePrivate(message: message)
    }
    
    func show(message: IterableInboxMessage) {
        ITBInfo()
        show(message: message, callback: nil)
    }
    
    func show(message: IterableInboxMessage, callback: ITEActionBlock?) {
        // This is public (via public protocol implementation), so make sure we call from Main Thread
        DispatchQueue.main.async {
            _ = self.showInternal(message: message, consume: false, callback: callback)
        }
    }
    
    func createInboxMessageViewController(for message: IterableInboxMessage) -> UIViewController? {
        guard let content = message.content as? IterableInboxHtmlContent else {
            ITBError("Invalid Content in message")
            return nil
        }
        
        let clickCallback = { (urlOrAction: String?) in
            ITBInfo()
            
            // in addition perform action or url delegate task
            if let urlOrAction = urlOrAction {
                self.handleUrlOrAction(urlOrAction: urlOrAction)
            } else {
                ITBError("No name for clicked button/link in inApp")
            }
        }
        let input = IterableHtmlMessageViewController.Input(html: content.html,
                                                            callback: clickCallback,
                                                            trackParams: IterableNotificationMetadata.metadata(fromInAppOptions: message.messageId))
        return IterableHtmlMessageViewController(input: input)
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
    
    func set(read: Bool, forMessage message: IterableInboxMessage) {
        updateQueue.sync {
            let toUpdate = message
            toUpdate.read = read
            self.messagesMap.updateValue(toUpdate, forKey: message.messageId)
            persister.persist(self.messagesMap.values)
        }
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
    private func showInternal(message: IterableMessageProtocol,
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
                self.handleUrlOrAction(urlOrAction: urlOrAction)
            } else {
                ITBError("No name for clicked button/link in inApp")
            }
            
            // set the dismiss time
            self.lastDismissedTime = self.dateProvider.currentDate
            
            // check if we need to process more inApps
            self.scheduleNextInAppMessage()
        }
        
        let showed = displayer.show(iterableMessage: message, withCallback: clickCallback)
        let shouldConsume = showed && consume
        if shouldConsume {
            internalApi?.inAppConsume(message.messageId)
        }
        
        // set read for valid inbox message
        InAppManager.asValidInbox(message: message, currentDate: dateProvider.currentDate).map { set(read: true, forMessage: $0) }

        updateMessage(message, processed: true, consumed: shouldConsume)
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
    
    private func initializeMessagesMap() {
        let messages = persister.getMessages()
        for message in messages {
            messagesMap[message.messageId] = message
        }
    }

    private func removePrivate(message: IterableMessageProtocol) {
        ITBInfo()
        
        updateMessage(message, processed: true, consumed: true)
        self.internalApi?.inAppConsume(message.messageId)
    }

    private static func isExpired(message: IterableMessageProtocol, currentDate: Date) -> Bool {
        guard let expiresAt = message.expiresAt else {
            return false
        }
        
        return currentDate >= expiresAt
    }
    
    fileprivate static func asValidInApp(message: IterableMessageProtocol, currentDate: Date) -> IterableInAppMessage? {
        guard let inAppMessage = message as? IterableInAppMessage else {
            return nil
        }
        guard isValid(message: message, currentDate: currentDate) else {
            return nil
        }
        
        return inAppMessage
    }
    
    fileprivate static func asValidInbox(message: IterableMessageProtocol, currentDate: Date) -> IterableInboxMessage? {
        guard let inboxMessage = message as? IterableInboxMessage else {
            return nil
        }
        guard isValid(message: message, currentDate: currentDate) else {
            return nil
        }
        
        return inboxMessage
    }
    
    fileprivate static func isValid(message: IterableMessageProtocol, currentDate: Date) -> Bool {
        return message.consumed == false && isExpired(message: message, currentDate: currentDate) == false
    }
    
    private var synchronizer: InAppSynchronizerProtocol // this is mutable because we need to set internalApi
    private let displayer: IterableMessageDisplayerProtocol
    private let inAppDelegate: IterableInAppDelegate
    private let inboxDelegate: IterableInboxDelegate?
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    private let applicationStateProvider: ApplicationStateProviderProtocol
    private let notificationCenter: NotificationCenterProtocol
    
    private let persister: IterableMessagePersistenceProtocol
    private var messagesMap = OrderedDictionary<String, IterableMessageProtocol>() // This is mutable
    private let dateProvider: DateProviderProtocol
    private let retryInterval: TimeInterval // in seconds, if a message is already showing how long to wait?
    private var lastDismissedTime: Date? = nil
    private let updateQueue = DispatchQueue(label: "InAppQueue")
    private let scheduleQueue = DispatchQueue(label: "Scheduler")
    private let syncQueue = DispatchQueue(label: "Sync")
    private var lastSyncTime: Date? = nil
    private let moveToForegroundSyncInterval: Double = 1.0 * 60.0 // don't sync within sixty seconds
}

extension InAppManager : InAppSynchronizerDelegate {
    func onInAppMessagesAvailable(messages: [IterableMessageProtocol]) {
        ITBDebug()

        updateQueue.async {
            // Remove messages that are no present in server
            self.removeDeletedMessages(messagesFromServer: messages)
            
            // add new ones
            self.addNewMessages(messagesFromServer: messages)
            
            self.persister.persist(self.messagesMap.values)
            
            // process inbox messages
            self.processInboxMessages()
            
            // now process in app messages
            self.processNextInAppMessage()
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
    
    private func processInboxMessages() {
        ITBDebug()
        let newInboxMessages = messagesMap.values.compactMap { InAppManager.asValidInbox(message: $0, currentDate: dateProvider.currentDate) }.filter { $0.processed == false }
        
        if newInboxMessages.count > 0 {
            newInboxMessages.forEach {
                let toUpdate = $0
                toUpdate.processed = true
                self.messagesMap.updateValue(toUpdate, forKey: $0.messageId)
            }
            persister.persist(self.messagesMap.values)

            inboxDelegate?.onNew(messages: newInboxMessages)
        }
    }
    
    private func scheduleNextInAppMessage() {
        ITBDebug()
        
        scheduleQueue.async {
            let waitTimeInterval = self.getInAppShowingWaitTimeInterval()
            if waitTimeInterval > 0 {
                ITBDebug("Need to wait for: \(waitTimeInterval)")
                self.scheduleQueue.asyncAfter(deadline: .now() + waitTimeInterval) {
                    self.processNextInAppMessage()
                }
            } else {
                self.processNextInAppMessage()
            }
        }
    }
    
    private func processNextInAppMessage() {
        ITBDebug()

        guard let message = getFirstProcessableInAppMessage() else {
            ITBDebug("No message to process")
            return
        }
        
        ITBDebug("processing message with id: \(message.messageId)")
        
        // We can only check applicationState from main queue so need to do the following
        DispatchQueue.main.async {
            if self.isOkToShowNow(message: message) {
                self.updateMessage(message, processed: true)

                if self.inAppDelegate.onNew(message: message) == .show {
                    ITBDebug("delegate returned show")
                    self.showInternal(message: message, consume: true, callback: nil)
                } else {
                    ITBDebug("delegate returned skip, continue processing")
                    self.scheduleQueue.async {
                        self.processNextInAppMessage()
                    }
                }
            } else {
                ITBInfo("Cannot show inApp with id: \(message.messageId) now.")
            }
        }
    }
    
    private func getFirstProcessableInAppMessage() -> IterableInAppMessage? {
        return messagesMap.values.filter(InAppManager.isProcessable).first as? IterableInAppMessage
    }
    
    private static func isProcessable(message: IterableMessageProtocol) -> Bool {
        guard message.inAppType == .default else {
            // do not process inbox Types
            return false
        }
        guard message.processed == false else {
            // if already processed return false
            return false
        }
        
        if let inAppMessage = message as? IterableInAppMessage {
            // only immediate triggers are processable
            return inAppMessage.trigger.type == .immediate
        } else {
            // inbox messages are processable
            ITBError("Expecting IterableInAppMessage")
            return false
        }
    }
    
    private func updateMessage(_ message: IterableMessageProtocol, processed: Bool, consumed: Bool = false) {
        ITBDebug()
        updateQueue.sync {
            var toUpdate = message
            toUpdate.processed = processed
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
        guard displayer.isShowingIterableMessage() == false else {
            ITBInfo("showing another")
            return false
        }
        guard message.processed == false else {
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
    
    private func addNewMessages(messagesFromServer messages: [IterableMessageProtocol]) {
        messages.forEach { message in
            if !messagesMap.contains(where: { $0.key == message.messageId }) {
                messagesMap[message.messageId] = message
            }
        }
    }
    
    private func removeDeletedMessages(messagesFromServer messages: [IterableMessageProtocol]) {
        getRemovedMessages(messagesFromServer: messages).forEach {
            messagesMap.removeValue(forKey: $0.messageId)
        }
    }
    
    // given `messages` coming for server, find messages that need to be removed
    private func getRemovedMessages(messagesFromServer messages: [IterableMessageProtocol]) -> [IterableMessageProtocol] {
        return messagesMap.values.reduce(into: [IterableMessageProtocol]()) { (result, message) in
            if !messages.contains(where: { $0.messageId == message.messageId }) {
                result.append(message)
            }
        }
    }
}

class EmptyInAppManager : IterableInAppManagerProtocol, IterableInboxManagerProtocol {
    func createInboxMessageViewController(for message: IterableInboxMessage) -> UIViewController? {
        ITBError("Can't create VC")
        return nil
    }
    
    func getMessages() -> [IterableInAppMessage] {
        return []
    }
    
    func getMessages() -> [IterableInboxMessage] {
        return []
    }
    
    func getUnreadMessages() -> [IterableInboxMessage] {
        return []
    }
    
    func show(message: IterableInAppMessage) {
    }
    
    func show(message: IterableInAppMessage, consume: Bool, callback: ITEActionBlock?) {
    }

    func show(message: IterableInboxMessage, callback: ITEActionBlock?) {
    }
    
    func show(message: IterableInboxMessage) {
    }
    
    func remove(message: IterableInAppMessage) {
    }

    func set(read: Bool, forMessage message: IterableInboxMessage) {
    }

    func getUnreadCount() -> Int {
        return 0
    }

    func remove(message: IterableInboxMessage) {
    }
}

