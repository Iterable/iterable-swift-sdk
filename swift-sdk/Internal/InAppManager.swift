//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

protocol NotificationCenterProtocol {
    func addObserver(_ observer: Any, selector: Selector, name: Notification.Name?, object: Any?)
    func removeObserver(_ observer: Any)
    func post(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?)
}

extension NotificationCenter: NotificationCenterProtocol {}

// This is internal. Do not expose

protocol InAppDisplayChecker {
    func isOkToShowNow(message: IterableInAppMessage) -> Bool
}

protocol IterableInternalInAppManagerProtocol: IterableInAppManagerProtocol, InAppNotifiable, InAppDisplayChecker {
    func start() -> Future<Bool, Error>
    /// This will create a ViewController which displays an inbox message.
    /// This ViewController would typically be pushed into the navigation stack.
    /// - parameter message: The message to show.
    /// - parameter inboxMode:
    /// - returns: UIViewController which displays the message.
    func createInboxMessageViewController(for message: IterableInAppMessage, withInboxMode inboxMode: IterableInboxViewController.InboxMode, inboxSessionId: String?) -> UIViewController?
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    /// - parameter inboxSessionId: The ID of the inbox session that the message originates from.
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, inboxSessionId: String?)
}

class InAppManager: NSObject, IterableInternalInAppManagerProtocol {
    init(apiClient: ApiClientProtocol,
         deviceMetadata: DeviceMetadata,
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
        self.deviceMetadata = deviceMetadata
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
        
        initializeMessagesMap()
        
        self.notificationCenter.addObserver(self,
                                            selector: #selector(onAppEnteredForeground(notification:)),
                                            name: UIApplication.didBecomeActiveNotification,
                                            object: nil)
    }
    
    deinit {
        ITBInfo()
        
        notificationCenter.removeObserver(self)
    }
    
    // MARK: - IterableInAppManagerProtocol
    
    var isAutoDisplayPaused: Bool {
        get {
            autoDisplayPaused
        }
        
        set {
            autoDisplayPaused = newValue
            
            if !autoDisplayPaused {
                _ = scheduleSync()
            }
        }
    }
    
