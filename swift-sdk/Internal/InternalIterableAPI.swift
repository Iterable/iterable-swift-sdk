//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

final class InternalIterableAPI: NSObject, PushTrackerProtocol, AuthProvider {
    var apiKey: String
    
    var lastPushPayload: [AnyHashable: Any]? {
        get {
            _payloadData
        } set {
            setPayloadData(newValue)
        }
    }

    var email: String? {
        get {
            _email
        } set {
            setEmail(newValue)
        }
    }
    
    var userId: String? {
        get {
            _userId
        } set {
            setUserId(newValue)
        }
    }
    
    var authToken: String? {
        get {
            authManager.getAuthToken()
        }
    }
    
    var deviceId: String {
        if let value = localStorage.deviceId {
            return value
        } else {
            let value = IterableUtil.generateUUID()
            localStorage.deviceId = value
            return value
        }
    }
    
    // MARK: - Pending Consent Tracking
    
    /// Holds consent data that should be sent once user creation is confirmed
    private struct PendingConsentData {
        let consentTimestamp: Int64
        let email: String?
        let userId: String?
        let isUserKnown: Bool
    }
    
    private var pendingConsentData: PendingConsentData?
    
    var deviceMetadata: DeviceMetadata {
        DeviceMetadata(deviceId: deviceId,
                       platform: JsonValue.iOS,
                       appPackageName: Bundle.main.appPackageName ?? "")
    }
    
    var attributionInfo: IterableAttributionInfo? {
        get {
            localStorage.getAttributionInfo(currentDate: dateProvider.currentDate)
        } set {
            let expiration = Calendar.current.date(byAdding: .hour,
                                                   value: Const.UserDefault.attributionInfoExpiration,
                                                   to: dateProvider.currentDate)
            localStorage.save(attributionInfo: newValue, withExpiration: expiration)
        }
    }
    
    var auth: Auth {
        Auth(userId: userId, email: email, authToken: authManager.getAuthToken(), userIdUnknownUser: localStorage.userIdUnknownUser)
    }

    var dependencyContainer: DependencyContainerProtocol
    
    lazy var inAppManager: IterableInternalInAppManagerProtocol = {
        self.dependencyContainer.createInAppManager(config: self.config,
                                                    apiClient: self.apiClient,
                                                    requestHandler: self.requestHandler,
                                                    deviceMetadata: deviceMetadata,
                                                    authManager: self.authManager)
    }()
    
    lazy var authManager: IterableAuthManagerProtocol = {
        self.dependencyContainer.createAuthManager(config: self.config)
    }()
    
    lazy var unknownUserManager: UnknownUserManagerProtocol = {
        self.dependencyContainer.createUnknownUserManager(config: self.config)
    }()
    
    lazy var unknownUserMerge: UnknownUserMergeProtocol = {
        self.dependencyContainer.createUnknownUserMerge(apiClient: apiClient as! ApiClient, unknownUserManager: unknownUserManager, localStorage: localStorage)
    }()
    
    lazy var embeddedManager: IterableInternalEmbeddedManagerProtocol = {
        self.dependencyContainer.createEmbeddedManager(config: self.config,
                                                                apiClient: self.apiClient)
    }()
    
    var apiEndPointForTest: String {
        get {
            apiEndPoint
        }
    }
    
    // MARK: - SDK Functions
    
    @discardableResult func handleUniversalLink(_ url: URL) -> Bool {
        let (result, pending) = deepLinkManager.handleUniversalLink(url,
                                                                   urlDelegate: config.urlDelegate,
                                                                   urlOpener: urlOpener,
                                                                   allowedProtocols: config.allowedProtocols)
        
        pending.onSuccess { attributionInfo in
            if let attributionInfo = attributionInfo {
                self.attributionInfo = attributionInfo
            }
        }
        return result
    }
    
    func setDeviceAttribute(name: String, value: String) {
        deviceAttributes[name] = value
    }
    
    func removeDeviceAttribute(name: String) {
        deviceAttributes.removeValue(forKey: name)
    }

    func setPayloadData(_ data: [AnyHashable: Any]?) {
        ITBInfo()
        _payloadData = data
    }
    
    func setEmail(_ email: String?, authToken: String? = nil, successHandler: OnSuccessHandler? = nil, failureHandler: OnFailureHandler? = nil, identityResolution: IterableIdentityResolution? = nil) {
        
        ITBInfo()
        if self._email == email && email != nil {
            self.checkAndUpdateAuthToken(authToken)
            return
        }

        if self._email == email {
            return
        }
        
        self.logoutPreviousUser()

        self._email = email
        self._userId = nil

        self.onLogin(authToken) { [weak self] in
            guard let config = self?.config else {
                return
            }
            let merge = identityResolution?.mergeOnUnknownUserToKnown ?? config.identityResolution.mergeOnUnknownUserToKnown
            let replay = identityResolution?.replayOnVisitorToKnown ?? config.identityResolution.replayOnVisitorToKnown
            if config.enableUnknownUserActivation, let email = email {
                // Prepare consent for replay scenario before merge
                // Check if this is truly a replay scenario (no existing anonymous user before merge)
                if let replay, replay, self?.localStorage.userIdUnknownUser == nil {
                    self?.prepareConsent(email: email, userId: nil)
                }
                
                self?.attemptAndProcessMerge(
                    merge: merge ?? true,
                    replay: replay ?? true,
                    destinationUser: email,
                    isEmail: true,
                    failureHandler: failureHandler
                )
                
                // Clear unknown user ID after merge for email login
                self?.localStorage.userIdUnknownUser = nil
            }
        }
        

        self._successCallback = successHandler
        self._failureCallback = failureHandler
        self.storeIdentifierData()
    }
    
