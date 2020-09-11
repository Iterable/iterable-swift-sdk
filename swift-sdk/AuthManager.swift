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
    
    func requestNewAuthToken() {
        authToken = onAuthTokenRequestedCallback?()
        
        storeAuthToken()
    }
    
    func logoutUser() {
        authToken = nil
        
        storeAuthToken()
    }
    
    // MARK: - Auth Manager Functions
    
    func storeAuthToken() {
        localStorage.authToken = authToken
    }
    
    func retrieveAuthToken() {
        authToken = localStorage.authToken
    }
    
    // MARK: - Private/Internal
    
    private var authToken: String?
    
    private var localStorage: LocalStorageProtocol
    
    private let onAuthTokenRequestedCallback: (() -> String?)?
    
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