    func getMessages() -> [IterableInAppMessage] {
        ITBInfo()
        
        return Array(messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: self.dateProvider.currentDate) })
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        ITBInfo()
        
        return Array(messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: self.dateProvider.currentDate) && $0.saveToInbox == true })
    }
    
    func getUnreadInboxMessagesCount() -> Int {
        return getInboxMessages().filter { $0.read == false }.count
    }
    
    func show(message: IterableInAppMessage) {
        ITBInfo()
        
        show(message: message, consume: true, callback: nil)
    }
    
    func show(message: IterableInAppMessage, consume: Bool = true, callback: ITBURLCallback? = nil) {
        ITBInfo()
        
        // This is public (via public protocol implementation), so make sure we call from Main Thread
        DispatchQueue.main.async {
            self.showInternal(message: message, consume: consume, callback: callback)
        }
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation) {
        ITBInfo()
        
        removePrivate(message: message, location: location)
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource) {
        ITBInfo()
        
        removePrivate(message: message, location: location, source: source)
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, inboxSessionId: String? = nil) {
        ITBInfo()
        
        removePrivate(message: message, location: location, source: source, inboxSessionId: inboxSessionId)
    }
    
    func set(read: Bool, forMessage message: IterableInAppMessage) {
        updateMessage(message, read: read).onSuccess { _ in
            self.callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
    }
    
    func getMessage(withId id: String) -> IterableInAppMessage? {
        return messagesMap[id]
    }
    
    // MARK: - IterableInternalInAppManagerProtocol
    
    func start() -> Future<Bool, Error> {
        ITBInfo()
        
        if messagesMap.values.filter({ $0.saveToInbox }).count > 0 {
            callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        
        return scheduleSync()
    }
    
    func createInboxMessageViewController(for message: IterableInAppMessage,
                                          withInboxMode inboxMode: IterableInboxViewController.InboxMode,
                                          inboxSessionId: String? = nil) -> UIViewController? {
        guard let content = message.content as? IterableHtmlInAppContent else {
            ITBError("Invalid Content in message")
            return nil
        }
        
        let parameters = IterableHtmlMessageViewController.Parameters(html: content.html,
                                                                      padding: content.edgeInsets,
                                                                      messageMetadata: IterableInAppMessageMetadata(message: message, location: .inbox),
                                                                      isModal: inboxMode == .popup,
                                                                      inboxSessionId: inboxSessionId)
        let createResult = IterableHtmlMessageViewController.create(parameters: parameters)
        let viewController = createResult.viewController
        
        createResult.futureClickedURL.onSuccess { url in
            ITBInfo()
            
            // in addition perform action or url delegate task
            self.handle(clickedUrl: url, forMessage: message, location: .inbox)
        }
        
        viewController.navigationItem.title = message.inboxMetadata?.title
        
        return viewController
    }
    
    func remove(message: IterableInAppMessage) {
        ITBInfo()
        
        removePrivate(message: message)
    }
    
    // MARK: - Private/Internal
    
    @objc private func onAppEnteredForeground(notification _: Notification) {
        ITBInfo()
        
        let waitTime = InAppManager.getWaitTimeInterval(fromLastTime: lastSyncTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval)
        
        if waitTime <= 0 {
            _ = scheduleSync()
        } else {
            ITBInfo("can't sync now, need to wait: \(waitTime)")
        }
    }
    
    private func synchronize(appIsReady: Bool) -> Future<Bool, Error> {
        ITBInfo()
        
        return fetcher.fetch()
            .map { self.mergeMessages($0) }
            .map { self.processMergedMessages(appIsReady: appIsReady, mergeMessagesResult: $0) }
    }
    
    // messages are new messages coming from the server
    private func mergeMessages(_ messages: [IterableInAppMessage]) -> MergeMessagesResult {
        return MessagesObtainedHandler(messagesMap: messagesMap, messages: messages).handle()
    }
    
    private func processMergedMessages(appIsReady: Bool, mergeMessagesResult: MergeMessagesResult) -> Bool {
        if appIsReady {
            processAndShowMessage(messagesMap: mergeMessagesResult.messagesMap)
        } else {
            messagesMap = mergeMessagesResult.messagesMap
        }
        
        // track in app delivery
        mergeMessagesResult.deliveredMessages.forEach {
            _ = apiClient?.track(inAppDelivery: InAppMessageContext.from(message: $0, location: nil))
        }
        
        finishSync(inboxChanged: mergeMessagesResult.inboxChanged)
        
        return true
    }
    
    private func finishSync(inboxChanged: Bool) {
        ITBInfo()
        
        if inboxChanged {
            callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        
        persister.persist(messagesMap.values)
        lastSyncTime = dateProvider.currentDate
    }
    
    private func getMessagesMap(fromMessagesProcessorResult messagesProcessorResult: MessagesProcessorResult) -> OrderedDictionary<String, IterableInAppMessage> {
        switch messagesProcessorResult {
        case let .noShow(messagesMap: messagesMap):
            return messagesMap
        case .show(message: _, messagesMap: let messagesMap):
            return messagesMap
        }
    }
    
    // Not a pure function.
    private func showMessage(fromMessagesProcessorResult messagesProcessorResult: MessagesProcessorResult) {
        if case MessagesProcessorResult.show(let message, _) = messagesProcessorResult {
            lastDisplayTime = dateProvider.currentDate
            ITBDebug("Setting last display time: \(String(describing: lastDisplayTime))")
            
            self.show(message: message, consume: !message.saveToInbox)
        }
    }
    
    private func processAndShowMessage(messagesMap: OrderedDictionary<String, IterableInAppMessage>) {
        var processor = MessagesProcessor(inAppDelegate: inAppDelegate, inAppDisplayChecker: self, messagesMap: messagesMap)
        let messagesProcessorResult = processor.processMessages()
        self.messagesMap = getMessagesMap(fromMessagesProcessorResult: messagesProcessorResult)
        
        showMessage(fromMessagesProcessorResult: messagesProcessorResult)
    }
    
    private func showInternal(message: IterableInAppMessage,
                              consume: Bool,
                              callback: ITBURLCallback? = nil) {
        ITBInfo()
        
        guard Thread.isMainThread else {
            ITBError("This must be called from the main thread")
            return
        }
        
        switch displayer.showInApp(message: message) {
        case let .notShown(reason):
            ITBError("Could not show message: \(reason)")
        case let .shown(futureClickedURL):
            ITBDebug("in-app shown")
            
            set(read: true, forMessage: message)
            
            updateMessage(message, didProcessTrigger: true, consumed: consume)
            
            futureClickedURL.onSuccess { url in
                ITBDebug("in-app clicked")
                
                // call the client callback, if present
                _ = callback?(url)
                
                // in addition perform action or url delegate task
                self.handle(clickedUrl: url, forMessage: message, location: .inApp)
                
                // set the dismiss time
                self.lastDismissedTime = self.dateProvider.currentDate
                ITBDebug("Setting last dismissed time: \(String(describing: self.lastDismissedTime))")
                
                // check if we need to process more in-apps
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
        
        let waitTimeInterval = getInAppShowingWaitTimeInterval()
        
        if waitTimeInterval > 0 {
            ITBDebug("Need to wait for: \(waitTimeInterval)")
            scheduleQueue.asyncAfter(deadline: .now() + waitTimeInterval) {
                self.scheduleNextInAppMessage()
            }
        } else {
            _ = InAppManager.getAppIsReady(applicationStateProvider: applicationStateProvider, displayer: displayer).map { appIsActive in
                if appIsActive {
                    self.processAndShowMessage(messagesMap: self.messagesMap)
                    self.persister.persist(self.messagesMap.values)
                }
            }
        }
    }
    
    @discardableResult
    private func updateMessage(_ message: IterableInAppMessage,
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
        
        messagesMap.updateValue(toUpdate, forKey: message.messageId)
        persister.persist(messagesMap.values)
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
    
    private func handle(clickedUrl url: URL?, forMessage message: IterableInAppMessage, location: InAppLocation) {
        guard let theUrl = url, let inAppClickedUrl = InAppHelper.parse(inAppUrl: theUrl) else {
            ITBError("Could not parse url: \(url?.absoluteString ?? "nil")")
            return
        }
        
        switch inAppClickedUrl {
        case let .iterableCustomAction(name: iterableCustomActionName):
            handleIterableCustomAction(name: iterableCustomActionName, forMessage: message, location: location)
        case let .customAction(name: customActionName):
            handleUrlOrAction(urlOrAction: customActionName)
        case let .localResource(name: localResourceName):
            handleUrlOrAction(urlOrAction: localResourceName)
        case .regularUrl:
            handleUrlOrAction(urlOrAction: theUrl.absoluteString)
        }
    }
    
    private func handleIterableCustomAction(name: String, forMessage message: IterableInAppMessage, location: InAppLocation) {
        guard let iterableCustomActionName = IterableCustomActionName(rawValue: name) else {
            return
        }
        
        switch iterableCustomActionName {
        case .delete:
            remove(message: message, location: location, source: .deleteButton)
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
            return IterableAction.action(fromDictionary: ["type": urlOrAction])
        }
    }
    
    private func initializeMessagesMap() {
        let messages = persister.getMessages()
        
        for message in messages {
            messagesMap[message.messageId] = message
        }
    }
    
    // From client side
    private func removePrivate(message: IterableInAppMessage,
                               location: InAppLocation = .inApp,
                               source: InAppDeleteSource? = nil,
                               inboxSessionId: String? = nil) {
        ITBInfo()
        
        updateMessage(message, didProcessTrigger: true, consumed: true)
        let messageContext = InAppMessageContext.from(message: message, location: location, inboxSessionId: inboxSessionId)
        apiClient?.inAppConsume(inAppMessageContext: messageContext, source: source)
        
        callbackQueue.async {
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
    
    fileprivate static func getAppIsReady(applicationStateProvider: ApplicationStateProviderProtocol,
                                          displayer: InAppDisplayerProtocol) -> Promise<Bool, Error> {
        if Thread.isMainThread {
            let ready = (applicationStateProvider.applicationState == .active) && (displayer.isShowingInApp() == false)
            return Promise(value: ready)
        } else {
            let result = Promise<Bool, Error>()
            
            DispatchQueue.main.async {
                let ready = (applicationStateProvider.applicationState == .active) && (displayer.isShowingInApp() == false)
                result.resolve(with: ready)
            }
            
            return result
        }
    }
    
    private weak var apiClient: ApiClientProtocol?
    private let deviceMetadata: DeviceMetadata
    private let fetcher: InAppFetcherProtocol
    private let displayer: InAppDisplayerProtocol
    private let inAppDelegate: IterableInAppDelegate
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    private let applicationStateProvider: ApplicationStateProviderProtocol
    private let notificationCenter: NotificationCenterProtocol
    
    private let persister: InAppPersistenceProtocol
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>()
    private let dateProvider: DateProviderProtocol
    private let retryInterval: TimeInterval // in seconds, if a message is already showing how long to wait?
    private var lastDismissedTime: Date?
    private var lastDisplayTime: Date?
    
    private let updateQueue = DispatchQueue(label: "UpdateQueue")
    private let scheduleQueue = DispatchQueue(label: "ScheduleQueue")
    private let callbackQueue = DispatchQueue(label: "CallbackQueue")
    private let syncQueue = DispatchQueue(label: "SyncQueue")
    
    private var syncResult: Future<Bool, Error>?
    private var lastSyncTime: Date?
    private let moveToForegroundSyncInterval: Double = 1.0 * 60.0 // don't sync within sixty seconds
    private var autoDisplayPaused = false
}

extension InAppManager: InAppNotifiable {
    func scheduleSync() -> Future<Bool, Error> {
        ITBInfo()
        
        return InAppManager.getAppIsReady(applicationStateProvider: applicationStateProvider, displayer: displayer).flatMap { self.scheduleSync(appIsReady: $0) }
    }
    
    private func scheduleSync(appIsReady: Bool) -> Future<Bool, Error> {
        ITBInfo()
        
        let result = Promise<Bool, Error>()
        
        syncQueue.async {
            if let syncResult = self.syncResult {
                if syncResult.isResolved() {
                    self.syncResult = self.synchronize(appIsReady: appIsReady)
                } else {
                    self.syncResult = syncResult.flatMap { _ in self.synchronize(appIsReady: appIsReady) }
                }
            } else {
                self.syncResult = self.synchronize(appIsReady: appIsReady)
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
            if let _ = self.messagesMap.filter({ $0.key == messageId }).first {
                self.messagesMap.removeValue(forKey: messageId)
                self.persister.persist(self.messagesMap.values)
            }
        }
        
        callbackQueue.async {
            self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
        }
    }
    
    func reset() -> Future<Bool, Error> {
        ITBInfo()
        
        let result = Promise<Bool, Error>()
        
        syncQueue.async {
            self.messagesMap.reset()
            self.persister.persist(self.messagesMap.values)
            
            self.callbackQueue.async {
                self.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
                result.resolve(with: true)
            }
        }
        
        return result
    }
}

extension InAppManager: InAppDisplayChecker {
    func isOkToShowNow(message: IterableInAppMessage) -> Bool {
        guard !isAutoDisplayPaused else {
            ITBInfo("automatic in-app display has been paused")
            return false
        }
        
        guard !message.didProcessTrigger else {
            ITBInfo("message with id: \(message.messageId) is already processed")
            return false
        }
        
        guard InAppManager.getWaitTimeInterval(fromLastTime: lastDismissedTime, currentTime: dateProvider.currentDate, gap: retryInterval) <= 0 else {
            ITBInfo("can't display within retryInterval window")
            return false
        }
        
        guard InAppManager.getWaitTimeInterval(fromLastTime: lastDisplayTime, currentTime: dateProvider.currentDate, gap: retryInterval) <= 0 else {
            ITBInfo("can't display within retryInterval window")
            return false
        }
        
        return true
    }
}
