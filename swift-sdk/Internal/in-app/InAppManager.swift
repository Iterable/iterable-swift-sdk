//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

protocol InAppDisplayChecker {
    func isOkToShowNow(message: IterableInAppMessage) -> Bool
}

protocol IterableInternalInAppManagerProtocol: IterableInAppManagerProtocol, InAppNotifiable, InAppDisplayChecker {
    func start() -> Pending<Bool, Error>

    func getUnhandledJsonOnlyMessages() -> [IterableInAppMessage]
    func markJsonOnlyMessageHandled(messageId: String) -> Bool
    func clearUnhandledJsonOnlyMessages()
    
    /// Use this method to handle clicks in InApp Messages
    /// - parameter clickedUrl: The url that is clicked.
    /// - parameter message: The message where the url was clicked.
    /// - parameter location: The location `inbox` or `inApp` where the message was shown.
    /// - parameter inboxSessionId: The ID of the inbox session that the message originates from.
    func handleClick(clickedUrl url: URL?, forMessage message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?)
    
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    /// - parameter inboxSessionId: The ID of the inbox session that the message originates from.
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, inboxSessionId: String?)
    
    /// - parameter message: The message to remove.
    /// - parameter location: The location from where this message was shown. `inbox` or `inApp`.
    /// - parameter source: The source of deletion `inboxSwipe` or `deleteButton`.`
    /// - parameter inboxSessionId: The ID of the inbox session that the message originates from.
    /// - parameter successHandler: The callback which returns `success.
    /// - parameter failureHandler: The callback which returns `failure.
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, inboxSessionId: String?, successHandler: OnSuccessHandler?, failureHandler: OnFailureHandler?)
}

class InAppManager: NSObject, IterableInternalInAppManagerProtocol {
    
