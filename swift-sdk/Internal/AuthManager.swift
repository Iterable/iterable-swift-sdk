//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

class AuthManager: IterableAuthManagerProtocol {
    init(delegate: IterableAuthDelegate?,
         authRetryPolicy: RetryPolicy,
         expirationRefreshPeriod: TimeInterval,
         localStorage: LocalStorageProtocol,
         dateProvider: DateProviderProtocol) {
        ITBInfo()
        
        self.delegate = delegate
        self.authRetryPolicy = authRetryPolicy
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.expirationRefreshPeriod = expirationRefreshPeriod
        
        if self.delegate != nil && (localStorage.email != nil || localStorage.userId != nil) {
            retrieveAuthToken()
        }
    }
    
    deinit {
        ITBInfo()
    }
    
    // MARK: - IterableInternalAuthManagerProtocol
    
    func getAuthToken() -> String? {
        return authToken
    }
    
    func resetFailedAuthCount() {
        hasFailedPriorAuth = false
    }
    
    func requestNewAuthToken(hasFailedPriorAuth: Bool = false,
                             onSuccess: AuthTokenRetrievalHandler? = nil,
                             shouldIgnoreRetryPolicy: Bool) {
        ITBInfo()
        
        if shouldPauseRetry(shouldIgnoreRetryPolicy) || pendingAuth || hasFailedAuth(hasFailedPriorAuth) {
            return
        }
        
        self.hasFailedPriorAuth = hasFailedPriorAuth
        pendingAuth = true
        
        if shouldUseLastValidToken(shouldIgnoreRetryPolicy) {
            // if some JWT retry had valid token it will not fetch the auth token again from developer function
            onAuthTokenReceived(retrievedAuthToken: authToken, onSuccess: onSuccess)
            return
        }
        
        delegate?.onAuthTokenRequested { [weak self] retrievedAuthToken in
            self?.pendingAuth = false
            self?.retryCount+=1
            self?.onAuthTokenReceived(retrievedAuthToken: retrievedAuthToken, onSuccess: onSuccess)
        }
    }
    
    private func hasFailedAuth(_ hasFailedPriorAuth: Bool) -> Bool {
        return self.hasFailedPriorAuth && hasFailedPriorAuth
    }
    
    private func shouldPauseRetry(_ shouldIgnoreRetryPolicy: Bool) -> Bool {
        return (!shouldIgnoreRetryPolicy && pauseAuthRetry) ||
               (retryCount >= authRetryPolicy.maxRetry && !shouldIgnoreRetryPolicy)
    }
    
    private func shouldUseLastValidToken(_ shouldIgnoreRetryPolicy: Bool) -> Bool {
        return isLastAuthTokenValid && !shouldIgnoreRetryPolicy
    }
    
    func setNewToken(_ newToken: String) {
        ITBInfo()
        
        onAuthTokenReceived(retrievedAuthToken: newToken)
    }
    
    func logoutUser() {
        ITBInfo()
        
        authToken = nil
        
        storeAuthToken()
        
        clearRefreshTimer()
        clearPendingCallbacks()
  
        if localStorage.email != nil || localStorage.userId != nil || localStorage.userIdUnknownUser != nil {
            localStorage.unknownUserEvents = nil
            localStorage.unknownUserSessions = nil
            localStorage.unknownUserUpdate = nil
        }

        isLastAuthTokenValid = false
    }
    
    // MARK: - Private/Internal
    
    private var authToken: String?
    private var expirationRefreshTimer: Timer?
    
    private var pendingAuth: Bool = false
    private var hasFailedPriorAuth: Bool = false
    
    private var authRetryPolicy: RetryPolicy
    private var retryCount: Int = 0
    private var isLastAuthTokenValid: Bool = false
    private var pauseAuthRetry: Bool = false
    private var isTimerScheduled: Bool = false
    
    private var pendingSuccessCallbacks: [AuthTokenRetrievalHandler] = []
    private let callbackQueue = DispatchQueue(label: "com.iterable.authCallbackQueue")
    
    private weak var delegate: IterableAuthDelegate?
    private let expirationRefreshPeriod: TimeInterval
    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    
    func pauseAuthRetries(_ pauseAuthRetry: Bool) {
        self.pauseAuthRetry = pauseAuthRetry
        resetRetryCount()
    }
    
    func setIsLastAuthTokenValid(_ isValid: Bool) {
        isLastAuthTokenValid = isValid
    }
    
    func getNextRetryInterval() -> Double {
        var nextRetryInterval = Double(authRetryPolicy.retryInterval)
        if authRetryPolicy.retryBackoff == .exponential {
            nextRetryInterval = Double(nextRetryInterval) * pow(Const.exponentialFactor, Double(retryCount - 1))
        }
        
        return nextRetryInterval
    }
    
    private func resetRetryCount() {
        retryCount = 0
    }
    
    private func storeAuthToken() {
        localStorage.authToken = authToken
    }
    
    private func retrieveAuthToken() {
        ITBInfo()
        
        authToken = localStorage.authToken
        
        _ = queueAuthTokenExpirationRefresh(authToken)
    }
    
