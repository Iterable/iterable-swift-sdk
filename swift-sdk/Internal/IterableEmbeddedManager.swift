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
         urlOpener: UrlOpenerProtocol,
         allowedProtocols: [String]) {
         ITBInfo()
        
        self.apiClient = apiClient
        self.urlDelegate = urlDelegate
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
    
    public func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String) {

        if let url = URL(string: clickedUrl) {
            handleUrl(url: url.absoluteString)
        } else {
            print("Invalid URL: \(clickedUrl)")
        }
    }
    
    public func reset() {
        let processor = EmbeddedMessagingProcessor(currentMessages: self.messages, fetchedMessages: [])
        self.setMessages(processor)
        self.notifyUpdateDelegates(processor)
    }
    
    private func createAction(fromUrlOrAction url: String) -> IterableAction? {
        if let parsedUrl = URL(string: url), let _ = parsedUrl.scheme {
            return IterableAction.actionOpenUrl(fromUrlString: url)
        } else {
            return IterableAction.action(fromDictionary: ["type": url])
        }
    }
    
    private func handleUrl(url: String) {
        guard let action = createAction(fromUrlOrAction: url) else {
            ITBError("Could not create action from: \(url)")
            return
        }

        let context = IterableActionContext(action: action, source: .embedded)
        DispatchQueue.main.async { [weak self] in
            ActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: IterableUtil.urlHandler(fromUrlDelegate: self?.urlDelegate, inContext: context),
                                         urlOpener: self?.urlOpener,
                                         allowedProtocols: self?.allowedProtocols ?? [])
        }
    }

    // MARK: - PRIVATE/INTERNAL
    private var apiClient: ApiClientProtocol
    private let urlDelegate: IterableURLDelegate?
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

extension IterableEmbeddedManager: EmbeddedNotifiable {
    public func syncMessages(completion: @escaping () -> Void) {
        retrieveEmbeddedMessages(completion: completion)
    }
}