    func setUserId(_ userId: String?, authToken: String? = nil, successHandler: OnSuccessHandler? = nil, failureHandler: OnFailureHandler? = nil, isUnknownUser: Bool = false, identityResolution: IterableIdentityResolution? = nil) {
        ITBInfo()

        if self._userId == userId && userId != nil {
            self.checkAndUpdateAuthToken(authToken)
            return
        }

        if self._userId == userId {
            return
        }

        self.logoutPreviousUser()

        self._email = nil
        self._userId = userId
        
        self.onLogin(authToken) { [weak self] in
            guard let config = self?.config else {
                return
            }
            if config.enableUnknownUserActivation {
                if let userId = userId, userId != (self?.localStorage.userIdUnknownUser ?? "") {
                    let merge = identityResolution?.mergeOnUnknownUserToKnown ?? config.identityResolution.mergeOnUnknownUserToKnown
                    let replay = identityResolution?.replayOnVisitorToKnown ?? config.identityResolution.replayOnVisitorToKnown
                    
                    // Prepare consent for replay scenario before merge
                    // Check if this is truly a replay scenario (no existing anonymous user before merge)
                    if let replay, replay, self?.localStorage.userIdUnknownUser == nil {
                        self?.prepareConsent(email: nil, userId: userId)
                    }
                    
                    self?.attemptAndProcessMerge(
                        merge: merge ?? true,
                        replay: replay ?? true,
                        destinationUser: userId,
                        isEmail: false,
                        failureHandler: failureHandler
                    )
                    
                    // Clear unknown user ID after merge (unless this is an unknown user login)
                    if !isUnknownUser {
                        self?.localStorage.userIdUnknownUser = nil
                    }
                }
            }
        }

        self._successCallback = successHandler
        self._failureCallback = failureHandler
        self.storeIdentifierData()

    }

    func logoutUser() {
        logoutPreviousUser()
    }
    
    func attemptAndProcessMerge(merge: Bool, replay: Bool, destinationUser: String?, isEmail: Bool, failureHandler: OnFailureHandler? = nil) {
        unknownUserMerge.tryMergeUser(destinationUser: destinationUser, isEmail: isEmail, merge: merge) { mergeResult, error in
            
            if mergeResult == MergeResult.mergenotrequired ||  mergeResult == MergeResult.mergesuccessful {
                if (replay) {
                    self.unknownUserManager.syncEvents()
                }
            } else {
                failureHandler?(error, nil)
            }
            self.unknownUserManager.clearVisitorEventsAndUserData()
        }
    }

    func setVisitorUsageTracked(isVisitorUsageTracked: Bool) {
        ITBInfo("CONSENT CHANGED - local events cleared")
        self.localStorage.visitorUsageTracked = isVisitorUsageTracked
        
        // Store consent timestamp when consent is given
        if isVisitorUsageTracked {
            self.localStorage.visitorConsentTimestamp = Int64(dateProvider.currentDate.timeIntervalSince1970 * 1000)
        } else {
            self.localStorage.visitorConsentTimestamp = nil
        }
        
        self.localStorage.unknownUserEvents = nil
        self.localStorage.unknownUserSessions = nil
        self.localStorage.unknownUserUpdate = nil
        self.localStorage.userIdUnknownUser = nil
        
        if isVisitorUsageTracked && config.enableUnknownUserActivation {
            ITBInfo("CONSENT GIVEN and UNKNOWN USER TRACKING ENABLED - Criteria fetched")
            self.unknownUserManager.getUnknownUserCriteria()
            self.unknownUserManager.updateUnknownUserSession()
        }
    }

    func getVisitorUsageTracked() -> Bool {
        return self.localStorage.visitorUsageTracked
    }

