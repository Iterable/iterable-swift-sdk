//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UIKit

public struct ResolvedMessage: Equatable {
    public let title: String?
    public let description: String?
    public var image: UIImage?
    public let buttonText: String?
    public let buttonTwoText: String?
    public let message: IterableEmbeddedMessage

    init(title: String?,
         description: String?,
         image: UIImage?,
         buttonText: String?,
         buttonTwoText: String?,
         message: IterableEmbeddedMessage) {
        self.title = title
        self.description = description
        self.image = image
        self.buttonText = buttonText
        self.buttonTwoText = buttonTwoText
        self.message = message
    }
    
    public static func ==(lhs: ResolvedMessage, rhs: ResolvedMessage) -> Bool {
            return lhs.title == rhs.title &&
                   lhs.description == rhs.description &&
                   lhs.image == rhs.image &&
                   lhs.buttonText == rhs.buttonText &&
                   lhs.buttonTwoText == rhs.buttonTwoText &&
                   lhs.message == rhs.message
        }
}

class IterableEmbeddedManager: NSObject, IterableEmbeddedManagerProtocol {
    init(apiClient: ApiClientProtocol,
         urlDelegate: IterableURLDelegate?,
         customActionDelegate: IterableCustomActionDelegate?,
         urlOpener: UrlOpenerProtocol,
         allowedProtocols: [String]) {
         ITBInfo()
        
        self.apiClient = apiClient
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
        self.allowedProtocols = allowedProtocols
        
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
        return Array(messages.values.flatMap { $0 })
    }
    
    public func getMessages(for placementId: Int) -> [IterableEmbeddedMessage] {
        return messages[placementId] ?? []
    }
    
    public func resolveMessages(_ messages: [IterableEmbeddedMessage], completion: @escaping ([ResolvedMessage]) -> Void) {
        var resolvedMessages: [Int: ResolvedMessage] = [:]

        let group = DispatchGroup()

        for (index, message) in messages.enumerated() {
            group.enter()

            let title = message.elements?.title
            let description = message.elements?.body
            let imageUrl = message.elements?.mediaUrl
            let buttonText = message.elements?.buttons?.first?.title
            let buttonTwoText = message.elements?.buttons?.count ?? 0 > 1 ? message.elements?.buttons?[1].title : nil

            DispatchQueue.global().async {
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    var request = URLRequest(url: url)
                    request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

                    let config = URLSessionConfiguration.default
                    config.httpAdditionalHeaders = request.allHTTPHeaderFields

                    let session = URLSession(configuration: config)
                    
                    session.dataTask(with: request) { (data, _, _) in
                        defer { group.leave() }

                        guard let imageData = data else {
                            print("Unable to load image data")
                            return
                        }

                        let resolvedMessage = ResolvedMessage(title: title,
                                                              description: description,
                                                              image: UIImage(data: imageData),
                                                              buttonText: buttonText,
                                                              buttonTwoText: buttonTwoText,
                                                              message: message)

                        DispatchQueue.main.async {
                            resolvedMessages[index] = resolvedMessage
                        }

                    }.resume()
                } else {
                    let resolvedMessage = ResolvedMessage(title: title,
                                                          description: description,
                                                          image: nil,
                                                          buttonText: buttonText,
                                                          buttonTwoText: buttonTwoText,
                                                          message: message)
                    DispatchQueue.main.async {
                        resolvedMessages[index] = resolvedMessage
                        group.leave()
                    }
                }
            }

        }

        group.notify(queue: .main) {
            let sortedResolvedMessages = resolvedMessages.sorted { $0.key < $1.key }.map { $0.value }
            completion(sortedResolvedMessages)
        }
    }
    
    public func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        listeners.add(listener)
    }
    
    public func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate) {
        listeners.remove(listener)
    }

    public func syncMessages(completion: @escaping () -> Void) {
        retrieveEmbeddedMessages(completion: completion)
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
    private var listeners: NSHashTable<IterableEmbeddedUpdateDelegate> = NSHashTable(options: [.weakMemory])
    private var trackedMessageIds: Set<String> = Set()
    
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
                receiveValue: { embeddedMessagesPayload in
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
                receiveError: { sendRequestError in
                    print("receive error: \(sendRequestError)")
                    
                    if sendRequestError.reason == "SUBSCRIPTION_INACTIVE" ||
                        sendRequestError.reason == "Invalid API Key" {
                        self.notifyDelegatesOfInvalidApiKeyOrSyncStop()
                        ITBInfo("Subscription inactive. Stopping embedded message sync")
                    } else {
                        ITBError()
                    }
                    completion()
                }
            )
    }
    
    private func setMessages(_ processor: EmbeddedMessagingProcessor) {
        messages = processor.processedMessagesList()
        cleanUpTrackedMessageIds(messages)
    }
    
    private func cleanUpTrackedMessageIds(_ currentMessages: [Int: [IterableEmbeddedMessage]]) {
        let currentUniqueKeys = Set(currentMessages.flatMap { placement, messages in
            messages.map { "\(placement)-\($0.metadata.messageId)" }
        })
        trackedMessageIds = trackedMessageIds.intersection(currentUniqueKeys)
    }

    private func trackNewlyRetrieved(_ processor: EmbeddedMessagingProcessor) {
        for (placementId, messages) in processor.newlyRetrievedMessages() {
            for message in messages {
                let messageId = message.metadata.messageId
                let uniqueKey = "\(placementId)-\(messageId)"
                
                if !trackedMessageIds.contains(uniqueKey) {
                    IterableAPI.track(embeddedMessageReceived: message)
                    trackedMessageIds.insert(uniqueKey)
                }
            }
        }
    }
    
    private func notifyUpdateDelegates(_ processor: EmbeddedMessagingProcessor) {
        if (processor.newlyRemovedMessageIds().count > 0 || processor.newlyRetrievedMessages().count > 0) {
            for listener in listeners.allObjects {
                listener.onMessagesUpdated()
            }
        }
    }
    
    private func notifyDelegatesOfInvalidApiKeyOrSyncStop() {
        for listener in listeners.allObjects {
            listener.onEmbeddedMessagingDisabled()
        }
    }
}
