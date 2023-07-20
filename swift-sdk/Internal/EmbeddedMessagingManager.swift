//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation
import UIKit

public struct ResolvedMessage {
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
}

class EmbeddedMessagingManager: NSObject, IterableEmbeddedMessagingManagerProtocol {
    init(apiClient: ApiClientProtocol) {
        ITBInfo()
        
        self.apiClient = apiClient
        super.init()
    }
    
    deinit {
        ITBInfo()
    }
    
    public func getMessages() -> [IterableEmbeddedMessage] {
        ITBInfo()
        
        return messages
    }
    
    public func resolveMessages(_ messages: [IterableEmbeddedMessage], completion: @escaping ([ResolvedMessage]) -> Void) {
        var resolvedMessages: [ResolvedMessage] = []

        let group = DispatchGroup()

        for message in messages {
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
                            resolvedMessages.append(resolvedMessage)
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
                        resolvedMessages.append(resolvedMessage)
                        group.leave()
                    }
                }
            }

        }

        group.notify(queue: .main) {
            completion(resolvedMessages)
        }
    }
    
    public func addUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
        listeners.add(listener)
    }
    
    public func removeUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate) {
        listeners.remove(listener)
    }

    public func syncMessages(completion: @escaping () -> Void) {
        retrieveEmbeddedMessages(completion: completion)
    }

    // MARK: - PRIVATE/INTERNAL
    
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
                    let fetchedMessages = embeddedMessagesPayload.embeddedMessages
                    
                    // TODO: decide if parsing errors should be accounted for here
                    
                    let processor = EmbeddedMessagingProcessor(currentMessages: self.messages,
                                                               fetchedMessages: fetchedMessages)
                    
                    self.setMessages(processor)
                    self.trackNewlyRetrieved(processor)
                    self.notifyUpdateDelegates(processor)
                    completion()
                },
                
                receiveError: { sendRequestError in
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
            listener.onInvalidApiKeyOrSyncStop()
        }
    }
    private var apiClient: ApiClientProtocol
    
    private var messages: [IterableEmbeddedMessage] = []
    
    private var listeners: NSHashTable<IterableEmbeddedMessagingUpdateDelegate> = NSHashTable(options: [.weakMemory])
}