    init(requestHandler: RequestHandlerProtocol,
         deviceMetadata: DeviceMetadata,
         fetcher: InAppFetcherProtocol,
         displayer: InAppDisplayerProtocol,
         persister: InAppPersistenceProtocol,
         inAppDelegate: IterableInAppDelegate,
         inAppDisplayDelegate: IterableInAppDisplayDelegate?,
         urlDelegate: IterableURLDelegate?,
         customActionDelegate: IterableCustomActionDelegate?,
         urlOpener: UrlOpenerProtocol,
         allowedProtocols: [String],
         applicationStateProvider: ApplicationStateProviderProtocol,
         notificationCenter: NotificationCenterProtocol,
         dateProvider: DateProviderProtocol,
         jsonOnlyMessageStore: JsonOnlyMessageStore,
         identityCoordinator: IdentityCoordinator,
         identityProvider: @escaping () -> UserIdentitySnapshot?,
         moveToForegroundSyncInterval: Double) {
        ITBInfo()
        
        self.requestHandler = requestHandler
        self.deviceMetadata = deviceMetadata
        self.fetcher = fetcher
        self.displayer = displayer
        self.persister = persister
        self.inAppDelegate = inAppDelegate
        self.inAppDisplayDelegate = inAppDisplayDelegate
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
        self.allowedProtocols = allowedProtocols
        self.applicationStateProvider = applicationStateProvider
        self.notificationCenter = notificationCenter
        self.dateProvider = dateProvider
        self.jsonOnlyMessageStore = jsonOnlyMessageStore
        self.identityCoordinator = identityCoordinator
        self.identityProvider = identityProvider
        self.moveToForegroundSyncInterval = moveToForegroundSyncInterval
        
        super.init()
        
        initializeMessagesMap()
        messagesIdentityContext = identityCoordinator.capture(identityProvider: identityProvider)
        
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

        var messages = [IterableInAppMessage]()
        let didRead = identityCoordinator.withCriticalSection {
            guard let context = messagesIdentityContext else { return false }
            return identityCoordinator.performIfCurrent(context, identityProvider: identityProvider) {
                messages = Array(messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: self.dateProvider.currentDate) })
            }
        }
        guard didRead else { return [] }
        return messages
    }
    
    func getInboxMessages() -> [IterableInAppMessage] {
        ITBInfo()

        var messages = [IterableInAppMessage]()
        let didRead = identityCoordinator.withCriticalSection {
            guard let context = messagesIdentityContext else { return false }
            return identityCoordinator.performIfCurrent(context, identityProvider: identityProvider) {
                messages = Array(messagesMap.values.filter { InAppManager.isValid(message: $0, currentDate: self.dateProvider.currentDate) && $0.saveToInbox })
            }
        }
        guard didRead else { return [] }
        return messages
    }
    
    func getUnreadInboxMessagesCount() -> Int {
        getInboxMessages().filter { $0.read == false }.count
    }

    func getUnhandledJsonOnlyMessages() -> [IterableInAppMessage] {
        jsonOnlyMessageStore.getMessages()
    }

    func markJsonOnlyMessageHandled(messageId: String) -> Bool {
        jsonOnlyMessageStore.remove(messageId: messageId)
    }

    func clearUnhandledJsonOnlyMessages() {
        jsonOnlyMessageStore.clear()
    }
    
    func show(message: IterableInAppMessage) {
        ITBInfo()
        
        show(message: message, consume: true, callback: nil)
    }
    
    func show(message: IterableInAppMessage, consume: Bool = true, callback: ITBURLCallback? = nil) {
        ITBInfo()
        
        // This is public (via public protocol implementation), so make sure we call from Main Thread
        DispatchQueue.main.async {[weak self] in
            self?.showInternal(message: message, consume: consume, callback: callback)
        }
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation) {
        ITBInfo()
        
        remove(message: message, location: location, successHandler: nil, failureHandler: nil)
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation, successHandler: OnSuccessHandler? = nil, failureHandler: OnFailureHandler? = nil) {
        removePrivate(message: message, location: location, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource) {
        remove(message: message, location: location, source: source, successHandler: nil, failureHandler: nil)
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, successHandler: OnSuccessHandler? = nil, failureHandler: OnFailureHandler? = nil) {
        
        removePrivate(message: message, location: location, source: source, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, inboxSessionId: String?) {
        ITBInfo()
        
        remove(message: message, location: location, source: source, inboxSessionId: inboxSessionId, successHandler: nil, failureHandler: nil)
    }
    
    func remove(message: IterableInAppMessage, location: InAppLocation, source: InAppDeleteSource, inboxSessionId: String? = nil, successHandler: OnSuccessHandler? = nil, failureHandler: OnFailureHandler? = nil) {
        removePrivate(message: message, location: location, source: source, inboxSessionId: inboxSessionId, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    func set(read: Bool, forMessage message: IterableInAppMessage) {
        set(read: read, forMessage: message, successHandler: nil, failureHandler: nil)
    }
    
    func set(read: Bool, forMessage message: IterableInAppMessage, successHandler: OnSuccessHandler? = nil, failureHandler: OnFailureHandler? = nil) {
        updateMessage(message, read: read).onSuccess { [weak self] _ in
            successHandler?([:])
            self?.callbackQueue.async { [weak self] in
                self?.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }.onError { [weak self] _ in
            failureHandler?(self?.description, nil)
        }
    }
    
    func getMessage(withId id: String) -> IterableInAppMessage? {
        var message: IterableInAppMessage?
        let didRead = identityCoordinator.withCriticalSection {
            guard let context = messagesIdentityContext else { return false }
            return identityCoordinator.performIfCurrent(context, identityProvider: identityProvider) {
                message = messagesMap[id]
            }
        }
        guard didRead else { return nil }
        return message
    }
    
    // MARK: - IterableInternalInAppManagerProtocol
    
    func start() -> Pending<Bool, Error> {
        ITBInfo()
        
        if messagesMap.values.filter({ $0.saveToInbox }).count > 0 {
            callbackQueue.async { [weak self] in
                self?.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        
        return replayUnhandledJsonOnlyMessages().flatMap { [weak self] _ in
            self?.scheduleSync() ?? Fulfill<Bool, Error>(value: true)
        }
    }
    
    func handleClick(clickedUrl url: URL?, forMessage message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?) {
        guard let theUrl = url, let inAppClickedUrl = InAppHelper.parse(inAppUrl: theUrl) else {
            ITBError("Could not parse url: \(url?.absoluteString ?? "nil")")
            return
        }
        
        switch inAppClickedUrl {
        case let .iterableCustomAction(name: iterableCustomActionName):
            handleIterableCustomAction(name: iterableCustomActionName, forMessage: message, location: location, inboxSessionId: inboxSessionId)
        case let .customAction(name: customActionName):
            handleUrlOrAction(urlOrAction: customActionName)
        case let .localResource(name: localResourceName):
            handleUrlOrAction(urlOrAction: localResourceName)
        case .regularUrl:
            handleUrlOrAction(urlOrAction: theUrl.absoluteString)
        }
    }
    
    func remove(message: IterableInAppMessage) {
        ITBInfo()

        remove(message: message, successHandler: nil, failureHandler: nil)
    }
    
    func remove(message: IterableInAppMessage, successHandler: OnSuccessHandler?, failureHandler: OnFailureHandler?) {
        removePrivate(message: message, location: .inApp, source: nil, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    // MARK: - Private/Internal
    
    @objc private func onAppEnteredForeground(notification _: Notification) {
        ITBInfo()

        replayUnhandledJsonOnlyMessages().onSuccess { [weak self] _ in
            self?.processForegroundMessages()
        }
    }

    private func processForegroundMessages() {
        ITBInfo()
        
        let waitTime = InAppManager.getWaitTimeInterval(fromLastTime: lastSyncTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval)
        
        if waitTime <= 0 {
            _ = scheduleSync()
        } else {
            ITBInfo("skipping sync (cooldown: \(waitTime)s), processing existing messages")
            
            processExistingMessages()
        }
    }
    
    private func synchronize(appIsReady: Bool) -> Pending<Bool, Error> {
        ITBInfo()
        
        let identityContext = identityCoordinator.capture(identityProvider: identityProvider)
        return fetcher.fetch()
            .flatMap { [weak self] messages in
                self?.processFetchedMessages(messages,
                                             appIsReady: appIsReady,
                                             identityContext: identityContext) ?? Fulfill<Bool, Error>(value: true)
            }
    }

    private func processFetchedMessages(_ messages: [IterableInAppMessage],
                                        appIsReady: Bool,
                                        identityContext: UserIdentityContext) -> Pending<Bool, Error> {
        let result = Fulfill<Bool, Error>()

        syncQueue.async { [weak self] in
            guard let self = self else {
                result.resolve(with: true)
                return
            }

            var mergeResult: MergeMessagesResult?
            var processingRevision: UInt64?
            let committed = self.identityCoordinator.performIfCurrent(identityContext,
                                                                       identityProvider: self.identityProvider) {
                let acknowledgementStatus = self.jsonOnlyMessageStore.acknowledgementStatus(for: messages,
                                                                                             identityContext: identityContext)
                let merged = MessagesObtainedHandler(messagesMap: self.messagesMap,
                                                      messages: messages,
                                                      acknowledgedJsonOnlyMessageIds: acknowledgementStatus.unchangedMessageIds,
                                                      readmittedJsonOnlyMessageIds: acknowledgementStatus.changedMessageIds).handle()
                self.messagesMap = merged.messagesMap
                self.messagesIdentityContext = identityContext
                processingRevision = self.messagesRevision
                self.persistEligibleJsonOnlyMessages(messagesMap: merged.messagesMap,
                                                     identityContext: identityContext)
                mergeResult = merged
            }
            guard committed,
                  let mergeResult = mergeResult,
                  let processingRevision = processingRevision else {
                result.resolve(with: true)
                return
            }

            self.processingQueue.async { [weak self] in
                guard let self = self else {
                    result.resolve(with: true)
                    return
                }
                let processingResult = appIsReady
                    ? self.processAndShowMessage(messagesMap: mergeResult.messagesMap,
                                                 identityContext: identityContext,
                                                 processingRevision: processingRevision)
                    : Fulfill<Bool, Error>(value: true)
                processingResult.onSuccess { [weak self] _ in
                    guard let self = self else {
                        result.resolve(with: true)
                        return
                    }
                    self.syncQueue.async {
                        guard self.identityCoordinator.performIfCurrent(identityContext,
                                                                        identityProvider: self.identityProvider, {
                            mergeResult.deliveredMessages.forEach {
                                self.requestHandler?.track(inAppDelivery: $0,
                                                           onSuccess: nil,
                                                           onFailure: nil)
                            }
                            self.finishSync(inboxChanged: mergeResult.inboxChanged)
                        }) else {
                            result.resolve(with: true)
                            return
                        }
                        result.resolve(with: true)
                    }
                }.onError { error in
                    result.reject(with: error)
                }
            }
        }

        return result
    }
    
    private func finishSync(inboxChanged: Bool) {
        ITBInfo()
        
        if inboxChanged {
            callbackQueue.async { [weak self] in
                self?.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        
        persister.persist(messagesMap.values)
        lastSyncTime = dateProvider.currentDate
    }
    
    private func getMessagesMap(fromMessagesProcessorResult messagesProcessorResult: MessagesProcessorResult) -> OrderedDictionary<String, IterableInAppMessage> {
        switch messagesProcessorResult {
        case let .noShow(message: _, messagesMap: messagesMap):
            return messagesMap
        case .show(message: _, messagesMap: let messagesMap):
            return messagesMap
        case .jsonOnly(message: _, messagesMap: let messagesMap):
            return messagesMap
        }
    }
    
    // Not a pure function.
    private func showMessage(fromMessagesProcessorResult messagesProcessorResult: MessagesProcessorResult) {
        if case let MessagesProcessorResult.show(message, _) = messagesProcessorResult {
            lastDisplayTime = dateProvider.currentDate
            ITBDebug("Setting last display time: \(String(describing: lastDisplayTime))")
            
            show(message: message, consume: !message.saveToInbox)
        }
    }
    
    private func processAndShowMessage(messagesMap: OrderedDictionary<String, IterableInAppMessage>,
                                       identityContext: UserIdentityContext,
                                       processingRevision: UInt64) -> Pending<Bool, Error> {
        var processor = MessagesProcessor(inAppDelegate: inAppDelegate,
                                          inAppDisplayChecker: self,
                                          messagesMap: messagesMap,
                                          currentDate: dateProvider.currentDate,
                                          isContextCurrent: { [weak self] in
                                              self?.canProcessMessages(identityContext: identityContext,
                                                                       processingRevision: processingRevision) ?? false
                                          })
        let messagesProcessorResult = processor.processMessages()
        let updatedMessagesMap = getMessagesMap(fromMessagesProcessorResult: messagesProcessorResult)
        var didCommit = false
        guard identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider, {
            guard processingRevision == self.messagesRevision else { return }
            self.messagesMap = updatedMessagesMap
            self.messagesIdentityContext = identityContext
            didCommit = true
        }), didCommit else {
            return Fulfill<Bool, Error>(value: true)
        }

        if case let .jsonOnly(message, _) = messagesProcessorResult {
            return deliverJsonOnlyMessage(message, consumeOnReplay: true, identityContext: identityContext).flatMap { [weak self] processed in
                guard let self = self,
                      processed || InAppManager.isExpired(message: message, currentDate: self.dateProvider.currentDate) else {
                    return Fulfill<Bool, Error>(value: true)
                }
                var nextMessagesMap = OrderedDictionary<String, IterableInAppMessage>()
                guard self.identityCoordinator.performIfCurrent(identityContext,
                                                                identityProvider: self.identityProvider, {
                    nextMessagesMap = self.messagesMap
                }) else {
                    return Fulfill<Bool, Error>(value: true)
                }
                return self.processAndShowMessage(messagesMap: nextMessagesMap,
                                                  identityContext: identityContext,
                                                  processingRevision: processingRevision)
            }
        }

        _ = identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider) {
            self.showMessage(fromMessagesProcessorResult: messagesProcessorResult)
        }
        return Fulfill<Bool, Error>(value: true)
    }

    private func canProcessMessages(identityContext: UserIdentityContext,
                                    processingRevision: UInt64) -> Bool {
        var canProcess = false
        guard identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider, {
            canProcess = processingRevision == self.messagesRevision
        }) else { return false }
        return canProcess
    }
    
    private func showInternal(message: IterableInAppMessage,
                              consume: Bool,
                              callback: ITBURLCallback? = nil) {
        ITBInfo()
        
        guard !message.isJsonOnly else {
            return
        }
        
        guard Thread.isMainThread else {
            ITBError("This must be called from the main thread")
            return
        }
        
        let onClickCallback: (URL) -> Void = { [weak self] url in
            ITBDebug("in-app clicked")
            
            // call the client callback, if present
            _ = callback?(url)
            
            // in addition perform action or url delegate task
            self?.handleClick(clickedUrl: url, forMessage: message, location: .inApp, inboxSessionId: nil)
            
            // set the dismiss time
            self?.lastDismissedTime = self?.dateProvider.currentDate
            ITBDebug("Setting last dismissed time: \(String(describing: self?.lastDismissedTime))")
            
            // check if we need to process more in-apps
            self?.scheduleNextInAppMessage()
            
            if consume {
                self?.requestHandler?.inAppConsume(message.messageId,
                                                   onSuccess: nil,
                                                   onFailure: nil)
            }
        }
        
        switch displayer.showInApp(message: message, onClickCallback: onClickCallback) {
        case let .notShown(reason):
            ITBError("Could not show message: \(reason)")
        case .shown:
            ITBDebug("in-app shown")
            
            set(read: true, forMessage: message)
            
            updateMessage(message, didProcessTrigger: true, consumed: consume)
        }
    }
    
    private func processExistingMessages() {
        _ = InAppManager.getAppIsReady(applicationStateProvider: applicationStateProvider, displayer: displayer).flatMap { [weak self] appIsActive in
            guard appIsActive, let self = self else {
                return Fulfill<Bool, Error>(value: true)
            }
            let identityContext = self.identityCoordinator.capture(identityProvider: self.identityProvider)
            var messagesMap = OrderedDictionary<String, IterableInAppMessage>()
            var processingRevision: UInt64 = 0
            guard self.identityCoordinator.performIfCurrent(identityContext, identityProvider: self.identityProvider, {
                messagesMap = self.messagesMap
                processingRevision = self.messagesRevision
                self.persistEligibleJsonOnlyMessages(messagesMap: messagesMap,
                                                     identityContext: identityContext)
            }) else {
                return Fulfill<Bool, Error>(value: true)
            }
            return self.processAndShowMessage(messagesMap: messagesMap,
                                              identityContext: identityContext,
                                              processingRevision: processingRevision).map { [weak self] _ in
                guard let self = self else { return true }
                _ = self.identityCoordinator.performIfCurrent(identityContext, identityProvider: self.identityProvider) {
                    self.persister.persist(self.messagesMap.values)
                }
                return true
            }
        }
    }
    
    // This method schedules next triggered message after showing a message
    private func scheduleNextInAppMessage() {
        ITBDebug()
        
        let waitTimeInterval = getInAppShowingWaitTimeInterval()
        
        if waitTimeInterval > 0 {
            ITBDebug("Need to wait for: \(waitTimeInterval)")
            scheduleQueue.asyncAfter(deadline: .now() + waitTimeInterval) { [weak self] in
                self?.scheduleNextInAppMessage()
            }
        } else {
            processExistingMessages()
        }
    }
    
    @discardableResult
    private func updateMessage(_ message: IterableInAppMessage,
                               read: Bool? = nil,
                               didProcessTrigger: Bool? = nil,
                               consumed: Bool? = nil) -> Pending<Bool, IterableError> {
        ITBDebug()
        
        let result = Fulfill<Bool, IterableError>()
        
        updateQueue.async { [weak self] in
            self?.updateMessageSync(message, read: read, didProcessTrigger: didProcessTrigger, consumed: consumed)
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
        InAppManager.getWaitTimeInterval(fromLastTime: lastDismissedTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval)
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
    
    private func handleIterableCustomAction(name: String, forMessage message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?) {
        guard let iterableCustomActionName = IterableCustomActionName(rawValue: name) else {
            return
        }
        
        switch iterableCustomActionName {
        case .delete:
            remove(message: message, location: location, source: .deleteButton, inboxSessionId: inboxSessionId)
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
        DispatchQueue.main.async { [weak self] in
            ActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self?.urlDelegate, inContext: context),
                                         customActionHandler: IterableUtil.customActionHandler(fromCustomActionDelegate: self?.customActionDelegate, inContext: context),
                                         urlOpener: self?.urlOpener,
                                         allowedProtocols: self?.allowedProtocols ?? [])
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

    private func persistEligibleJsonOnlyMessages(messagesMap: OrderedDictionary<String, IterableInAppMessage>,
                                                 identityContext: UserIdentityContext) {
        guard identityContext.identity != nil else { return }
        let messages = messagesMap.values.filter {
            $0.isJsonOnly && !$0.didProcessTrigger && !$0.consumed && !$0.read && $0.trigger.type == .immediate
        }
        guard !messages.isEmpty else { return }
        jsonOnlyMessageStore.enqueue(messages, identityContext: identityContext)
    }

    private func replayUnhandledJsonOnlyMessages() -> Pending<Bool, Error> {
        let identityContext = jsonOnlyMessageStore.identityContext
        guard applicationStateProvider.applicationState == .active,
              identityContext.identity != nil else {
            return Fulfill<Bool, Error>(value: true)
        }

        return jsonOnlyMessageStore.getMessages(identityContext: identityContext).reduce(Fulfill<Bool, Error>(value: true) as Pending<Bool, Error>) { pending, message in
            pending.flatMap { [weak self] _ in
                self?.deliverJsonOnlyMessage(message,
                                             consumeOnReplay: false,
                                             identityContext: identityContext) ?? Fulfill<Bool, Error>(value: true)
            }
        }
    }

    private func deliverJsonOnlyMessage(_ message: IterableInAppMessage,
                                        consumeOnReplay: Bool,
                                        identityContext: UserIdentityContext) -> Pending<Bool, Error> {
        let result = Fulfill<Bool, Error>()

        guard identityContext.identity != nil else {
            if consumeOnReplay {
                deliverJsonOnlyMessageWithoutAvailability(message, result: result)
            } else {
                result.resolve(with: false)
            }
            return result
        }

        guard jsonOnlyMessageStore.enqueue(message, identityContext: identityContext) else {
            result.resolve(with: false)
            return result
        }

        let deliver = { [weak self] in
            guard let self = self else {
                result.resolve(with: false)
                return
            }

            guard self.applicationStateProvider.applicationState == .active,
                  let delivery = self.jsonOnlyMessageStore.prepareDelivery(for: message,
                                                                            identityContext: identityContext) else {
                result.resolve(with: false)
                return
            }

            if delivery.isInitial {
                guard self.identityCoordinator.isCurrent(identityContext,
                                                         identityProvider: self.identityProvider) else {
                    result.resolve(with: false)
                    return
                }
                _ = self.inAppDelegate.onNew(message: delivery.message)
                guard self.identityCoordinator.isCurrent(identityContext,
                                                         identityProvider: self.identityProvider) else {
                    result.resolve(with: false)
                    return
                }
            }
            guard self.identityCoordinator.isCurrent(identityContext,
                                                     identityProvider: self.identityProvider) else {
                result.resolve(with: false)
                return
            }
            self.inAppDelegate.onJsonOnlyMessageAvailable?(message: delivery.message)
            guard self.identityCoordinator.isCurrent(identityContext,
                                                     identityProvider: self.identityProvider) else {
                result.resolve(with: false)
                return
            }
            self.notificationCenter.post(name: .iterableJsonOnlyInAppMessageAvailable,
                                         object: delivery.message,
                                         userInfo: nil)
            guard self.identityCoordinator.isCurrent(identityContext,
                                                     identityProvider: self.identityProvider) else {
                result.resolve(with: false)
                return
            }

            guard delivery.isInitial || consumeOnReplay else {
                result.resolve(with: true)
                return
            }

            self.updateQueue.async { [weak self] in
                guard let self = self,
                      self.identityCoordinator.performIfCurrent(identityContext,
                                                                identityProvider: self.identityProvider, {
                    self.updateMessageSync(message, didProcessTrigger: true, consumed: true)
                    self.requestHandler?.inAppConsume(message.messageId,
                                                      onSuccess: nil,
                                                      onFailure: nil)
                }) else {
                    result.resolve(with: false)
                    return
                }
                result.resolve(with: true)
            }
        }

        if Thread.isMainThread {
            deliver()
        } else {
            DispatchQueue.main.async(execute: deliver)
        }

        return result
    }

    private func deliverJsonOnlyMessageWithoutAvailability(_ message: IterableInAppMessage,
                                                           result: Fulfill<Bool, Error>) {
        let deliver = { [weak self] in
            guard let self = self else {
                result.resolve(with: false)
                return
            }

            _ = self.inAppDelegate.onNew(message: message)
            self.updateQueue.async { [weak self] in
                guard let self = self else {
                    result.resolve(with: false)
                    return
                }
                self.updateMessageSync(message, didProcessTrigger: true, consumed: true)
                self.requestHandler?.inAppConsume(message.messageId,
                                                  onSuccess: nil,
                                                  onFailure: nil)
                result.resolve(with: true)
            }
        }

        if Thread.isMainThread {
            deliver()
        } else {
            DispatchQueue.main.async(execute: deliver)
        }
    }
    
    // From client side
    private func removePrivate(message: IterableInAppMessage,
                               location: InAppLocation = .inApp,
                               source: InAppDeleteSource? = nil,
                               inboxSessionId: String? = nil,
                               successHandler: OnSuccessHandler? = nil,
                               failureHandler: OnFailureHandler? = nil) {
        ITBInfo()
        updateMessage(message, didProcessTrigger: true, consumed: true).onSuccess { [weak self] _ in
            guard message.saveToInbox else { return }
            self?.callbackQueue.async { [weak self] in
                self?.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
        requestHandler?.inAppConsume(message: message,
                                     location: location,
                                     source: source,
                                     inboxSessionId: inboxSessionId,
                                     onSuccess: successHandler,
                                     onFailure: failureHandler)
    }
    
    private static func isExpired(message: IterableInAppMessage, currentDate: Date) -> Bool {
        guard let expiresAt = message.expiresAt else {
            return false
        }
        
        return currentDate >= expiresAt
    }
    
    fileprivate static func isValid(message: IterableInAppMessage, currentDate: Date) -> Bool {
        message.consumed == false && isExpired(message: message, currentDate: currentDate) == false
    }
    
    fileprivate static func getAppIsReady(applicationStateProvider: ApplicationStateProviderProtocol,
                                          displayer: InAppDisplayerProtocol) -> Fulfill<Bool, Error> {
        if Thread.isMainThread {
            let ready = (applicationStateProvider.applicationState == .active) && (displayer.isShowingInApp() == false)
            return Fulfill(value: ready)
        } else {
            let result = Fulfill<Bool, Error>()
            
            DispatchQueue.main.async {
                let ready = (applicationStateProvider.applicationState == .active) && (displayer.isShowingInApp() == false)
                result.resolve(with: ready)
            }
            
            return result
        }
    }
    
    private weak var requestHandler: RequestHandlerProtocol?
    private let deviceMetadata: DeviceMetadata
    private let fetcher: InAppFetcherProtocol
    private let displayer: InAppDisplayerProtocol
    private let inAppDelegate: IterableInAppDelegate
    private let inAppDisplayDelegate: IterableInAppDisplayDelegate?
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    private let allowedProtocols: [String]
    private let applicationStateProvider: ApplicationStateProviderProtocol
    private let notificationCenter: NotificationCenterProtocol
    
    private let persister: InAppPersistenceProtocol
    private let jsonOnlyMessageStore: JsonOnlyMessageStore
    private let identityCoordinator: IdentityCoordinator
    private let identityProvider: () -> UserIdentitySnapshot?
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>()
    private var messagesIdentityContext: UserIdentityContext?
    private var messagesRevision: UInt64 = 0
    private let dateProvider: DateProviderProtocol
    private var lastDismissedTime: Date?
    private var lastDisplayTime: Date?
    
    private let updateQueue = DispatchQueue(label: "UpdateQueue")
    private let scheduleQueue = DispatchQueue(label: "ScheduleQueue")
    private let callbackQueue = DispatchQueue(label: "CallbackQueue")
    private let syncQueue = DispatchQueue(label: "SyncQueue")
    private let processingQueue = DispatchQueue(label: "InAppProcessingQueue")
    
    private var syncResult: Pending<Bool, Error>?
    private var lastSyncTime: Date?
    private var moveToForegroundSyncInterval: Double = 1.0 * 60.0 // don't sync within sixty seconds
    private var autoDisplayPaused = false
}

extension InAppManager: InAppNotifiable {
    func scheduleSync() -> Pending<Bool, Error> {
        ITBInfo()
        
        return InAppManager.getAppIsReady(applicationStateProvider: applicationStateProvider,
                                          displayer: displayer)
            .flatMap { self.scheduleSync(appIsReady: $0) }
    }
    
    private func scheduleSync(appIsReady: Bool) -> Pending<Bool, Error> {
        ITBInfo()
        
        let result = Fulfill<Bool, Error>()
        
        syncQueue.async { [weak self] in
            if let syncResult = self?.syncResult {
                if syncResult.isResolved() {
                    self?.syncResult = self?.synchronize(appIsReady: appIsReady)
                } else {
                    self?.syncResult = syncResult.flatMap { _ in self?.synchronize(appIsReady: appIsReady) ?? Fulfill<Bool, Error>(value: true) }
                }
            } else {
                self?.syncResult = self?.synchronize(appIsReady: appIsReady)
            }
            self?.syncResult?.onSuccess { success in
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
        
        updateQueue.async { [weak self] in
            guard let self = self, let message = self.messagesMap[messageId] else { return }
            self.messagesMap.removeValue(forKey: messageId)
            self.persister.persist(self.messagesMap.values)
            guard message.saveToInbox else { return }
            self.callbackQueue.async { [weak self] in
                self?.notificationCenter.post(name: .iterableInboxChanged, object: self, userInfo: nil)
            }
        }
    }
    
    func reset() -> Pending<Bool, Error> {
        ITBInfo()
        
        let result = Fulfill<Bool, Error>()
        
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.identityCoordinator.withCriticalSection {
                let identityContext = self.identityCoordinator.capture(identityProvider: self.identityProvider)
                self.messagesRevision &+= 1
                self.messagesMap.reset()
                self.messagesIdentityContext = identityContext
                self.persister.persist(self.messagesMap.values)
            }
            
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
        // Check delegate first if available, otherwise fall back to isAutoDisplayPaused property
        let autoDisplayPaused = inAppDisplayDelegate?.isAutoDisplayPaused?(for: message) ?? isAutoDisplayPaused
        
        guard !autoDisplayPaused else {
            ITBInfo("automatic in-app display has been paused")
            return false
        }
        
        guard !message.didProcessTrigger else {
            ITBInfo("message with id: \(message.messageId) is already processed")
            return false
        }
        
        guard InAppManager.getWaitTimeInterval(fromLastTime: lastDismissedTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval) <= 0 else {
            ITBInfo("can't display within configured In-App display interval window")
            return false
        }
        
        guard InAppManager.getWaitTimeInterval(fromLastTime: lastDisplayTime, currentTime: dateProvider.currentDate, gap: moveToForegroundSyncInterval) <= 0 else {
            ITBInfo("can't display within configured In-App display window")
            return false
        }
        
        return true
    }
}
