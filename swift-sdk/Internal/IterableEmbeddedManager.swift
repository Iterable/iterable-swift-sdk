//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UIKit

protocol IterableInternalEmbeddedManagerProtocol: IterableEmbeddedManagerProtocol, EmbeddedNotifiable {
    // we can add the internal delegate methods here
}

class IterableEmbeddedManager: NSObject, IterableInternalEmbeddedManagerProtocol {
    init(apiClient: ApiClientProtocol,
         urlDelegate: IterableURLDelegate?,
         customActionDelegate: IterableCustomActionDelegate?,
         urlOpener: UrlOpenerProtocol,
         allowedProtocols: [String],
         enableEmbeddedMessaging: Bool) {
         ITBInfo()
        
        self.apiClient = apiClient
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
        self.allowedProtocols = allowedProtocols
        self.enableEmbeddedMessaging = enableEmbeddedMessaging
        
        super.init()
        addForegroundObservers()
        syncMessages { print("Retrieving embedded message")}
    }
    
    var onDeinit: (() -> Void)?
    deinit {
        ITBInfo()
        removeForegroundObservers()
        onDeinit?()
    }
    
    public func getMessages() -> [IterableEmbeddedMessage] {
        var result: [IterableEmbeddedMessage] = []
        messageProcessingQueue.sync {
            result = Array(messages.values.flatMap { $0 })
        }
        return result
    }
    
    public func getMessages(for placementId: Int) -> [IterableEmbeddedMessage] {
        var result: [IterableEmbeddedMessage] = []
        messageProcessingQueue.sync {
            result = messages[placementId] ?? []
        }
        return result
    }
    