    /// Prepares consent data to be sent when user registration is confirmed during "replay scenario".
    ///
    /// A "replay scenario" occurs when a user signs up or logs in but does not meet the criteria
    /// for immediate consent tracking. This method stores consent data to be sent once user 
    /// registration is confirmed through the registration success callback.
    ///
    /// This method is typically called during user sign-up or sign-in processes to ensure that
    /// consent data is properly recorded for compliance and analytics purposes.
    private func prepareConsent(email: String?, userId: String?) {
        guard let consentTimestamp = localStorage.visitorConsentTimestamp else {
            return
        }
        
        // Only prepare consent if we have previous anonymous tracking consent but no anonymous user ID
        guard localStorage.userIdUnknownUser == nil && localStorage.visitorUsageTracked else {
            return
        }
        
        // Store the consent data to be sent when user registration is confirmed
        pendingConsentData = PendingConsentData(
            consentTimestamp: consentTimestamp,
            email: email,
            userId: userId,
            isUserKnown: true
        )
        
        ITBInfo("Consent data prepared for replay scenario - will send after user registration is confirmed")
    }
    
    /// Sends any pending consent data now that user creation is confirmed
    private func sendPendingConsent() {
        guard let consentData = pendingConsentData else {
            ITBDebug("No pending consent to send")
            return
        }
        
        ITBDebug("Sending pending consent after user registration: email set=\(consentData.email != nil), userId set=\(consentData.userId != nil), timestamp=\(consentData.consentTimestamp)")
        
        // Track consent with retry logic if enabled
        trackConsentWithRetry(consentData: consentData, isRetryAttempt: false)
        
        // Clear the pending consent data
        pendingConsentData = nil
    }
    
    /// Tracks consent with optional retry mechanism
    private func trackConsentWithRetry(consentData: PendingConsentData, isRetryAttempt: Bool) {
        apiClient.trackConsent(
            consentTimestamp: consentData.consentTimestamp,
            email: consentData.email,
            userId: consentData.userId,
            isUserKnown: consentData.isUserKnown
        ).onSuccess { _ in
            if isRetryAttempt {
                ITBInfo("Pending consent tracked successfully on retry attempt after user registration")
            } else {
                ITBInfo("Pending consent tracked successfully after user registration")
            }
        }.onError { [weak self] error in
            if !isRetryAttempt {
                ITBInfo("First consent tracking attempt failed, retrying once: \(error)")
                self?.trackConsentWithRetry(consentData: consentData, isRetryAttempt: true)
            } else {
                let attemptDescription = isRetryAttempt ? "retry attempt" : "initial attempt"
                ITBError("Failed to track pending consent after user registration (\(attemptDescription)): \(error)")
            }
        }
    }

    // MARK: - API Request Calls
    
    func register(token: String,
                  onSuccess: OnSuccessHandler? = nil,
                  onFailure: OnFailureHandler? = nil) {
        
        guard let appName = pushIntegrationName else {
            let errorMessage = "Not registering device token - appName must not be nil"
            ITBError(errorMessage)
            _failureCallback?(errorMessage, nil)
            onFailure?(errorMessage, nil)
            return
        }

         if !isEitherUserIdOrEmailSet() && localStorage.userIdUnknownUser == nil {
            if config.enableUnknownUserActivation {
                unknownUserManager.trackUnknownUserTokenRegistration(token: token)
            }
            onFailure?("Iterable SDK must be initialized with an API key and user email/userId before calling SDK methods", nil)
            return
        }
        
        hexToken = token
        
        let mobileFrameworkInfo = config.mobileFrameworkInfo ?? createDefaultMobileFrameworkInfo()
        
        let registerTokenInfo = RegisterTokenInfo(hexToken: token,
                                                appName: appName,
                                                pushServicePlatform: config.pushPlatform,
                                                apnsType: dependencyContainer.apnsTypeChecker.apnsType,
                                                deviceId: deviceId,
                                                deviceAttributes: deviceAttributes,
                                                sdkVersion: localStorage.sdkVersion,
                                                mobileFrameworkInfo: mobileFrameworkInfo)
        requestHandler.register(registerTokenInfo: registerTokenInfo,
                                notificationStateProvider: notificationStateProvider,
                                onSuccess: { (_ data: [AnyHashable: Any]?) in
                                                // Send any pending consent now that user registration is confirmed
                                                ITBDebug("Device registration succeeded; attempting to send pending consent if any")
                                                if self.config.identityResolution.replayOnVisitorToKnown ?? true {
                                                    self.sendPendingConsent()
                                                } else {
                                                    ITBDebug("Event replay is disabled; skipping pending consent")
                                                }
                                                self.pendingConsentData = nil
                                                self._successCallback?(data)
                                                onSuccess?(data)
                                },
                                onFailure: { (_ reason: String?, _ data: Data?) in
                                                // Send any pending consent even when user registration fails
                                                ITBDebug("Device registration failed; attempting to send pending consent if any")
                                                if self.config.identityResolution.replayOnVisitorToKnown ?? true {
                                                    self.sendPendingConsent()
                                                } else {
                                                    ITBDebug("Event replay is disabled; skipping pending consent")
                                                }
                                                self.pendingConsentData = nil
                                                self._failureCallback?(reason, data)
                                                onFailure?(reason, data)
                                }
        )
    }
    
