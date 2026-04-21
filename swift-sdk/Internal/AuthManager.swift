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
                             onRetryExhausted: (() -> Void)? = nil,
                             shouldIgnoreRetryPolicy: Bool) {
        ITBInfo()
        
        if shouldPauseRetry(shouldIgnoreRetryPolicy) {
            addPendingExhaustionCallback(onRetryExhausted)
            invokePendingExhaustionCallbacks()
            return
        }

        if pendingAuth {
            // In-flight auth is already running; piggyback so the current resolution drains us.
            addPendingCallback(onSuccess)
            addPendingExhaustionCallback(onRetryExhausted)
            return
        }

        if hasFailedAuth(hasFailedPriorAuth) {
            addPendingExhaustionCallback(onRetryExhausted)
            invokePendingExhaustionCallbacks()
            return
        }
        
        self.hasFailedPriorAuth = hasFailedPriorAuth
        pendingAuth = true
        
        if shouldUseLastValidToken(shouldIgnoreRetryPolicy) {
            // if some JWT retry had valid token it will not fetch the auth token again from developer function
            onAuthTokenReceived(retrievedAuthToken: authToken, onSuccess: onSuccess, onRetryExhausted: onRetryExhausted)
            return
        }
        
        delegate?.onAuthTokenRequested { [weak self] retrievedAuthToken in
            self?.pendingAuth = false
            self?.retryCount+=1
            self?.onAuthTokenReceived(retrievedAuthToken: retrievedAuthToken, onSuccess: onSuccess, onRetryExhausted: onRetryExhausted)
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
        return lastAuthTokenState == .valid && !shouldIgnoreRetryPolicy
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
        // Resolve any upstream Fulfills instead of orphaning them.
        invokePendingExhaustionCallbacks()
  
        if localStorage.email != nil || localStorage.userId != nil || localStorage.userIdUnknownUser != nil {
            localStorage.unknownUserEvents = nil
            localStorage.unknownUserSessions = nil
            localStorage.unknownUserUpdate = nil
        }

        lastAuthTokenState = .unknown
    }

    // MARK: - Private/Internal
    
    private var authToken: String?
    private var expirationRefreshTimer: Timer?
    
    private var pendingAuth: Bool = false
    private var hasFailedPriorAuth: Bool = false
    
    private var authRetryPolicy: RetryPolicy
    private var retryCount: Int = 0
    private var lastAuthTokenState: AuthTokenValidityState = .unknown {
        didSet {
            guard lastAuthTokenState != oldValue else { return }
            NotificationCenter.default.post(
                name: .iterableAuthTokenStateChanged,
                object: nil,
                userInfo: ["state": lastAuthTokenState.rawValue]
            )
        }
    }
    private var pauseAuthRetry: Bool = false
    private var isTimerScheduled: Bool = false
    
    private var pendingSuccessCallbacks: [AuthTokenRetrievalHandler] = []
    private var pendingExhaustionCallbacks: [() -> Void] = []
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
        if isValid {
            let wasNotValid = lastAuthTokenState != .valid
            lastAuthTokenState = .valid
            if wasNotValid {
                NotificationCenter.default.post(name: .iterableAuthTokenRefreshed, object: nil)
            }
        } else {
            // Only transition to .invalid from .valid.
            // When state is .unknown (token just refreshed, awaiting validation),
            // keep it as .unknown — the next successful request will set .valid.
            if lastAuthTokenState == .valid {
                lastAuthTokenState = .invalid
            }
        }
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
    
    /// Resolves a completed auth token fetch.
    ///
    /// Success path ordering is deliberate:
    /// 1. Drain piggybacked `pendingAuth` waiters with the new token (via `invokePendingCallbacks`)
    ///    before step 2 re-enqueues `onSuccess` for the scheduled refresh cycle — otherwise the
    ///    direct caller's `onSuccess` would fire twice.
    /// 2. Queue the next expiration refresh (`queueAuthTokenExpirationRefresh`), which may enqueue
    ///    `onSuccess`/`onRetryExhausted` against the future timer.
    /// 3. Fire the direct caller's `onSuccess` with the resolved token.
    ///
    /// Failure path (nil token): report auth failure, then schedule a retry timer carrying
    /// `onSuccess`/`onRetryExhausted` forward.
    private func onAuthTokenReceived(retrievedAuthToken: String?, onSuccess: AuthTokenRetrievalHandler? = nil, onRetryExhausted: (() -> Void)? = nil) {
        ITBInfo()

        pendingAuth = false

        // Set the new token first
        authToken = retrievedAuthToken
        storeAuthToken()

        if let resolvedToken = retrievedAuthToken {
            // Only transition to .unknown from .invalid (auth recovery).
            // When state is .valid (normal scheduled refresh), keep it .valid.
            if lastAuthTokenState == .invalid {
                lastAuthTokenState = .unknown
            }
            // Drain pendingAuth waiters before queueAuthTokenExpirationRefresh re-enqueues `onSuccess`
            // for the future refresh cycle; otherwise direct + drain would double-fire it.
            invokePendingCallbacks(with: resolvedToken)
            let isRefreshQueued = queueAuthTokenExpirationRefresh(retrievedAuthToken, onSuccess: onSuccess, onRetryExhausted: onRetryExhausted)
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
            scheduleAuthTokenRefreshTimer(interval: getNextRetryInterval(), successCallback: onSuccess, onRetryExhausted: onRetryExhausted)
            authToken = retrievedAuthToken
            storeAuthToken()
        }
    }
    
    func handleAuthFailure(failedAuthToken: String?, reason: AuthFailureReason) {
        delegate?.onAuthFailure(AuthFailure(userKey: IterableUtil.getEmailOrUserId(), failedAuthToken: failedAuthToken, failedRequestTime: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate), failureReason: reason))
    }
    
    private func queueAuthTokenExpirationRefresh(_ authToken: String?, onSuccess: AuthTokenRetrievalHandler? = nil, onRetryExhausted: (() -> Void)? = nil) -> Bool {
        ITBInfo()
        
        clearRefreshTimer()
        
        guard let authToken = authToken, let expirationDate = AuthManager.decodeExpirationDateFromAuthToken(authToken) else {
            handleAuthFailure(failedAuthToken: authToken, reason: .authTokenPayloadInvalid)
            
            /// schedule a default timer of 10 seconds if we fall into this case
            scheduleAuthTokenRefreshTimer(interval: getNextRetryInterval(), successCallback: onSuccess, onRetryExhausted: onRetryExhausted)
            
            return false  // Return false since we couldn't queue a valid refresh
        }
        
        let timeIntervalToRefresh = TimeInterval(expirationDate) - dateProvider.currentDate.timeIntervalSince1970 - expirationRefreshPeriod
        if timeIntervalToRefresh > 0 {
            scheduleAuthTokenRefreshTimer(interval: timeIntervalToRefresh, isScheduledRefresh: true, successCallback: onSuccess, onRetryExhausted: onRetryExhausted)
            return true  // Only return true when we successfully queue a refresh
        }
        return false
    }
    
    func scheduleAuthTokenRefreshTimer(interval: TimeInterval, isScheduledRefresh: Bool = false, successCallback: AuthTokenRetrievalHandler? = nil, onRetryExhausted: (() -> Void)? = nil) {
        ITBInfo()
        
        // If timer is already scheduled, queue the callback for later invocation
        if isTimerScheduled && !isScheduledRefresh {
            addPendingCallback(successCallback)
            addPendingExhaustionCallback(onRetryExhausted)
            return
        }
        
        if shouldSkipTokenRefresh(isScheduledRefresh: isScheduledRefresh) {
            onRetryExhausted?()
            return
        }
        
        // Add the initial callbacks to pending lists
        addPendingCallback(successCallback)
        addPendingExhaustionCallback(onRetryExhausted)
        
        expirationRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            if self?.localStorage.email != nil || self?.localStorage.userId != nil {
                self?.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: { [weak self] token in
                    if let token = token {
                        self?.invokePendingCallbacks(with: token)
                    } else {
                        self?.invokePendingExhaustionCallbacks()
                    }
                }, shouldIgnoreRetryPolicy: isScheduledRefresh)
                self?.isTimerScheduled = false
            } else {
                ITBDebug("Email or userId is not available. Skipping token refresh")
                self?.isTimerScheduled = false
                self?.invokePendingExhaustionCallbacks()
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
    
    private func invokePendingCallbacks(with token: String) {
        drainCallbacks().success.forEach { $0(token) }
    }
    
    private func addPendingExhaustionCallback(_ callback: (() -> Void)?) {
        guard let callback = callback else { return }
        callbackQueue.sync {
            pendingExhaustionCallbacks.append(callback)
        }
    }
    
    private func invokePendingExhaustionCallbacks() {
        drainCallbacks().exhaustion.forEach { $0() }
    }
    
    /// Atomically drains both queues. Success and exhaustion are mutually exclusive:
    /// invoking either one clears the other, so pending waiters only fire once.
    private func drainCallbacks() -> (success: [AuthTokenRetrievalHandler], exhaustion: [() -> Void]) {
        return callbackQueue.sync {
            let success = pendingSuccessCallbacks
            let exhaustion = pendingExhaustionCallbacks
            pendingSuccessCallbacks.removeAll()
            pendingExhaustionCallbacks.removeAll()
            return (success, exhaustion)
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
