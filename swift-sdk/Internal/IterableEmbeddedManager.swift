//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UIKit

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
    }
    
    var onDeinit: (() -> Void)?
    deinit {
        ITBInfo()
        removeForegroundObservers()
        onDeinit?()
    }
    
    public func getMessages() -> [IterableEmbeddedMessage] {
        ITBInfo()
        
        return messages
    }
    
    public func getMessages(for placementId: Int) -> [IterableEmbeddedMessage] {

        return messages.filter { $0.metadata.placementId == placementId }
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
    
    public func handleEmbeddedClick(message: IterableEmbeddedMessage?, buttonIdentifier: String?, clickedUrl: String) {
        print("called embeddedMessageClicked IterableEmbeddedManager method.")
        guard let message = message else {
            print("Error: message is nil.")
            return
        }
        
        // Step 1: Handle the clicked URL
        if let url = URL(string: clickedUrl) {
            handleClick(clickedUrl: url, forMessage: message)
        } else {
            print("Invalid URL: \(clickedUrl)")
        }
        
//        for listener in listeners.allObjects {
//            listener.onTapAction(action: action)
//        }
    }
    
    private func handleClick(clickedUrl url: URL?, forMessage message: IterableEmbeddedMessage) {
        guard let theUrl = url, let embeddedClickedUrl = EmbeddedHelper.parse(embeddedUrl: theUrl) else {
            ITBError("Could not parse url: \(url?.absoluteString ?? "nil")")
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
                handleUrlOrAction(urlOrAction: theUrl.absoluteString)
        }
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
    
    private func createAction(fromUrlOrAction urlOrAction: String) -> IterableAction? {
        if let parsedUrl = URL(string: urlOrAction), let _ = parsedUrl.scheme {
            return IterableAction.actionOpenUrl(fromUrlString: urlOrAction)
        } else {
            return IterableAction.action(fromDictionary: ["type": urlOrAction])
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
    private var messages: [IterableEmbeddedMessage] = []
    private var listeners: NSHashTable<IterableEmbeddedUpdateDelegate> = NSHashTable(options: [.weakMemory])
    
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
                                let fetchedMessages = placements.flatMap { $0.embeddedMessages }
                                
                                // TODO: decide if parsing errors should be accounted for here
                                
                                let processor = EmbeddedMessagingProcessor(currentMessages: self.messages,
                                                                           fetchedMessages: fetchedMessages)
                                
                                self.setMessages(processor)
                                self.trackNewlyRetrieved(processor)
                                self.notifyUpdateDelegates(processor)
                                completion()
                            },
                
                receiveError: { sendRequestError in
                    print("receive error: \(sendRequestError)")
                    //TODO: This check can go away once eligibility based retrieval comes in place.
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
    }
    
    private func trackNewlyRetrieved(_ processor: EmbeddedMessagingProcessor) {
        for message in processor.newlyRetrievedMessages() {
            IterableAPI.track(embeddedMessageReceived: message)
        }
    }
    
    private func notifyUpdateDelegates(_ processor: EmbeddedMessagingProcessor) {
        // TODO: filter `messages` by `placementId` and notify objects in `listeners` that have that placement ID
        
//        let placementIdsToUpdate = processor.placementIdsToNotify()
        
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
