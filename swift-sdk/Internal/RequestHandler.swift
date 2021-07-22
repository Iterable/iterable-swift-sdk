//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
@available(iOSApplicationExtension, unavailable)
class RequestHandler: RequestHandlerProtocol {
    init(onlineProcessor: OnlineRequestProcessor,
         offlineProcessor: OfflineRequestProcessor?,
         healthMonitor: HealthMonitor?,
         offlineMode: Bool = true) {
        ITBInfo()
        self.onlineProcessor = onlineProcessor
        self.offlineProcessor = offlineProcessor
        self.healthMonitor = healthMonitor
        self.offlineMode = offlineMode
        self.healthMonitor?.delegate = self
    }
    
    deinit {
        ITBInfo()
    }
    
    var offlineMode: Bool
    
    func start() {
        ITBInfo()
        if offlineMode {
            offlineProcessor?.start()
        }
    }
    
    func stop() {
        ITBInfo()
        if offlineMode {
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
    
    func getRemoteConfiguration() -> Future<RemoteConfiguration, SendRequestError> {
        onlineProcessor.getRemoteConfiguration()
    }
    
    func handleLogout() throws {
        if offlineMode {
            offlineProcessor?.deleteAllTasks()
        }
    }

    private let offlineProcessor: OfflineRequestProcessor?
    private let healthMonitor: HealthMonitor?
    private let onlineProcessor: OnlineRequestProcessor
    
    private func chooseRequestProcessor() -> RequestProcessorProtocol {
        guard offlineMode else {
            return onlineProcessor
        }
        guard
            let offlineProcessor = offlineProcessor,
            let healthMonitor = healthMonitor
        else {
            return onlineProcessor
        }

        return healthMonitor.canSchedule() ? offlineProcessor : onlineProcessor
    }
}

@available(iOS 10.0, *)
@available(iOSApplicationExtension, unavailable)
extension RequestHandler: HealthMonitorDelegate {
    func onDBError() {
        self.offlineMode = false
    }
}
