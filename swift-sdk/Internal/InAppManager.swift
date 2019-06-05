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

// This is internal. Do not expose
protocol IterableInAppManagerProtocolInternal : IterableInAppManagerProtocol, InAppNotifiable {
    func start()
}

class InAppManager : NSObject, IterableInAppManagerProtocolInternal {
    init(apiClient: ApiClientProtocol,
         fetcher: InAppFetcherProtocol,
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
        self.apiClient = apiClient
        self.fetcher = fetcher
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

        self.notificationCenter.addObserver(self,
                                       selector: #selector(onAppEnteredForeground(notification:)),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
    }
    
    deinit {
        ITBInfo()
        notificationCenter.removeObserver(self)
    }
    
    func start() {
        ITBInfo()
        if self.messagesMap.values.filter({$0.saveToInbox == true}).count > 0 {
            self.callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        synchronize()
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
    
    func getUnreadInboxMessagesCount() -> Int {
        return getInboxMessages().filter { $0.read == false }.count
    }
    
    func createInboxMessageViewController(for message: IterableInAppMessage) -> UIViewController? {
        guard let content = message.content as? IterableHtmlInAppContent else {
            ITBError("Invalid Content in message")
            return nil
        }
        
        let parameters = IterableHtmlMessageViewController.Parameters(html: content.html,
                                                            trackParams: IterableNotificationMetadata.metadata(fromInAppOptions: message.messageId),
                                                            isModal: false)
        let createResult = IterableHtmlMessageViewController.create(parameters: parameters)
        let viewController = createResult.viewController
        createResult.futureClickedURL.onSuccess { (url) in
            ITBInfo()
            // in addition perform action or url delegate task
            self.handle(clickedUrl: url, forMessage: message)
        }
        viewController.navigationItem.title = message.inboxMetadata?.title
        return viewController
    }
    
    func show(message: IterableInAppMessage) {
        ITBInfo()
        show(message: message, consume: true, callback: nil)
    }
    
    func show(message: IterableInAppMessage, consume: Bool = true, callback: ITBURLCallback? = nil) {
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

    @objc private func onAppEnteredForeground(notification: Notification) {
        ITBInfo()
        let waitTime = InAppManager.getWaitTimeInterval(fromLastTime: lastSyncTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval)
        if waitTime <= 0 {
            synchronize()
        } else {
            ITBInfo("can't sync now, need to wait: \(waitTime)")
        }
    }
    
    private func synchronize() {
        ITBInfo()
        syncQueue.async {
            self.fetcher.fetch()
                .onSuccess{ self.handleInAppMessagesObtainedFromServer(messages: $0) }
                .onError { ITBError($0.localizedDescription) }
            self.lastSyncTime = self.dateProvider.currentDate
        }
    }
    
    private func handleInAppMessagesObtainedFromServer(messages: [IterableInAppMessage]) {
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
            self.scheduleQueue.async {
                self.processMessages()
            }
        }
    }

    // This must be called from MainThread
    private func showInternal(message: IterableInAppMessage,
                              consume: Bool,
                              callback: ITBURLCallback? = nil) {
        ITBInfo()

        guard Thread.isMainThread else {
            ITBError("This must be called from the main thread")
            return
        }

        switch displayer.showInApp(message: message) {
        case .notShown(let reason):
            ITBError("Could not show message: \(reason)")
        case .shown(let futureClickedURL):
            // set read
            set(read: true, forMessage: message)
            
            updateMessage(message, didProcessTrigger: true, consumed: consume)

            futureClickedURL.onSuccess { url in
                // call the client callback, if present
                _ = callback?(url)
                
                // in addition perform action or url delegate task
                self.handle(clickedUrl: url, forMessage: message)
                
                // set the dismiss time"
                self.lastDismissedTime = self.dateProvider.currentDate
                
                // check if we need to process more inApps
                self.scheduleNextInAppMessage()
                
                if consume {
                    self.apiClient?.inappConsume(messageId: message.messageId)
                }
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
                    self.processMessages()
                }
            } else {
                self.processMessages()
            }
        }
    }
    
    private func processMessages()  {
        ITBDebug()
        
        _ = processNextMessage().map { (processResult) -> Void in
            switch (processResult) {
            case .show(let message):
                self.updateMessage(message, didProcessTrigger: true)
                let consume = !message.saveToInbox
                DispatchQueue.main.async {
                    self.showInternal(message: message, consume: consume, callback: nil)
                }
            case .skip(let message):
                self.updateMessage(message, didProcessTrigger: true)
                self.processMessages()
            case .wait:
                break
            }
        }
    }

    private enum ProcessNextMessageResult {
        case show(IterableInAppMessage)
        case skip(IterableInAppMessage)
        case wait
    }
    
    private func processNextMessage() -> Future<ProcessNextMessageResult, IterableError> {
        ITBDebug()
        
        guard let message = getFirstProcessableTriggeredMessage() else {
            ITBDebug("No message to process")
            return Promise<ProcessNextMessageResult, IterableError>(value: .wait)
        }
        
        ITBDebug("processing message with id: \(message.messageId)")
        
        let result = Promise<ProcessNextMessageResult, IterableError>()
        
        _ = checkMessage(message).map { (checkMessageResult) -> Void in
            switch checkMessageResult {
            case .notReady:
                result.resolve(with: .wait)
            case .inAppShowResponse(let inAppShowResponse):
                if inAppShowResponse == .show {
                    result.resolve(with: .show(message))
                } else {
                    result.resolve(with: .skip(message))
                }
            }
        }
        
        return result
    }
    
    private enum CheckMessageResult {
        case inAppShowResponse(InAppShowResponse)
        case notReady
    }
    
    private func checkMessage(_ message: IterableInAppMessage) -> Future<CheckMessageResult, IterableError> {
        return canShowMessageNow(message: message).map { (canShow) -> CheckMessageResult in
            if canShow {
                return .inAppShowResponse(self.inAppDelegate.onNew(message: message))
            } else {
                return .notReady
            }
        }
    }

    private func canShowMessageNow(message: IterableInAppMessage) -> Future<Bool, IterableError> {
        let result = Promise<Bool, IterableError>()
        DispatchQueue.main.async {
            result.resolve(with: self.isOkToShowNow(message: message))
        }
        return result
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

    private func handle(clickedUrl url: URL?, forMessage message: IterableInAppMessage) {
        guard let theUrl = url, let inAppClickedUrl = InAppHelper.parse(inAppUrl: theUrl) else {
            ITBError("Could not parse url: \(url?.absoluteString ?? "nil")")
            return
        }
        
        switch (inAppClickedUrl) {
        case .iterableCustomAction(name: let iterableCustomActionName):
            handleIterableCustomAction(name: iterableCustomActionName, forMessage: message)
            break
        case .customAction(name: let customActionName):
            handleUrlOrAction(urlOrAction: customActionName)
            break
        case .localResource(name: let localResourceName):
            handleUrlOrAction(urlOrAction: localResourceName)
            break
        case .regularUrl(_):
            handleUrlOrAction(urlOrAction: theUrl.absoluteString)
        }
    }
    
    private func handleIterableCustomAction(name: String, forMessage message: IterableInAppMessage) {
        guard let iterableCustomActionName = IterableCustomActionName(rawValue: name) else {
            return
        }

        switch iterableCustomActionName {
        case .delete:
            remove(message: message)
            break
        case .dismiss:
            break
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
    
    private func initializeMessagesMap() {
        let messages = persister.getMessages()
        for message in messages {
            messagesMap[message.messageId] = message
        }
    }

    // From client side
    private func removePrivate(message: IterableInAppMessage) {
        ITBInfo()
        
        updateMessage(message, didProcessTrigger: true, consumed: true)
        apiClient?.inappConsume(messageId: message.messageId)
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
    
    private weak var apiClient: ApiClientProtocol?
    private var fetcher: InAppFetcherProtocol // this is mutable because we need to set internalApi
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

extension InAppManager : InAppNotifiable {
    func onInAppSyncNeeded() {
        ITBInfo()
        synchronize()
    }
    
    // from server side
    func onInAppRemoved(messageId: String) {
        ITBInfo()
        
        updateQueue.async {
            if let _ = self.messagesMap.filter({$0.key == messageId}).first {
                self.messagesMap.removeValue(forKey: messageId)
                self.persister.persist(self.messagesMap.values)
            }
        }
        self.callbackQueue.async {
            self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
        }
    }
}

class EmptyInAppManager : IterableInAppManagerProtocolInternal {
    weak var internalApi: IterableAPIInternal?
    
    func start() {
    }
    
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
    
    func show(message: IterableInAppMessage) {
    }
    
    func show(message: IterableInAppMessage, consume: Bool, callback: ITBURLCallback?) {
    }

    func remove(message: IterableInAppMessage) {
    }

    func set(read: Bool, forMessage message: IterableInAppMessage) {
    }

    func getUnreadInboxMessagesCount() -> Int {
        return 0
    }

    func onInAppSyncNeeded() {
    }
    
    func onInAppRemoved(messageId: String) {
    }
}