    func register(token: Data,
                  onSuccess: OnSuccessHandler? = nil,
                  onFailure: OnFailureHandler? = nil) {
        register(token: token.hexString(), onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func disableDeviceForCurrentUser(withOnSuccess onSuccess: OnSuccessHandler? = nil,
                                     onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        guard let hexToken = hexToken else {
            let errorMessage = "no token present"
            onFailure?(errorMessage, nil)
            return SendRequestError.createErroredFuture(reason: errorMessage)
        }
        
        guard isEitherUserIdOrEmailSet() else {
            let errorMessage = "either userId or email must be present"
            onFailure?(errorMessage, nil)
            return SendRequestError.createErroredFuture(reason: errorMessage)
        }
        
        return requestHandler.disableDeviceForCurrentUser(hexToken: hexToken, withOnSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func disableDeviceForAllUsers(withOnSuccess onSuccess: OnSuccessHandler? = nil,
                                  onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        guard let hexToken = hexToken else {
            let errorMessage = "no token present"
            onFailure?(errorMessage, nil)
            return SendRequestError.createErroredFuture(reason: errorMessage)
        }
        return requestHandler.disableDeviceForAllUsers(hexToken: hexToken, withOnSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateUser(_ dataFields: [AnyHashable: Any],
                    mergeNestedObjects: Bool,
                    onSuccess: OnSuccessHandler? = nil,
                    onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        if !isEitherUserIdOrEmailSet() && localStorage.userIdUnknownUser == nil {
            if config.enableUnknownUserActivation {
                ITBInfo("UUA ENABLED - unknown user update user")
                unknownUserManager.trackUnknownUserUpdateUser(dataFields)
            }
            return rejectWithInitializationError(onFailure: onFailure)
        }
        return requestHandler.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateEmail(_ newEmail: String,
                     withToken token: String? = nil,
                     onSuccess: OnSuccessHandler? = nil,
                     onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.updateEmail(newEmail,
                                   onSuccess: nil,
                                   onFailure: nil).onSuccess { json in
            if self.email != nil {
                self.setEmail(newEmail, authToken: token)
            }
            
            onSuccess?(json)
        }.onError { error in
            onFailure?(error.reason, error.data)
        }
    }
    
    @discardableResult
    func updateCart(items: [CommerceItem],
                    onSuccess: OnSuccessHandler? = nil,
                    onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        if !isEitherUserIdOrEmailSet() && localStorage.userIdUnknownUser == nil {
            if config.enableUnknownUserActivation {
                ITBInfo("UUA ENABLED - unknown user update cart")
                unknownUserManager.trackUnknownUserUpdateCart(items: items)
            }
            return rejectWithInitializationError(onFailure: onFailure)
        }
        return requestHandler.updateCart(items: items, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateCart(items: [CommerceItem],
                    createdAt: Int,
                    onSuccess: OnSuccessHandler? = nil,
                    onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        return requestHandler.updateCart(items: items, createdAt: createdAt, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    private func rejectWithInitializationError(onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        let result = Fulfill<SendRequestValue, SendRequestError>()
        result.reject(with: SendRequestError())
        onFailure?("Iterable SDK must be initialized with an API key and user email/userId before calling SDK methods", nil)
        return result
    }
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]? = nil,
                       campaignId: NSNumber? = nil,
                       templateId: NSNumber? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        if !isEitherUserIdOrEmailSet() {
            if config.enableUnknownUserActivation {
                ITBInfo("UUA ENABLED - unknown user track purchase")
                unknownUserManager.trackUnknownUserPurchaseEvent(total: total, items: items, dataFields: dataFields)
            }
            return rejectWithInitializationError(onFailure: onFailure)
        }
        return requestHandler.trackPurchase(total,
                                     items: items,
                                     dataFields: dataFields,
                                     campaignId: campaignId,
                                     templateId: templateId,
                                     onSuccess: onSuccess,
                                     onFailure: onFailure)
    }
    
    @discardableResult
    func trackPurchase(_ total: NSNumber,
                       items: [CommerceItem],
                       dataFields: [AnyHashable: Any]? = nil,
                       createdAt: Int,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        return requestHandler.trackPurchase(total,
                                     items: items,
                                     dataFields: dataFields,
                                     createdAt: createdAt,
                                     onSuccess: onSuccess,
                                     onFailure: onFailure)
    }

    
    @discardableResult
    func trackPushOpen(_ userInfo: [AnyHashable: Any],
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        save(pushPayload: userInfo)
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            return trackPushOpen(metadata.campaignId,
                                 templateId: metadata.templateId,
                                 messageId: metadata.messageId,
                                 appAlreadyRunning: false,
                                 dataFields: dataFields,
                                 onSuccess: onSuccess,
                                 onFailure: onFailure)
        } else {
            return SendRequestError.createErroredFuture(reason: "Not tracking push open - payload is not an Iterable notification, or is a test/proof/ghost push")
        }
    }
    
    @discardableResult
    func trackPushOpen(_ campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]? = nil,
                       onSuccess: OnSuccessHandler? = nil,
                       onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.trackPushOpen(campaignId,
                                       templateId: templateId,
                                       messageId: messageId,
                                       appAlreadyRunning: appAlreadyRunning,
                                       dataFields: dataFields,
                                       onSuccess: onSuccess,
                                       onFailure: onFailure)
    }
    
    @discardableResult
    func track(_ eventName: String,
               dataFields: [AnyHashable: Any]? = nil,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        if !isEitherUserIdOrEmailSet() && localStorage.userIdUnknownUser == nil {
            if config.enableUnknownUserActivation {
                ITBInfo("UUA ENABLED - unknown user track custom event")
                unknownUserManager.trackUnknownUserEvent(name: eventName, dataFields: dataFields)
            }
            return rejectWithInitializationError(onFailure: onFailure)
        }
        return requestHandler.track(event: eventName, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func track(_ eventName: String,
               withBody body: [AnyHashable: Any],
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(event: eventName, withBody: body, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func updateSubscriptions(_ emailListIds: [NSNumber]?,
                             unsubscribedChannelIds: [NSNumber]?,
                             unsubscribedMessageTypeIds: [NSNumber]?,
                             subscribedMessageTypeIds: [NSNumber]?,
                             campaignId: NSNumber?,
                             templateId: NSNumber?,
                             onSuccess: OnSuccessHandler? = nil,
                             onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        let updateSubscriptionsInfo = UpdateSubscriptionsInfo(emailListIds: emailListIds,
                                                              unsubscribedChannelIds: unsubscribedChannelIds,
                                                              unsubscribedMessageTypeIds: unsubscribedMessageTypeIds,
                                                              subscribedMessageTypeIds: subscribedMessageTypeIds,
                                                              campaignId: campaignId,
                                                              templateId: templateId)
        return requestHandler.updateSubscriptions(info: updateSubscriptionsInfo, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppOpen(_ message: IterableInAppMessage,
                        location: InAppLocation,
                        inboxSessionId: String? = nil,
                        onSuccess: OnSuccessHandler? = nil,
                        onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.trackInAppOpen(message,
                                        location: location,
                                        inboxSessionId: inboxSessionId,
                                        onSuccess: onSuccess,
                                        onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         clickedUrl: String,
                         onSuccess: OnSuccessHandler? = nil,
                         onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.trackInAppClick(message, location: location,
                                         inboxSessionId: inboxSessionId,
                                         clickedUrl: clickedUrl,
                                         onSuccess: onSuccess,
                                         onFailure: onFailure)
    }
    
    @discardableResult
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation = .inApp,
                         inboxSessionId: String? = nil,
                         source: InAppCloseSource? = nil,
                         clickedUrl: String? = nil,
                         onSuccess: OnSuccessHandler? = nil,
                         onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.trackInAppClose(message,
                                         location: location,
                                         inboxSessionId: inboxSessionId,
                                         source: source,
                                         clickedUrl: clickedUrl,
                                         onSuccess: onSuccess,
                                         onFailure: onFailure)
    }
    
    @discardableResult
    func track(inboxSession: IterableInboxSession,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(inboxSession: inboxSession, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func track(inAppDelivery message: IterableInAppMessage,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(inAppDelivery: message, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func inAppConsume(_ messageId: String,
                      onSuccess: OnSuccessHandler? = nil,
                      onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.inAppConsume(messageId, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult
    func inAppConsume(message: IterableInAppMessage,
                      location: InAppLocation = .inApp,
                      source: InAppDeleteSource? = nil,
                      inboxSessionId: String? = nil,
                      onSuccess: OnSuccessHandler? = nil,
                      onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {       
        requestHandler.inAppConsume(message: message,
                                    location: location,
                                    source: source,
                                    inboxSessionId: inboxSessionId,
                                    onSuccess: onSuccess,
                                    onFailure: onFailure)
    }
    
    @discardableResult
    func track(embeddedMessageReceived message: IterableEmbeddedMessage,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(embeddedMessageReceived: message,
                             onSuccess: onSuccess,
                             onFailure: onFailure)
    }
    
    @discardableResult
    func track(embeddedMessageClick message: IterableEmbeddedMessage,
               buttonIdentifier: String?,
               clickedUrl: String,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(embeddedMessageClick: message,
                             buttonIdentifier: buttonIdentifier,
                             clickedUrl: clickedUrl,
                             onSuccess: onSuccess,
                             onFailure: onFailure)
    }
    
    @discardableResult
    func track(embeddedMessageDismiss message: IterableEmbeddedMessage,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(embeddedMessageDismiss: message,
                             onSuccess: onSuccess,
                             onFailure: onFailure)
    }
    
    @discardableResult
    func track(embeddedMessageImpression message: IterableEmbeddedMessage,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(embeddedMessageImpression: message,
                             onSuccess: onSuccess,
                             onFailure: onFailure)
    }
    
    @discardableResult
    func track(embeddedSession: IterableEmbeddedSession,
               onSuccess: OnSuccessHandler? = nil,
               onFailure: OnFailureHandler? = nil) -> Pending<SendRequestValue, SendRequestError> {
        requestHandler.track(embeddedSession: embeddedSession, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    // MARK: - Private/Internal
    
    private var config: IterableConfig
    private var apiEndPoint: String
    
    /// Following are needed for handling pending notification and deep link.
    static var pendingNotificationResponse: NotificationResponseProtocol?
    static var pendingUniversalLink: URL?
    
    private let dateProvider: DateProviderProtocol
    private let inAppDisplayer: InAppDisplayerProtocol
    private var notificationStateProvider: NotificationStateProviderProtocol
    private var localStorage: LocalStorageProtocol
    private var networkSession: NetworkSessionProtocol
    private var urlOpener: UrlOpenerProtocol
    
    private var deepLinkManager: DeepLinkManager
    
    private var _email: String?
    private var _payloadData: [AnyHashable: Any]?
    private var _userId: String?
    private var _successCallback: OnSuccessHandler? = nil
    private var _failureCallback: OnFailureHandler? = nil
    
    private let notificationCenter: NotificationCenterProtocol

    
    /// the hex representation of this device token
    private var hexToken: String?
    
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    
    lazy var apiClient: ApiClientProtocol = {
        ApiClient(apiKey: apiKey,
                  authProvider: self,
                  endpoint: apiEndPoint,
                  networkSession: networkSession,
                  deviceMetadata: deviceMetadata,
                  dateProvider: dateProvider)
    }()
    
    lazy var requestHandler: RequestHandlerProtocol = {
        let offlineMode = self.localStorage.offlineMode
        return dependencyContainer.createRequestHandler(apiKey: apiKey,
                                                        config: config,
                                                        endpoint: apiEndPoint,
                                                        authProvider: self,
                                                        authManager: authManager,
                                                        deviceMetadata: deviceMetadata,
                                                        offlineMode: offlineMode)
    }()
    
    private var deviceAttributes = [String: String]()
    
    private var pushIntegrationName: String? {
        if let pushIntegrationName = config.pushIntegrationName, let sandboxPushIntegrationName = config.sandboxPushIntegrationName {
            switch config.pushPlatform {
            case .production:
                return pushIntegrationName
            case .sandbox:
                return sandboxPushIntegrationName
            case .auto:
                return dependencyContainer.apnsTypeChecker.apnsType == .sandbox ? sandboxPushIntegrationName : pushIntegrationName
            }
        } else if let pushIntegrationName = config.pushIntegrationName {
            return pushIntegrationName
        } else {
            return Bundle.main.appPackageName
        }
    }
    
    
    public func isSDKInitialized() -> Bool {
        let isInitialized = !apiKey.isEmpty && isEitherUserIdOrEmailSet()
        
        if !isInitialized {
            ITBInfo("Iterable SDK must be initialized with an API key and user email/userId before calling SDK methods")
        }
        
        return isInitialized
    }
    
    public func isEitherUserIdOrEmailSet() -> Bool {
        IterableUtil.isNotNullOrEmpty(string: _email) || IterableUtil.isNotNullOrEmpty(string: _userId)
    }
    
    public func noUserLoggedIn() -> Bool {
        IterableUtil.isNullOrEmpty(string: _email) && IterableUtil.isNullOrEmpty(string: _userId)
    }
    
    public func isUnknownUserSet() -> Bool {
        IterableUtil.isNotNullOrEmpty(string: localStorage.userIdUnknownUser)
    }
    
    private func logoutPreviousUser() {
        ITBInfo()
        
        guard isSDKInitialized() else { return }
        
        if config.autoPushRegistration {
            disableDeviceForCurrentUser()
        }
        
        _email = nil
        _userId = nil
        
        storeIdentifierData()
        
        authManager.logoutUser()
                
        _ = inAppManager.reset()
        _ = embeddedManager.reset()
        
        try? requestHandler.handleLogout()
    }
    
    private func storeIdentifierData() {
        localStorage.email = _email
        localStorage.userId = _userId
    }
    
    private func onLogin(_ authToken: String? = nil, onloginSuccess onloginSuccessCallBack: (()->())? = nil) {
        guard isSDKInitialized() else { return }

        ITBInfo()
        
        guard isSDKInitialized() else { return }
        
        self.authManager.pauseAuthRetries(false)
        if let authToken {
            self.authManager.setNewToken(authToken)
            completeUserLogin(onloginSuccessCallBack: onloginSuccessCallBack)
        } else if isEitherUserIdOrEmailSet() && config.authDelegate != nil {
            requestNewAuthToken(onloginSuccessCallBack: onloginSuccessCallBack)
        } else {
            completeUserLogin(onloginSuccessCallBack: onloginSuccessCallBack)
        }
    }
    
    private func requestNewAuthToken(onloginSuccessCallBack: (()->())? = nil) {
        ITBInfo()
        
        authManager.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: { [weak self] token in
            if token != nil {
                self?.completeUserLogin(onloginSuccessCallBack: onloginSuccessCallBack)
            }
        }, shouldIgnoreRetryPolicy: true)
    }
    
    private func completeUserLogin(onloginSuccessCallBack: (()->())? = nil) {
        ITBInfo()        
        guard isSDKInitialized() else { return }
        
        if config.autoPushRegistration {
            notificationStateProvider.registerForRemoteNotifications()
        } else {
            // If auto push registration is disabled, send pending consent here
            // since register() won't be called automatically
            ITBDebug("Auto push registration disabled; attempting to send pending consent after login")
            if config.identityResolution.replayOnVisitorToKnown ?? true {
                sendPendingConsent()
            } else {
                ITBDebug("Event replay is disabled; skipping pending consent")
            }
            _successCallback?([:])            
        }
        
        _ = inAppManager.scheduleSync()
        if onloginSuccessCallBack != nil {
            onloginSuccessCallBack!()
        }
    }
    
    private func retrieveIdentifierData() {
        _email = localStorage.email
        _userId = localStorage.userId
    }
    
    private func save(pushPayload payload: [AnyHashable: Any]) {
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload) {
            if let templateId = metadata.templateId {
                attributionInfo = IterableAttributionInfo(campaignId: metadata.campaignId, templateId: templateId, messageId: metadata.messageId)
            }

            if !metadata.isGhostPush {
                lastPushPayload = payload
            }
        }
    }
    
    private func checkAndUpdateAuthToken(_ authToken: String? = nil) {
        if config.authDelegate != nil && authToken != authManager.getAuthToken() && authToken != nil {
            onLogin(authToken)
        }
    }
    
    private static func setApiEndpoint(apiEndPointOverride: String?, config: IterableConfig) -> String {
        let apiEndPoint = config.dataRegion
        let endpoint = apiEndPointOverride ?? apiEndPoint
        
        // Sanitize and validate endpoint
        let sanitized = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate endpoint is a valid URL
        if let url = URL(string: sanitized) {
            if url.scheme == nil || url.host == nil {
                ITBError("Invalid API endpoint - missing scheme or host: '\(sanitized)'")
            }
        } else {
            ITBError("Invalid API endpoint - cannot create URL from: '\(sanitized)'")
        }
        
        // Check for common issues
        if sanitized != endpoint {
            ITBError("API endpoint contained whitespace, trimmed from '\(endpoint)' to '\(sanitized)'")
        }
        
        if sanitized.isEmpty {
            ITBError("API endpoint is empty after sanitization")
        }
        
        return sanitized
    }
    
    init(apiKey: String,
         launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
         config: IterableConfig = IterableConfig(),
         apiEndPointOverride: String? = nil,
         dependencyContainer: DependencyContainerProtocol = DependencyContainer()) {
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: dependencyContainer.dateProvider, logDelegate: config.logDelegate)
        ITBInfo()
        self.apiKey = apiKey
        self.launchOptions = launchOptions
        self.config = config
        apiEndPoint = InternalIterableAPI.setApiEndpoint(apiEndPointOverride: apiEndPointOverride, config: config)
        self.dependencyContainer = dependencyContainer
        dateProvider = dependencyContainer.dateProvider
        networkSession = dependencyContainer.networkSession
        notificationStateProvider = dependencyContainer.notificationStateProvider
        localStorage = dependencyContainer.localStorage
        inAppDisplayer = dependencyContainer.inAppDisplayer
        urlOpener = dependencyContainer.urlOpener
        notificationCenter = dependencyContainer.notificationCenter
        deepLinkManager = DeepLinkManager(redirectNetworkSessionProvider: dependencyContainer)
    }
    
    func start() -> Pending<Bool, Error> {
        ITBInfo()
        
        updateSDKVersion()
        
        // get email and userId from UserDefaults if present
        retrieveIdentifierData()
        
        if config.autoPushRegistration, isEitherUserIdOrEmailSet() {
            notificationStateProvider.registerForRemoteNotifications()
        }
        
        IterableAppIntegration.implementation = InternalIterableAppIntegration(tracker: self,
                                                                               urlDelegate: config.urlDelegate,
                                                                               customActionDelegate: config.customActionDelegate,
                                                                               urlOpener: urlOpener,
                                                                               allowedProtocols: config.allowedProtocols,
                                                                               inAppNotifiable: inAppManager,
                                                                               embeddedNotifiable: embeddedManager)
        
        handle(launchOptions: launchOptions)
        
        handlePendingNotification()
        
        handlePendingUniversalLink()
        
        requestHandler.start()
        
        checkRemoteConfiguration()
        
        addForegroundObservers()
                
        return inAppManager.start()
    }
    
    private func addForegroundObservers() {
        notificationCenter.addObserver(self,
                                     selector: #selector(onAppDidBecomeActiveNotification(notification:)),
                                     name: UIApplication.didBecomeActiveNotification,
                                     object: nil)
    }
    
    @objc private func onAppDidBecomeActiveNotification(notification: Notification) {
        handlePushNotificationState()
        handleMatchingCriteriaState()
    }
    
    private func handlePushNotificationState() {
        guard config.autoPushRegistration else { return }
        
        notificationStateProvider.isNotificationsEnabled { [weak self] systemEnabled in
            guard let self = self else { return }
            
            let storedEnabled = self.localStorage.isNotificationsEnabled
            let hasStoredPermission = self.localStorage.hasStoredNotificationSetting
            
            if self.isEitherUserIdOrEmailSet() {
                if hasStoredPermission && (storedEnabled != systemEnabled) {
                    self.notificationStateProvider.registerForRemoteNotifications()
                }
                
                // Always store the current state
                self.localStorage.isNotificationsEnabled = systemEnabled
                self.localStorage.hasStoredNotificationSetting = true
            }
        }
    }
    
    private func handleMatchingCriteriaState() {
        guard config.enableForegroundCriteriaFetch else { return }
        
        let currentTime = Date().timeIntervalSince1970 * 1000  // Convert to milliseconds
        
        // fetching unknown user criteria on foregrounding
        if noUserLoggedIn()
            && !isUnknownUserSet()
            && config.enableUnknownUserActivation
            && getVisitorUsageTracked()
            && (currentTime - unknownUserManager.getLastCriteriaFetch() >= Const.criteriaFetchingCooldown) {
            
            unknownUserManager.updateLastCriteriaFetch(currentTime: currentTime)
            unknownUserManager.getUnknownUserCriteria()
            ITBInfo("Fetching unknown user criteria - Foreground")
        }
    }
    
    private func handle(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let launchOptions = launchOptions else {
            return
        }
        
        if let remoteNotificationPayload = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            
            if let aps = remoteNotificationPayload[Const.RemoteNotification.aps] as? [String: Any],
               let contentAvailable = aps[Const.RemoteNotification.contentAvailable] as? Int,
               contentAvailable == 1 {
                ITBInfo("Received push notification with wakey content-available flag")
                return
            }
            
            if let _ = IterableUtil.rootViewController {
                // we are ready
                IterableAppIntegration.implementation?.performDefaultNotificationAction(remoteNotificationPayload)
            } else {
                // keywindow not set yet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    IterableAppIntegration.implementation?.performDefaultNotificationAction(remoteNotificationPayload)
                }
            }
        }
    }
    
    private func handlePendingNotification() {
        if let pendingNotificationResponse = Self.pendingNotificationResponse {
            IterableAppIntegration.implementation?.userNotificationCenter(nil, didReceive: pendingNotificationResponse, withCompletionHandler: nil)
            Self.pendingNotificationResponse = nil
        }
    }
    
    private func handlePendingUniversalLink() {
        if let pendingUniversalLink = Self.pendingUniversalLink {
            handleUniversalLink(pendingUniversalLink)
            Self.pendingUniversalLink = nil
        }
    }
    
    private func updateSDKVersion() {
        // Always attempt keychain migration to handle uninstall/reinstall scenario
        // where UserDefaults are cleared but keychain persists
        localStorage.migrateKeychainToIsolatedStorage()
        
        if let lastVersion = localStorage.sdkVersion, lastVersion != IterableAPI.sdkVersion {
            performUpgrade(lastVersion: lastVersion, newVersion: IterableAPI.sdkVersion)
        } else {
            localStorage.sdkVersion = IterableAPI.sdkVersion
        }
    }
    
    private func performUpgrade(lastVersion _: String, newVersion: String) {
        // do upgrade things here
        localStorage.upgrade()
        
        // then set new version
        localStorage.sdkVersion = newVersion
    }
    
    private func checkRemoteConfiguration() {
        ITBInfo()
        requestHandler.getRemoteConfiguration().onSuccess { remoteConfiguration in
            self.localStorage.offlineMode = remoteConfiguration.offlineMode
            self.requestHandler.offlineMode = remoteConfiguration.offlineMode
            ITBInfo("setting offlineMode: \(self.requestHandler.offlineMode)")
        }.onError { error in
            let offlineMode = self.requestHandler.offlineMode
            ITBError("Could not get remote configuration: \(error.localizedDescription), using saved value: \(offlineMode)")
        }
    }
    
    func getCriteriaData(completion: @escaping (Data) -> Void) {
        apiClient.getCriteria().onSuccess { data in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                completion(jsonData)
            } catch {
                print("Error converting dictionary to data: \(error)")
            }
        }
	}

    private func createDefaultMobileFrameworkInfo() -> IterableAPIMobileFrameworkInfo {
        let frameworkType = IterableAPIMobileFrameworkDetector.frameworkType()
        return IterableAPIMobileFrameworkInfo(
            frameworkType: frameworkType,
            iterableSdkVersion: frameworkType == .native ? localStorage.sdkVersion : nil
        )
    }
    
    deinit {
        ITBInfo()
        notificationCenter.removeObserver(self)
        requestHandler.stop()
    }
    
}


