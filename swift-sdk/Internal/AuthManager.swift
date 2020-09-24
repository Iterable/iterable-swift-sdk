//
//  Created by Jay Kim on 9/3/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableInternalAuthManagerProtocol {
    func getAuthToken() -> String?
    func requestNewAuthToken(hasFailedPriorAuth: Bool, onSuccess: (() -> Void)?)
    func logoutUser()
}

class AuthManager: IterableInternalAuthManagerProtocol {
    init(delegate: IterableAuthDelegate?,
         refreshWindow: TimeInterval,
         localStorage: LocalStorageProtocol,
         dateProvider: DateProviderProtocol) {
        ITBInfo()
        
        self.delegate = delegate
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.refreshWindow = refreshWindow
        
        retrieveAuthToken()
    }
    
    deinit {
        ITBInfo()
    }
    
    // MARK: - IterableInternalAuthManagerProtocol
    
    func getAuthToken() -> String? {
        return authToken
    }
    
    // @objc attribute only needed for the pre-iOS 10 Timer constructor in queueAuthTokenExpirationRefresh
    @objc func requestNewAuthToken(hasFailedPriorAuth: Bool = false, onSuccess: (() -> Void)? = nil) {
        guard !self.hasFailedPriorAuth || !hasFailedPriorAuth else {
            return
        }
        
        self.hasFailedPriorAuth = hasFailedPriorAuth
        
        delegate?.onAuthTokenRequested(completion: { retrievedAuthToken in
            self.authToken = retrievedAuthToken
            
            self.storeAuthToken()
            
            if self.authToken != nil {
                onSuccess?()
            }
            
            self.queueAuthTokenExpirationRefresh(self.authToken)
        })
    }
    
    func logoutUser() {
        authToken = nil
        
        storeAuthToken()
        
        expirationRefreshTimer?.invalidate()
        expirationRefreshTimer = nil
    }
    
    // MARK: - Private/Internal
    
    private var expirationRefreshTimer: Timer?
    
    private var authToken: String?
    
    private var hasFailedPriorAuth: Bool = false
    
    private weak var delegate: IterableAuthDelegate?
    private let refreshWindow: TimeInterval
    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol

    private func storeAuthToken() {
        localStorage.authToken = authToken
    }
    
    private func retrieveAuthToken() {
        authToken = localStorage.authToken
        
        queueAuthTokenExpirationRefresh(authToken)
    }
    
    private func queueAuthTokenExpirationRefresh(_ authToken: String?) {
        guard let authToken = authToken, let expirationDate = AuthManager.decodeExpirationDateFromAuthToken(authToken) else {
            return
        }
        
        let timeIntervalToRefresh = TimeInterval(expirationDate) - dateProvider.currentDate.timeIntervalSince1970 - refreshWindow
        
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
