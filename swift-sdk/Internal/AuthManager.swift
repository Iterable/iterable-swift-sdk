//
//  Created by Jay Kim on 9/3/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableInternalAuthManagerProtocol {
    func getAuthToken() -> String?
    func resetFailedAuthCount()
    func requestNewAuthToken(hasFailedPriorAuth: Bool, onSuccess: ((String?) -> Void)?)
    func logoutUser()
}

class AuthManager: IterableInternalAuthManagerProtocol {
    init(delegate: IterableAuthDelegate?,
         expirationRefreshPeriod: TimeInterval,
         localStorage: LocalStorageProtocol,
         dateProvider: DateProviderProtocol) {
        ITBInfo()
        
        self.delegate = delegate
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.expirationRefreshPeriod = expirationRefreshPeriod
        
        retrieveAuthToken()
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
    
    // @objc attribute only needed for the pre-iOS 10 Timer constructor in queueAuthTokenExpirationRefresh
    @objc func requestNewAuthToken(hasFailedPriorAuth: Bool = false, onSuccess: AuthTokenRetrievalHandler? = nil) {
        ITBInfo()
        
        guard !pendingAuth else {
            return
        }
        
        guard !self.hasFailedPriorAuth || !hasFailedPriorAuth else {
            return
        }
        
        self.hasFailedPriorAuth = hasFailedPriorAuth
        
        pendingAuth = true
        
        delegate?.onAuthTokenRequested { [weak self] retrievedAuthToken in
            self?.onAuthTokenReceived(retrievedAuthToken: retrievedAuthToken, onSuccess: onSuccess)
        }
    }
    
    func logoutUser() {
        ITBInfo()
        
        authToken = nil
        
        storeAuthToken()
        
        clearRefreshTimer()
    }
    
    // MARK: - Private/Internal
    
    private var authToken: String?
    private var expirationRefreshTimer: Timer?
    
    private var pendingAuth: Bool = false
    private var hasFailedPriorAuth: Bool = false
    
    private weak var delegate: IterableAuthDelegate?
    private let expirationRefreshPeriod: TimeInterval
    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    
    private func storeAuthToken() {
        localStorage.authToken = authToken
    }
    
    private func retrieveAuthToken() {
        authToken = localStorage.authToken
        
        queueAuthTokenExpirationRefresh(authToken)
    }
    
    private func onAuthTokenReceived(retrievedAuthToken: String?, onSuccess: AuthTokenRetrievalHandler?) {
        pendingAuth = false
        
        authToken = retrievedAuthToken
        
        storeAuthToken()
        
        if authToken != nil {
            onSuccess?(authToken)
        }
        
        queueAuthTokenExpirationRefresh(authToken)
    }
    
    private func queueAuthTokenExpirationRefresh(_ authToken: String?) {
        ITBInfo()
        
        guard let authToken = authToken, let expirationDate = AuthManager.decodeExpirationDateFromAuthToken(authToken) else {
            return
        }
        
        let timeIntervalToRefresh = TimeInterval(expirationDate) - dateProvider.currentDate.timeIntervalSince1970 - expirationRefreshPeriod
        
        if #available(iOS 10.0, *) {
            expirationRefreshTimer = Timer.scheduledTimer(withTimeInterval: timeIntervalToRefresh, repeats: false) { [weak self] _ in
                self?.requestNewAuthToken(hasFailedPriorAuth: false)
            }
        } else {
            // Fallback on earlier versions
            expirationRefreshTimer = Timer.scheduledTimer(timeInterval: timeIntervalToRefresh,
                                                          target: self,
                                                          selector: #selector(requestNewAuthToken),
                                                          userInfo: nil,
                                                          repeats: false)
        }
    }
    
    private func clearRefreshTimer() {
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
