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

extension NotificationCenter: NotificationCenterProtocol {
}

// This is internal. Do not expose

protocol InAppDisplayChecker {
    func isOkToShowNow(message: IterableInAppMessage) -> Bool
}

protocol IterableInAppManagerProtocolInternal : IterableInAppManagerProtocol, InAppNotifiable, InAppDisplayChecker {
    func start()
}

class InAppManager: NSObject, IterableInAppManagerProtocolInternal {
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
        _ = scheduleSync()
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        
        return Array(self.messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: self.dateProvider.currentDate)})
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        ITBInfo()
        return Array(self.messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: self.dateProvider.currentDate) && $0.saveToInbox == true})
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
                                                                      trackParams: IterableInAppMessageMetadata.metadata(from: message, location: AnyHashable.ITBL_IN_APP_LOCATION_INBOX),
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
        updateMessage(message, read: true).onSuccess { _ in
            self.callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
    }
    
    func isOkToShowNow(message: IterableInAppMessage) -> Bool {
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
    
    @objc private func onAppEnteredForeground(notification: Notification) {
        ITBInfo()
        let waitTime = InAppManager.getWaitTimeInterval(fromLastTime: lastSyncTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval)
        if waitTime <= 0 {
            _ = scheduleSync()
        } else {
            ITBInfo("can't sync now, need to wait: \(waitTime)")
        }
    }

    private func synchronize() -> Future<Bool, Error> {
        ITBInfo()
        return
            fetcher.fetch()
                .map { self.mergeMessages($0) }
                .flatMap { self.processMergedMessages($0) }
    }
    
    // messages are new messages coming from the server
    // This function
    private func mergeMessages(_ messages: [IterableInAppMessage]) -> MergeMessagesResult {
        var messagesObtainedHandler = MessagesObtainedHandler(messagesMap: self.messagesMap, messages: messages)
        return messagesObtainedHandler.handle()
    }

    private func processMergedMessages(_ mergeMessagesResult: MergeMessagesResult) -> Future<Bool, Error> {
        let result = Promise<Bool, Error>()
        DispatchQueue.main.async {
            // we can only check on main thread
            if self.applicationStateProvider.applicationState == .active {
                self.processMessages(messagesMap: mergeMessagesResult.messagesMap).onSuccess { (processMessagesResult) in
                    self.onMessagesProcessed(processMessagesResult)

                    self.finishSync(inboxChanged: mergeMessagesResult.inboxChanged)

                    result.resolve(with: true)
                }
            } else {
                self.messagesMap = mergeMessagesResult.messagesMap

                self.finishSync(inboxChanged: mergeMessagesResult.inboxChanged)

                result.resolve(with: true)
            }
        }
        return result
    }
    
    private func finishSync(inboxChanged: Bool) {
        ITBInfo()
        if inboxChanged {
            self.callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        
        self.persister.persist(self.messagesMap.values)
        self.lastSyncTime = self.dateProvider.currentDate
    }
    
    // Not a pure function. This has side effect of showing the message
    private func onMessagesProcessed(_ processMessagesResult: ProcessMessagesResult) {
        self.messagesMap = getMessagesMap(fromProcessMessagesResult: processMessagesResult)
        showMessage(fromProcessMessagesResult: processMessagesResult)
    }
    
    private func getMessagesMap(fromProcessMessagesResult processMessagesResult: ProcessMessagesResult) -> OrderedDictionary<String, IterableInAppMessage> {
        switch processMessagesResult {
        case .noShow(messagesMap: let messagesMap):
            return messagesMap
        case .show(message: _, messagesMap: let messagesMap):
            return messagesMap
        }
    }
    
    // Not a pure function.
    private func showMessage(fromProcessMessagesResult processMessagesResult: ProcessMessagesResult) {
        if case let ProcessMessagesResult.show(message: message, messagesMap: _) = processMessagesResult {
            self.show(message: message, consume: !message.saveToInbox)
        }
    }
    
    private func processMessages(messagesMap: OrderedDictionary<String, IterableInAppMessage>) -> Future<ProcessMessagesResult, Error> {
        let result = Promise<ProcessMessagesResult, Error>()
        syncQueue.async {
            var messagesProcessor = MessagesProcessor(inAppDelegate: self.inAppDelegate, inAppDisplayChecker: self, messagesMap: messagesMap)
            result.resolve(with: messagesProcessor.processMessages())
        }
        return result
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
                
                // set the dismiss time
                self.lastDismissedTime = self.dateProvider.currentDate
                
                // check if we need to process more inApps
                self.scheduleNextInAppMessage()
                
                if consume {
                    self.apiClient?.inAppConsume(messageId: message.messageId)
                }
            }
        }
    }
    
    // This method schedules next triggered message after showing a message
    private func scheduleNextInAppMessage() {
        ITBDebug()

        let waitTimeInterval = self.getInAppShowingWaitTimeInterval()
        if waitTimeInterval > 0 {
            ITBDebug("Need to wait for: \(waitTimeInterval)")
            self.scheduleQueue.asyncAfter(deadline: .now() + waitTimeInterval) {
                self.scheduleNextInAppMessage()
            }
        } else {
            DispatchQueue.main.async {
                if self.applicationStateProvider.applicationState == .active {
                    self.processMessages(messagesMap: self.messagesMap).onSuccess { processMessagesResult in
                        self.onMessagesProcessed(processMessagesResult)
                        self.persister.persist(self.messagesMap.values)
                    }
                }
            }
        }
    }
    
    @discardableResult private func updateMessage(_ message: IterableInAppMessage,
                                                  read: Bool? = nil,
                                                  didProcessTrigger: Bool? = nil,
                                                  consumed: Bool? = nil) -> Future<Bool, IterableError> {
        ITBDebug()
        let result = Promise<Bool, IterableError>()
        updateQueue.async {
            self.updateMessageSync(message, read: read, didProcessTrigger: didProcessTrigger, consumed: consumed)
            result.resolve(with: true)
        }
        return result
    }

    private func updateMessageSync(_ message: IterableInAppMessage,
                                   read: Bool? = nil,
                                   didProcessTrigger: Bool? = nil,
                                   consumed: Bool? = nil) {
        ITBDebug()
        let toUpdate = message
        if let read = read {
            toUpdate.read = read
        }
        if let didProcessTrigger = didProcessTrigger {
            toUpdate.didProcessTrigger = didProcessTrigger
        }
        if let consumed = consumed {
            toUpdate.consumed = consumed
        }
        self.messagesMap.updateValue(toUpdate, forKey: message.messageId)
        self.persister.persist(self.messagesMap.values)
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
        apiClient?.inAppConsume(messageId: message.messageId)
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
    private let callbackQueue = DispatchQueue(label: "CallbackQueue")
    private let syncQueue = DispatchQueue(label: "SyncQueue")
    
    private var syncResult: Future<Bool, Error>?
    private var lastSyncTime: Date? = nil
    private let moveToForegroundSyncInterval: Double = 1.0 * 60.0 // don't sync within sixty seconds
}

extension InAppManager: InAppNotifiable {
    func scheduleSync() -> Future<Bool, Error> {
        ITBInfo()
        
        let result = Promise<Bool, Error>()
        self.syncQueue.async {
            if let syncResult = self.syncResult {
                if syncResult.isResolved() {
                    self.syncResult = self.synchronize()
                } else {
                    self.syncResult = syncResult.flatMap { _ in self.synchronize() }
                }
            } else {
                self.syncResult = self.synchronize()
            }
            self.syncResult?.onSuccess { success in
                result.resolve(with: success)
            }.onError { error in
                result.reject(with: error)
            }
        }
        return result
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