    private func onAuthTokenReceived(retrievedAuthToken: String?, onSuccess: AuthTokenRetrievalHandler? = nil) {
        ITBInfo()
        
        pendingAuth = false
        
        // Set the new token first
        authToken = retrievedAuthToken
        storeAuthToken()
        
        if retrievedAuthToken != nil {
            let isRefreshQueued = queueAuthTokenExpirationRefresh(retrievedAuthToken, onSuccess: onSuccess)
            if !isRefreshQueued {
                onSuccess?(authToken)
                authToken = retrievedAuthToken
                storeAuthToken()
            } else {
                authToken = retrievedAuthToken
                storeAuthToken()
                onSuccess?(authToken)
            }
            NotificationCenter.default.post(name: .iterableAuthTokenRefreshed, object: nil)
        } else {
            handleAuthFailure(failedAuthToken: nil, reason: .authTokenNull)
            scheduleAuthTokenRefreshTimer(interval: getNextRetryInterval(), successCallback: onSuccess)
            authToken = retrievedAuthToken
            storeAuthToken()
        }
    }
    
    func handleAuthFailure(failedAuthToken: String?, reason: AuthFailureReason) {
        delegate?.onAuthFailure(AuthFailure(userKey: IterableUtil.getEmailOrUserId(), failedAuthToken: failedAuthToken, failedRequestTime: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate), failureReason: reason))
    }
    
    private func queueAuthTokenExpirationRefresh(_ authToken: String?, onSuccess: AuthTokenRetrievalHandler? = nil) -> Bool {
        ITBInfo()
        
        clearRefreshTimer()
        
        guard let authToken = authToken, let expirationDate = AuthManager.decodeExpirationDateFromAuthToken(authToken) else {
            handleAuthFailure(failedAuthToken: authToken, reason: .authTokenPayloadInvalid)
            
            /// schedule a default timer of 10 seconds if we fall into this case
            scheduleAuthTokenRefreshTimer(interval: getNextRetryInterval(), successCallback: onSuccess)
            
            return false  // Return false since we couldn't queue a valid refresh
        }
        
        let timeIntervalToRefresh = TimeInterval(expirationDate) - dateProvider.currentDate.timeIntervalSince1970 - expirationRefreshPeriod
        if timeIntervalToRefresh > 0 {
            scheduleAuthTokenRefreshTimer(interval: timeIntervalToRefresh, isScheduledRefresh: true, successCallback: onSuccess)
            return true  // Only return true when we successfully queue a refresh
        }
        return false
    }
    
    func scheduleAuthTokenRefreshTimer(interval: TimeInterval, isScheduledRefresh: Bool = false, successCallback: AuthTokenRetrievalHandler? = nil) {
        ITBInfo()
        
        // If timer is already scheduled, queue the callback for later invocation
        if isTimerScheduled && !isScheduledRefresh {
            addPendingCallback(successCallback)
            return
        }
        
        if shouldSkipTokenRefresh(isScheduledRefresh: isScheduledRefresh) {
            // we only stop schedule token refresh if it is called from retry (in case of failure). The normal auth token refresh schedule would work
            return
        }
        
        // Add the initial callback to pending list
        addPendingCallback(successCallback)
        
        expirationRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.isTimerScheduled = false
            if self?.localStorage.email != nil || self?.localStorage.userId != nil {
                self?.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: { [weak self] token in
                    self?.invokePendingCallbacks(with: token)
                }, shouldIgnoreRetryPolicy: isScheduledRefresh)
            } else {
                ITBDebug("Email or userId is not available. Skipping token refresh")
                self?.clearPendingCallbacks()
            }
        }
        
        isTimerScheduled = true
    }
    
    private func shouldSkipTokenRefresh(isScheduledRefresh: Bool) -> Bool {
        return (pauseAuthRetry && !isScheduledRefresh) || isTimerScheduled
    }
    
    // MARK: - Pending Callbacks Management
    
    private func addPendingCallback(_ callback: AuthTokenRetrievalHandler?) {
        guard let callback = callback else { return }
        callbackQueue.sync {
            pendingSuccessCallbacks.append(callback)
        }
    }
    
    private func invokePendingCallbacks(with token: String?) {
        let callbacks = callbackQueue.sync { () -> [AuthTokenRetrievalHandler] in
            let current = pendingSuccessCallbacks
            pendingSuccessCallbacks.removeAll()
            return current
        }
        callbacks.forEach { $0(token) }
    }
    
    private func clearPendingCallbacks() {
        callbackQueue.sync {
            pendingSuccessCallbacks.removeAll()
        }
    }
    
    private func clearRefreshTimer() {
        ITBInfo()
        
        expirationRefreshTimer?.invalidate()
        isTimerScheduled = false
        expirationRefreshTimer = nil
    }
    
    static func decodeExpirationDateFromAuthToken(_ authToken: String) -> Int? {
        let components = authToken.components(separatedBy: ".")
        
        guard components.count > 1 else {
            return nil
        }
        
        let encodedPayload = components[1]
        
        let remaining = encodedPayload.count % 4
        let fixedEncodedPayload = encodedPayload + String(repeating: "=", count: (4 - remaining) % 4)
        
        guard let decoded = Data(base64Encoded: fixedEncodedPayload),
            let serialized = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any],
            let payloadExpTime = serialized[JsonKey.JWT.exp] as? Int else {
            return nil
        }
        
        return payloadExpTime
    }
}