    public func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        listeners.add(listener)
    }
    
    public func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        listeners.remove(listener)
    }
    
    public func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {
        if let url = URL(string: clickedUrl) {
            handleClick(clickedUrl: url, forMessage: message)
        } else {
            print("Invalid URL: \(clickedUrl)")
        }
    }
    
    public func handleClick(clickedUrl: URL?, forMessage message: IterableEmbeddedMessage) {
        guard let url = clickedUrl, let embeddedClickedUrl = EmbeddedHelper.parse(embeddedUrl: url) else {
            ITBError("Could not parse url: \(clickedUrl?.absoluteString ?? "nil")")
            return
        }
        
        switch embeddedClickedUrl {
        case let .iterableCustomAction(name: iterableCustomActionName):
            handleIterableCustomAction(name: iterableCustomActionName, forMessage: message)
        case let .customAction(name: customActionName):
            handleUrlOrAction(urlOrAction: customActionName)
        case let .localResource(name: localResourceName):
            handleUrlOrAction(urlOrAction: localResourceName)
        case .regularUrl:
            handleUrlOrAction(urlOrAction: url.absoluteString)
        }
    }
    
    public func reset() {
        let processor = EmbeddedMessagingProcessor(currentMessages: self.messages, fetchedMessages: [:])
        self.setMessages(processor)
        self.notifyUpdateDelegates(processor)
    }
    
    private func handleIterableCustomAction(name: String, forMessage message: IterableEmbeddedMessage) {
        guard let iterableCustomActionName = IterableCustomActionName(rawValue: name) else {
            return
        }
        print("iterable custom action name: \(iterableCustomActionName) on embeddedMessage: \(message)")
        switch iterableCustomActionName {
            case .delete:
                break;
            case .dismiss:
                break
        }
    }
    
    private func createAction(fromUrlOrAction url: String) -> IterableAction? {
        if let parsedUrl = URL(string: url), let _ = parsedUrl.scheme {
            return IterableAction.actionOpenUrl(fromUrlString: url)
        } else {
            return IterableAction.action(fromDictionary: ["type": url])
        }
    }
    
    private func handleUrlOrAction(urlOrAction: String) {
        guard let action = createAction(fromUrlOrAction: urlOrAction) else {
            ITBError("Could not create action from: \(urlOrAction)")
            return
        }

        let context = IterableActionContext(action: action, source: .embedded)
        DispatchQueue.main.async { [weak self] in
            ActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self?.urlDelegate, inContext: context),
                                         customActionHandler: IterableUtil.customActionHandler(fromCustomActionDelegate: self?.customActionDelegate, inContext: context),
                                         urlOpener: self?.urlOpener,
                                         allowedProtocols: self?.allowedProtocols ?? [])
        }
    }

    // MARK: - PRIVATE/INTERNAL
    private var apiClient: ApiClientProtocol
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    private let allowedProtocols: [String]
    private var messages: [Int: [IterableEmbeddedMessage]] = [:]
    private let messageProcessingQueue = DispatchQueue(label: "com.iterable.embedded.messages", qos: .userInitiated)
    private var listeners: NSHashTable<IterableEmbeddedUpdateDelegate> = NSHashTable(options: [.weakMemory])
    private var trackedMessageIds: Set<String> = Set()
    private var enableEmbeddedMessaging: Bool
    
    private func addForegroundObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onAppDidBecomeActiveNotification(notification:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func removeForegroundObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    @objc private func onAppDidBecomeActiveNotification(notification: Notification) {
        ITBInfo()
        syncMessages { }
    }
    
    private func retrieveEmbeddedMessages(completion: @escaping () -> Void) {
        apiClient.getEmbeddedMessages()
            .onCompletion(
                receiveValue: { [weak self] embeddedMessagesPayload in
                    guard let self = self else {
                        completion()
                        return
                    }
                    
                    let placements = embeddedMessagesPayload.placements
                    
                    var fetchedMessagesDict: [Int: [IterableEmbeddedMessage]] = [:]
                    for placement in placements {
                        fetchedMessagesDict[placement.placementId!] = placement.embeddedMessages
                    }
                    
                    let processor = EmbeddedMessagingProcessor(currentMessages: self.messages,
                                                               fetchedMessages: fetchedMessagesDict)
                    
                    self.setMessages(processor)
                    self.trackNewlyRetrieved(processor)
                    self.notifyUpdateDelegates(processor)
                    completion()
                },
                receiveError: { [weak self] sendRequestError in
                    ITBDebug("receive error: \(sendRequestError)")
                    
                    if sendRequestError.reason == "SUBSCRIPTION_INACTIVE" ||
                        sendRequestError.reason == "Invalid API Key" {
                        self?.notifyDelegatesOfInvalidApiKeyOrSyncStop()
                        ITBInfo("Subscription inactive. Stopping embedded message sync")
                    } else {
                        ITBError("Embedded messages sync failed: \(sendRequestError.reason ?? "unknown")")
                    }
                    completion()
                }
            )
    }
    
    private func setMessages(_ processor: EmbeddedMessagingProcessor) {
        messageProcessingQueue.sync {
            messages = processor.processedMessagesList()
            let currentUniqueKeys = Set(messages.flatMap { placement, messages in
                messages.map { "\(placement)-\($0.metadata.messageId)" }
            })
            trackedMessageIds = trackedMessageIds.intersection(currentUniqueKeys)
        }
    }
    
    private func cleanUpTrackedMessageIds(_ currentMessages: [Int: [IterableEmbeddedMessage]]) {
        let currentUniqueKeys = Set(currentMessages.flatMap { placement, messages in
            messages.map { "\(placement)-\($0.metadata.messageId)" }
        })
        messageProcessingQueue.sync {
            trackedMessageIds = trackedMessageIds.intersection(currentUniqueKeys)
        }
    }

    private func trackNewlyRetrieved(_ processor: EmbeddedMessagingProcessor) {
        for (placementId, messages) in processor.newlyRetrievedMessages() {
            for message in messages {
                let messageId = message.metadata.messageId
                let uniqueKey = "\(placementId)-\(messageId)"
                
                messageProcessingQueue.sync {
                    if !trackedMessageIds.contains(uniqueKey) {
                        IterableAPI.track(embeddedMessageReceived: message)
                        trackedMessageIds.insert(uniqueKey)
                    }
                }
            }
        }
    }
    
    private func notifyUpdateDelegates(_ processor: EmbeddedMessagingProcessor) {
        for listener in listeners.allObjects {
            listener.onMessagesUpdated()
        }
    }
    
    private func notifyDelegatesOfInvalidApiKeyOrSyncStop() {
        for listener in listeners.allObjects {
            listener.onEmbeddedMessagingDisabled()
        }
    }
}

