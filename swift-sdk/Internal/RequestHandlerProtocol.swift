//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// `InternalIterableAPI` will delegate all network related calls to this protocol.
protocol RequestHandlerProtocol: AnyObject {
    var offlineMode: Bool { get set }
    var autoRetry: Bool { get set }

    func start()
    
    func stop()
    
    func register(registerTokenInfo: RegisterTokenInfo,
                  notificationStateProvider: NotificationStateProviderProtocol,
                  onSuccess: OnSuccessHandler?,
                  onFailure: OnFailureHandler?)
    
    /// - Parameter onHandoff: see `RequestProcessorProtocol.disableDeviceForCurrentUser`. Use
    ///   the three-argument overload unless the caller has to know when the request left the
    ///   SDK's control.
    @discardableResult
    func disableDeviceForCurrentUser(hexToken: String,
                                     withOnSuccess onSuccess: OnSuccessHandler?,
                                     onFailure: OnFailureHandler?,
                                     onHandoff: ((Bool) -> Void)?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func disableDeviceForAllUsers(hexToken: String,
                                  withOnSuccess onSuccess: OnSuccessHandler?,
                                  onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func updateUser(_ dataFields: [AnyHashable: Any],
                    mergeNestedObjects: Bool,
                    onSuccess: OnSuccessHandler?,
                    onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func updateEmail(_ newEmail: String,
                     onSuccess: OnSuccessHandler?,
                     onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func updateCart(items: [CommerceItem],
                    onSuccess: OnSuccessHandler?,
                    onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func updateCart(items: [CommerceItem],
                    createdAt: Int,
                    onSuccess: OnSuccessHandler?,
                    onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]?,
                       campaignId: NSNumber?,
                       templateId: NSNumber?,
                       onSuccess: OnSuccessHandler?,
                       onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]?,
                       createdAt: Int,
                       onSuccess: OnSuccessHandler?,
                       onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]?,
                       onSuccess: OnSuccessHandler?,
                       onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func track(event: String,
               dataFields: [AnyHashable: Any]?,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func track(event: String,
               withBody body: [AnyHashable: Any]?,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func updateSubscriptions(info: UpdateSubscriptionsInfo,
                             onSuccess: OnSuccessHandler?,
                             onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func trackInAppOpen(_ message: IterableInAppMessage,
                        location: InAppLocation,
                        inboxSessionId: String?,
                        onSuccess: OnSuccessHandler?,
                        onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         source: InAppCloseSource?,
                         clickedUrl: String?,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    @discardableResult
    func track(inboxSession: IterableInboxSession,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func track(inAppDelivery message: IterableInAppMessage,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func inAppConsume(_ messageId: String,
                      onSuccess: OnSuccessHandler?,
                      onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func inAppConsume(message: IterableInAppMessage,
                      location: InAppLocation,
                      source: InAppDeleteSource?,
                      inboxSessionId: String?,
                      onSuccess: OnSuccessHandler?,
                      onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func track(embeddedMessageReceived message: IterableEmbeddedMessage,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func track(embeddedMessageClick message: IterableEmbeddedMessage,
               buttonIdentifier: String?,
               clickedUrl: String,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    
    @discardableResult
    func track(embeddedSession: IterableEmbeddedSession,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError>
    

    /// Purges the persisted offline queue, preserving queued `disableDevice` tasks.
    ///
    /// - Parameter completion: invoked once the purge has finished, on an unspecified queue.
    ///   Pass `nil` (or use the `handleLogout()` overload) for the fire-and-forget behaviour
    ///   the logout path relies on.
    func handleLogout(completion: (() -> Void)?) throws
    
    func getRemoteConfiguration() -> Pending<RemoteConfiguration, SendRequestError>
}

extension RequestHandlerProtocol {
    func handleLogout() throws {
        try handleLogout(completion: nil)
    }

    @discardableResult
    func disableDeviceForCurrentUser(hexToken: String,
                                     withOnSuccess onSuccess: OnSuccessHandler?,
                                     onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError> {
        disableDeviceForCurrentUser(hexToken: hexToken,
                                    withOnSuccess: onSuccess,
                                    onFailure: onFailure,
                                    onHandoff: nil)
    }
}
