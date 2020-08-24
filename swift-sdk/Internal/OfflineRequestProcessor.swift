//
//  Created by Tapash Majumder on 8/24/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
struct OfflineRequestProcessor: RequestProcessorProtocol {
    init(apiKey: String,
         authProvider: AuthProvider,
         endPoint: String,
         deviceMetadata: DeviceMetadata,
         notificationCenter: NotificationCenterProtocol) {
        self.apiKey = apiKey
        self.authProvider = authProvider
        self.endPoint = endPoint
        self.deviceMetadata = deviceMetadata
        notificationListener = NotificationListener(notificationCenter: notificationCenter)
    }
    
    @discardableResult
    func register(registerTokenInfo: RegisterTokenInfo,
                  notificationStateProvider: NotificationStateProviderProtocol,
                  onSuccess: OnSuccessHandler?,
                  onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func disableDeviceForCurrentUser(hexToken: String,
                                     withOnSuccess onSuccess: OnSuccessHandler?,
                                     onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func disableDeviceForAllUsers(hexToken: String,
                                  withOnSuccess onSuccess: OnSuccessHandler?,
                                  onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func updateUser(_ dataFields: [AnyHashable: Any],
                    mergeNestedObjects: Bool,
                    onSuccess: OnSuccessHandler?,
                    onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func updateEmail(_ newEmail: String,
                     withToken _: String?,
                     onSuccess: OnSuccessHandler?,
                     onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]?,
                       onSuccess: OnSuccessHandler?,
                       onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]?,
                       onSuccess: OnSuccessHandler?,
                       onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func track(event: String,
               dataFields: [AnyHashable: Any]?,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        ITBInfo()
        guard let authProvider = authProvider else {
            fatalError("authProvider is missing")
        }

        let requestCreator = createRequestCreator(authProvider: authProvider)
        guard case let Result.success(trackEventRequest) = requestCreator.createTrackEventRequest(event, dataFields: dataFields) else {
            return SendRequestError.createErroredFuture(reason: "Could not create trackEvent request")
        }
        
        let apiCallRequest = IterableAPICallRequest(apiKey: apiKey,
                                                    endPoint: endPoint,
                                                    auth: authProvider.auth,
                                                    deviceMetadata: deviceMetadata,
                                                    iterableRequest: trackEventRequest)

        do {
            let taskId = try IterableTaskScheduler().schedule(apiCallRequest: apiCallRequest,
                                                              context: IterableTaskContext(blocking: true))
            return notificationListener.futureFromTask(withTaskId: taskId)
        } catch let error {
            ITBError(error.localizedDescription)
            return SendRequestError.createErroredFuture(reason: error.localizedDescription)
        }
    }
    
    @discardableResult
    func updateSubscriptions(info: UpdateSubscriptionsInfo,
                             onSuccess: OnSuccessHandler?,
                             onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func trackInAppOpen(_ message: IterableInAppMessage,
                        location: InAppLocation,
                        inboxSessionId: String?,
                        onSuccess: OnSuccessHandler?,
                        onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         source: InAppCloseSource?,
                         clickedUrl: String?,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func track(inboxSession: IterableInboxSession,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func track(inAppDelivery message: IterableInAppMessage,
               onSuccess: OnSuccessHandler?,
               onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func inAppConsume(_ messageId: String,
                      onSuccess: OnSuccessHandler?,
                      onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func inAppConsume(message: IterableInAppMessage,
                      location: InAppLocation,
                      source: InAppDeleteSource?,
                      onSuccess: OnSuccessHandler?,
                      onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    // MARK: DEPRECATED
    
    @discardableResult
    func trackInAppOpen(_ messageId: String,
                        onSuccess: OnSuccessHandler?,
                        onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    @discardableResult
    func trackInAppClick(_ messageId: String,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler?,
                         onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        fatalError()
    }
    
    private let apiKey: String
    private weak var authProvider: AuthProvider?
    private let endPoint: String
    private let deviceMetadata: DeviceMetadata
    private let notificationListener: NotificationListener
    
    private func createRequestCreator(authProvider: AuthProvider) -> RequestCreator {
        return RequestCreator(apiKey: apiKey, auth: authProvider.auth, deviceMetadata: deviceMetadata)
    }
    
    private class NotificationListener: NSObject {
        init(notificationCenter: NotificationCenterProtocol) {
            self.notificationCenter = notificationCenter
            super.init()
            self.notificationCenter.addObserver(self,
                                                selector: #selector(on(notification:)),
                                                name: .iterableTaskFinishedWithSuccess, object: nil)
        }
        
        deinit {
            self.notificationCenter.removeObserver(self)
        }
        
        func futureFromTask(withTaskId taskId: String) -> Future<SendRequestValue, SendRequestError> {
            ITBInfo()
            let result = Promise<SendRequestValue, SendRequestError>()
            pendingTasksMap[taskId] = result
            return result
        }
        
        @objc
        private func on(notification: Notification) {
            switch notification.name {
            case .iterableTaskFinishedWithSuccess:
                if let taskSendRequestValue = IterableNotificationUtil.notificationToTaskSendRequestValue(notification) {
                    let taskId = taskSendRequestValue.taskId
                    ITBInfo("task: \(taskId) finished with success")
                    if let promise = pendingTasksMap[taskId] {
                        promise.resolve(with: taskSendRequestValue.sendRequestValue)
                        pendingTasksMap.removeValue(forKey: taskId)
                    } else {
                        ITBError("could not find promise for taskId: \(taskId)")
                    }
                } else {
                    ITBError("Could not find taskId for notification")
                }
            case .iterableTaskFinishedWithNoRetry:
                if let taskSendRequestError = IterableNotificationUtil.notificationToTaskSendRequestError(notification) {
                    let taskId = taskSendRequestError.taskId
                    ITBInfo("task: \(taskId) finished with no retry")
                    if let promise = pendingTasksMap[taskId] {
                        promise.reject(with: taskSendRequestError.sendRequestError)
                        pendingTasksMap.removeValue(forKey: taskId)
                    } else {
                        ITBError("could not find promise for taskId: \(taskId)")
                    }
                } else {
                    ITBError("Could not find taskId for notification")
                }
            case .iterableTaskFinishedWithRetry:
                break
            default:
                break
            }
        }
        
        private var notificationCenter: NotificationCenterProtocol
        private var pendingTasksMap = [String: Promise<SendRequestValue, SendRequestError>]()
    }
}
