//
//  Created by Jay Kim on 9/3/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@objc public protocol IterableInternalAuthManagerProtocol {
    func getAuthToken() -> String?
    func requestNewAuthToken()
    func logoutUser()
}

class AuthManager: IterableInternalAuthManagerProtocol {
    init(onAuthTokenRequestedCallback: (() -> String?)?, localStorage: LocalStorageProtocol) {
        ITBInfo()
        
        self.onAuthTokenRequestedCallback = onAuthTokenRequestedCallback
        self.localStorage = localStorage
        
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
    @objc func requestNewAuthToken() {
        authToken = onAuthTokenRequestedCallback?()
        
        storeAuthToken()
        
        queueAuthTokenExpirationRefresh(authToken)
    }
    
    func logoutUser() {
        authToken = nil
        
        storeAuthToken()
        
        expirationRefreshTimer?.invalidate()
    }
    
    // MARK: - Auth Manager Functions
    
    func storeAuthToken() {
        localStorage.authToken = authToken
    }
    
    func retrieveAuthToken() {
        authToken = localStorage.authToken
        
        queueAuthTokenExpirationRefresh(authToken)
    }
    
    // MARK: - Private/Internal
    
    private static let refreshWindow = 60
    
    private var expirationRefreshTimer: Timer?
    
    private var authToken: String?
    
    private var localStorage: LocalStorageProtocol
    
    private let onAuthTokenRequestedCallback: (() -> String?)?
    
    private func queueAuthTokenExpirationRefresh(_ authToken: String?) {
        guard let authToken = authToken, let expirationDate = AuthManager.decodeExpirationDateFromAuthToken(authToken) else {
            return
        }
        
        let refreshDate = TimeInterval(expirationDate - AuthManager.refreshWindow)
        
        if #available(iOS 10.0, *) {
            expirationRefreshTimer = Timer.scheduledTimer(withTimeInterval: refreshDate, repeats: false) { timer in
                self.requestNewAuthToken()
            }
        } else {
            // Fallback on earlier versions
            expirationRefreshTimer = Timer.scheduledTimer(timeInterval: refreshDate,
                                                          target: self,
                                                          selector: #selector(requestNewAuthToken),
                                                          userInfo: nil,
                                                          repeats: false)
        }
    }
    
    private static func decodeExpirationDateFromAuthToken(_ authToken: String) -> Int? {
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
