//
//  Created by Tapash Majumder on 8/24/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

protocol RequestProcessorStrategy {
    var chooseOfflineProcessor: Bool { get }
}

struct DefaultRequestProcessorStrategy: RequestProcessorStrategy {
    let selectOffline: Bool
    
    var chooseOfflineProcessor: Bool {
        selectOffline
    }
}

@available(iOS 10.0, *)
class RequestHandler: RequestHandlerProtocol {
    init(onlineCreator: @escaping () -> OnlineRequestProcessor,
         offlineCreator: @escaping () -> OfflineRequestProcessor?,
         strategy: RequestProcessorStrategy = DefaultRequestProcessorStrategy(selectOffline: false)) {
        ITBInfo()
        self.onlineCreator = onlineCreator
        self.offlineCreator = offlineCreator
        self.strategy = strategy
    }
    
    deinit {
        ITBInfo()
    }
    
    func start() {
        ITBInfo()
        if strategy.chooseOfflineProcessor {
            offlineProcessor?.start()
        }
    }
    
    func stop() {
        ITBInfo()
        if strategy.chooseOfflineProcessor {
            offlineProcessor?.stop()
        }
    }
    
    @discardableResult
    func register(registerTokenInfo: RegisterTokenInfo,
                  notificationStateProvider: NotificationStateProviderProtocol,
                  onSuccess: OnSuccessHandler?,
                  onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        onlineProcessor.register(registerTokenInfo: registerTokenInfo,
                                 notificationStateProvider: notificationStateProvider,
                                 onSuccess: onSuccess,
                                 onFailure: onFailure)
    }
    
    @discardableResult
    func disableDeviceForCurrentUser(hexToken: String,
                                     withOnSuccess onSuccess: OnSuccessHandler?,
                                     onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        onlineProcessor.disableDeviceForCurrentUser(hexToken: hexToken,
                                                    withOnSuccess: onSuccess,
                                                    onFailure: onFailure)
    }
    
    @discardableResult
    func disableDeviceForAllUsers(hexToken: String,
                                  withOnSuccess onSuccess: OnSuccessHandler?,
                                  onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        onlineProcessor.disableDeviceForAllUsers(hexToken: hexToken,
                                                 withOnSuccess: onSuccess,
                                                 onFailure: onFailure)
    }
    
    @discardableResult
    func updateUser(_ dataFields: [AnyHashable: Any],
                    mergeNestedObjects: Bool,
                    onSuccess: OnSuccessHandler?,
                    onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        onlineProcessor.updateUser(dataFields,
                                   mergeNestedObjects: mergeNestedObjects,
                                   onSuccess: onSuccess,
                                   onFailure: onFailure)
    }
    
    @discardableResult
    func updateEmail(_ newEmail: String,
                     onSuccess: OnSuccessHandler?,
                     onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        onlineProcessor.updateEmail(newEmail,
                                    onSuccess: onSuccess,
                                    onFailure: onFailure)
    }
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]?,
                       onSuccess: OnSuccessHandler?,
                       onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().trackPurchase(total,
                                               items: items,
                                               dataFields: dataFields,
                                               onSuccess: onSuccess,
                                               onFailure: onFailure)
    }
    
    @discardableResult
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]?,
                       onSuccess: OnSuccessHandler?,
                       onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().trackPushOpen(campaignId,
                                               templateId: templateId,
                                               messageId: messageId,
                                               appAlreadyRunning: appAlreadyRunning,
                                               dataFields: dataFields,
                                               onSuccess: onSuccess,
                                               onFailure: onFailure)
    }
    
    @discardableResult
    func track(event: String,
               dataFields: [AnyHashable: Any]?,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().track(event: event,
                                       dataFields: dataFields,
                                       onSuccess: onSuccess,
                                       onFailure: onFailure)
    }
    
    @discardableResult
    func updateSubscriptions(info: UpdateSubscriptionsInfo,
                             onSuccess: OnSuccessHandler?,
                             onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        onlineProcessor.updateSubscriptions(info: info,
                                            onSuccess: onSuccess,
                                            onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppOpen(_ message: IterableInAppMessage,
                        location: InAppLocation,
                        inboxSessionId: String?,
                        onSuccess: OnSuccessHandler?,
                        onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().trackInAppOpen(message,
                                                location: location,
                                                inboxSessionId: inboxSessionId,
                                                onSuccess: onSuccess,
                                                onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().trackInAppClick(message,
                                                 location: location,
                                                 inboxSessionId: inboxSessionId,
                                                 clickedUrl: clickedUrl,
                                                 onSuccess: onSuccess,
                                                 onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         source: InAppCloseSource?,
                         clickedUrl: String?,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().trackInAppClose(message,
                                                 location: location,
                                                 inboxSessionId: inboxSessionId,
                                                 source: source,
                                                 clickedUrl: clickedUrl,
                                                 onSuccess: onSuccess,
                                                 onFailure: onFailure)
    }
    
    @discardableResult
    func track(inboxSession: IterableInboxSession,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().track(inboxSession: inboxSession,
                                       onSuccess: onSuccess,
                                       onFailure: onFailure)
    }
    
    @discardableResult
    func track(inAppDelivery message: IterableInAppMessage,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().track(inAppDelivery: message,
                                       onSuccess: onSuccess,
                                       onFailure: onFailure)
    }
    
    @discardableResult
    func inAppConsume(_ messageId: String,
                      onSuccess: OnSuccessHandler?,
                      onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().inAppConsume(messageId,
                                              onSuccess: onSuccess,
                                              onFailure: onFailure)
    }
    
    @discardableResult
    func inAppConsume(message: IterableInAppMessage,
                      location: InAppLocation,
                      source: InAppDeleteSource?,
                      onSuccess: OnSuccessHandler?,
                      onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().inAppConsume(message: message,
                                              location: location,
                                              source: source,
                                              onSuccess: onSuccess,
                                              onFailure: onFailure)
    }
    
    // MARK: DEPRECATED
    
    @discardableResult
    func trackInAppOpen(_ messageId: String,
                        onSuccess: OnSuccessHandler?,
                        onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().trackInAppOpen(messageId,
                                                onSuccess: onSuccess,
                                                onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppClick(_ messageId: String,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        chooseRequestProcessor().trackInAppClick(messageId,
                                                 clickedUrl: clickedUrl,
                                                 onSuccess: onSuccess,
                                                 onFailure: onFailure)
    }
    
    func handleLogout() throws {
        if strategy.chooseOfflineProcessor {
            try offlineProcessor?.deleteAllTasks()
        }
    }

    private let onlineCreator: () -> OnlineRequestProcessor
    private let offlineCreator: () -> OfflineRequestProcessor?
    
    private let strategy: RequestProcessorStrategy
    
    private lazy var offlineProcessor: OfflineRequestProcessor? = {
        offlineCreator()
    }()
    
    private lazy var onlineProcessor: OnlineRequestProcessor = {
        onlineCreator()
    }()
    
    private func chooseRequestProcessor() -> RequestProcessorProtocol {
        if strategy.chooseOfflineProcessor {
            if let offlineProcessor = self.offlineProcessor {
                return offlineProcessor
            }
            return onlineProcessor
        } else {
            return onlineProcessor
        }
    }
}