extension IterableEmbeddedManager: EmbeddedNotifiable {
    // MARK: - Constants
    
    private static let syncIdentifier = "embeddedMessagesSync"
    
    /// Creates a SendRequestError for when embedded messaging is not enabled
    /// Using SDK's established pattern for structured error responses
    private static func createNotEnabledError() -> SendRequestError {
        SendRequestError(reason: "Embedded messaging is not enabled",
                         data: nil,
                         httpStatusCode: nil,
                         iterableCode: "EmbeddedMessagingNotEnabled",
                         originalError: nil)
    }
    
    // MARK: - Default Handlers (following RequestProcessorUtil pattern)
    
    private static func defaultOnSuccess(_ identifier: String) -> OnSuccessHandler {
        { data in
            if let data = data {
                ITBInfo("\(identifier) succeeded, got response: \(data)")
            } else {
                ITBInfo("\(identifier) succeeded.")
            }
        }
    }
    
    private static func defaultOnFailure(_ identifier: String) -> OnFailureHandler {
        { reason, data in
            var toLog = "\(identifier) failed:"
            if let reason = reason {
                toLog += ", \(reason)"
            }
            if let data = data {
                toLog += ", got response \(String(data: data, encoding: .utf8) ?? "nil")"
            }
            ITBError(toLog)
        }
    }
    
    private static func defaultOnDetailedFailure(_ identifier: String) -> EmbeddedSyncErrorHandler {
        { error in
            var toLog = "\(identifier) failed:"
            if let reason = error.reason {
                toLog += ", \(reason)"
            }
            if let httpStatusCode = error.httpStatusCode {
                toLog += ", httpStatus: \(httpStatusCode)"
            }
            if let iterableCode = error.iterableCode {
                toLog += ", iterableCode: \(iterableCode)"
            }
            if let data = error.data {
                toLog += ", got response \(String(data: data, encoding: .utf8) ?? "nil")"
            }
            ITBError(toLog)
        }
    }
    
    // MARK: - Callback Helpers
    
    private func reportSuccess(responseDict: [AnyHashable: Any], onSuccess: OnSuccessHandler?) {
        if let onSuccess = onSuccess {
            onSuccess(responseDict)
        } else {
            Self.defaultOnSuccess(Self.syncIdentifier)(responseDict)
        }
    }
    
    private func reportFailure(error: SendRequestError, onFailure: OnFailureHandler?) {
        if let onFailure = onFailure {
            onFailure(error.reason, error.data)
        } else {
            Self.defaultOnFailure(Self.syncIdentifier)(error.reason, error.data)
        }
    }
    
    private func reportDetailedFailure(error: SendRequestError, onFailure: EmbeddedSyncErrorHandler?) {
        if let onFailure = onFailure {
            onFailure(error)
        } else {
            Self.defaultOnDetailedFailure(Self.syncIdentifier)(error)
        }
    }
    
    // MARK: - Sync Methods
    
    public func syncMessages(completion: @escaping () -> Void) {
        if (enableEmbeddedMessaging) {
            retrieveEmbeddedMessages(completion: completion)
        }
    }
    
