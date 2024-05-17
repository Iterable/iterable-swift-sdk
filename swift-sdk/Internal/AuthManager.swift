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
        guard !((!shouldIgnoreRetryPolicy && pauseAuthRetry) || (retryCount >= authRetryPolicy.maxRetry && !shouldIgnoreRetryPolicy)) else {
            return
        }
        
        guard !pendingAuth else {
            return
        }
        
        guard !self.hasFailedPriorAuth || !hasFailedPriorAuth else {
            return
        }
        
        self.hasFailedPriorAuth = hasFailedPriorAuth
        
        pendingAuth = true
        
        guard !(isLastAuthTokenValid && !shouldIgnoreRetryPolicy) else {
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
    
    func setNewToken(_ newToken: String) {
        ITBInfo()
        
        onAuthTokenReceived(retrievedAuthToken: newToken)
    }
    
    func logoutUser() {
        ITBInfo()
        
        authToken = nil
        
        storeAuthToken()
        
        reset()
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
    
    private weak var delegate: IterableAuthDelegate?
    private let expirationRefreshPeriod: TimeInterval
    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    
    func pauseAuthRetries(_ pauseAuthRetry: Bool) {
        self.pauseAuthRetry = pauseAuthRetry
        resetRetryCount()
    }
    
    func reset() {
        clearRefreshTimer()
        isLastAuthTokenValid = false
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
        
        queueAuthTokenExpirationRefresh(authToken)
    }
    
    private func onAuthTokenReceived(retrievedAuthToken: String?, onSuccess: AuthTokenRetrievalHandler? = nil) {
        ITBInfo()
        
        pendingAuth = false
        
        guard retrievedAuthToken != nil else {
            delegate?.onTokenRegistrationFailed("auth token was nil, scheduling auth token retrieval in 10 seconds")
            
            /// by default, schedule a refresh for 10s
            scheduleAuthTokenRefreshTimer(interval: getNextRetryInterval())
            
            return
        }
        
        authToken = retrievedAuthToken
        
        storeAuthToken()
        
        queueAuthTokenExpirationRefresh(authToken)
        
        onSuccess?(authToken)
    }
    
    private func queueAuthTokenExpirationRefresh(_ authToken: String?) {
        ITBInfo()
        
        clearRefreshTimer()
        
        guard let authToken = authToken, let expirationDate = AuthManager.decodeExpirationDateFromAuthToken(authToken) else {
            delegate?.onTokenRegistrationFailed("auth token was nil or could not decode an expiration date, scheduling auth token retrieval in 10 seconds")
            
            /// schedule a default timer of 10 seconds if we fall into this case
            scheduleAuthTokenRefreshTimer(interval: getNextRetryInterval())
            
            return
        }
        
        let timeIntervalToRefresh = TimeInterval(expirationDate) - dateProvider.currentDate.timeIntervalSince1970 - expirationRefreshPeriod
        if (timeIntervalToRefresh > 0) {
            print("timeIntervalToRefresh:: \(timeIntervalToRefresh)")
            scheduleAuthTokenRefreshTimer(interval: timeIntervalToRefresh, isScheduledRefresh: true)
        }
    }
    
    func scheduleAuthTokenRefreshTimer(interval: TimeInterval, isScheduledRefresh: Bool = false, successCallback: AuthTokenRetrievalHandler? = nil) {
        ITBInfo()
        guard !((pauseAuthRetry && !isScheduledRefresh) || isTimerScheduled) else {
            // we only stop schedule token refresh if it is called from retry (in case of failure). The normal auth token refresh schedule would work
            return
        }
        
        expirationRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            if self?.localStorage.email != nil || self?.localStorage.userId != nil {
                self?.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: successCallback, shouldIgnoreRetryPolicy: isScheduledRefresh)
            } else {
                ITBDebug("Email or userId is not available. Skipping token refresh")
            }
            self?.isTimerScheduled = false
        }
        isTimerScheduled = true
    }
    
    private func clearRefreshTimer() {
        ITBInfo()
        
        expirationRefreshTimer?.invalidate()
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