    public func syncMessages(onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        guard enableEmbeddedMessaging else {
            let error = Self.createNotEnabledError()
            // Dispatch async for consistent callback timing
            // Note: Don't use weak self here - we need to call the callback even if self is deallocated
            DispatchQueue.main.async {
                if let onFailure = onFailure {
                    onFailure(error.reason, error.data)
                } else {
                    Self.defaultOnFailure(Self.syncIdentifier)(error.reason, error.data)
                }
            }
            return
        }
        
        apiClient.getEmbeddedMessages()
            .onCompletion(
                receiveValue: { [weak self] payload in
                    // Issue 1: Still call callback even if self is deallocated
                    guard let self = self else {
                        // Can't process payload without self, but notify caller
                        if let onSuccess = onSuccess {
                            onSuccess([:])
                        } else {
                            Self.defaultOnSuccess(Self.syncIdentifier)([:])
                        }
                        return
                    }
                    let (processor, responseDict) = self.processPayload(payload)
                    self.setMessages(processor)
                    self.trackNewlyRetrieved(processor)
                    self.notifyUpdateDelegates(processor)
                    self.reportSuccess(responseDict: responseDict, onSuccess: onSuccess)
                },
                receiveError: { [weak self] error in
                    if error.reason == "SUBSCRIPTION_INACTIVE" || error.reason == "Invalid API Key" {
                        self?.notifyDelegatesOfInvalidApiKeyOrSyncStop()
                    }
                    // Issue 1: Call callback even if self is deallocated
                    if let self = self {
                        self.reportFailure(error: error, onFailure: onFailure)
                    } else {
                        if let onFailure = onFailure {
                            onFailure(error.reason, error.data)
                        } else {
                            Self.defaultOnFailure(Self.syncIdentifier)(error.reason, error.data)
                        }
                    }
                }
            )
    }
    
    public func syncMessagesWithCallback(onSuccess: OnSuccessHandler?, onFailure: EmbeddedSyncErrorHandler?) {
        guard enableEmbeddedMessaging else {
            let error = Self.createNotEnabledError()
            // Dispatch async for consistent callback timing
            // Note: Don't use weak self here - we need to call the callback even if self is deallocated
            DispatchQueue.main.async {
                if let onFailure = onFailure {
                    onFailure(error)
                } else {
                    Self.defaultOnDetailedFailure(Self.syncIdentifier)(error)
                }
            }
            return
        }
        
        apiClient.getEmbeddedMessages()
            .onCompletion(
                receiveValue: { [weak self] payload in
                    // Issue 1: Still call callback even if self is deallocated
                    guard let self = self else {
                        // Can't process payload without self, but notify caller
                        if let onSuccess = onSuccess {
                            onSuccess([:])
                        } else {
                            Self.defaultOnSuccess(Self.syncIdentifier)([:])
                        }
                        return
                    }
                    let (processor, responseDict) = self.processPayload(payload)
                    self.setMessages(processor)
                    self.trackNewlyRetrieved(processor)
                    self.notifyUpdateDelegates(processor)
                    self.reportSuccess(responseDict: responseDict, onSuccess: onSuccess)
                },
                receiveError: { [weak self] error in
                    if error.reason == "SUBSCRIPTION_INACTIVE" || error.reason == "Invalid API Key" {
                        self?.notifyDelegatesOfInvalidApiKeyOrSyncStop()
                    }
                    // Issue 1: Call callback even if self is deallocated
                    if let self = self {
                        self.reportDetailedFailure(error: error, onFailure: onFailure)
                    } else {
                        if let onFailure = onFailure {
                            onFailure(error)
                        } else {
                            Self.defaultOnDetailedFailure(Self.syncIdentifier)(error)
                        }
                    }
                }
            )
    }
    
    // MARK: - Private Helpers
    
    /// Processes the embedded messages payload and returns the processor along with a response dictionary
    /// Following SDK pattern of returning [AnyHashable: Any] for success callbacks
    private func processPayload(_ payload: PlacementsPayload) -> (EmbeddedMessagingProcessor, [AnyHashable: Any]) {
        var dict: [Int: [IterableEmbeddedMessage]] = [:]
        var totalMessageCount = 0
        
        for placement in payload.placements {
            let placementMessages = placement.embeddedMessages ?? []
            dict[placement.placementId!] = placementMessages
            totalMessageCount += placementMessages.count
        }
        
        let processor = EmbeddedMessagingProcessor(currentMessages: self.messages, fetchedMessages: dict)
        
        // Build response dictionary following SDK conventions
        let responseDict: [AnyHashable: Any] = [
            "placementCount": payload.placements.count,
            "messageCount": totalMessageCount
        ]
        
        return (processor, responseDict)
    }
}
