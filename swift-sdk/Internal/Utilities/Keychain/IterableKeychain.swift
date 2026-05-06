//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

class IterableKeychain {
    init(wrapper: KeychainWrapper = KeychainWrapper(),
         legacyWrapper: KeychainWrapper? = nil) {
        self.wrapper = wrapper
        self.legacyWrapper = legacyWrapper
    }

    /// Migrates keychain data from legacy storage to isolated storage
    /// This is needed when upgrading from older SDK versions that used a shared service name
    /// - Returns: true if migration was performed, false otherwise
    @discardableResult
    func migrateFromLegacy() -> Bool {
        guard let legacyWrapper = legacyWrapper else {
            return false
        }

        var migrated = false

        // Migrate email if isolated keychain is empty and legacy has data
        if email == nil, let legacyEmail = getString(forKey: Const.Keychain.Key.email, from: legacyWrapper) {
            email = legacyEmail
            legacyWrapper.removeValue(forKey: Const.Keychain.Key.email)
            ITBInfo("UPDATED: migrated email from legacy keychain to isolated keychain")
            migrated = true
        }

        // Migrate userId if isolated keychain is empty and legacy has data
        if userId == nil, let legacyUserId = getString(forKey: Const.Keychain.Key.userId, from: legacyWrapper) {
            userId = legacyUserId
            legacyWrapper.removeValue(forKey: Const.Keychain.Key.userId)
            ITBInfo("UPDATED: migrated userId from legacy keychain to isolated keychain")
            migrated = true
        }

        // Migrate userIdUnknownUser if isolated keychain is empty and legacy has data
        if userIdUnknownUser == nil, let legacyUserIdUnknownUser = getString(forKey: Const.Keychain.Key.userIdUnknownUser, from: legacyWrapper) {
            userIdUnknownUser = legacyUserIdUnknownUser
            legacyWrapper.removeValue(forKey: Const.Keychain.Key.userIdUnknownUser)
            ITBInfo("UPDATED: migrated userIdUnknownUser from legacy keychain to isolated keychain")
            migrated = true
        }

        // Migrate authToken if isolated keychain is empty and legacy has data
        if authToken == nil, let legacyAuthToken = getString(forKey: Const.Keychain.Key.authToken, from: legacyWrapper) {
            authToken = legacyAuthToken
            legacyWrapper.removeValue(forKey: Const.Keychain.Key.authToken)
            ITBInfo("UPDATED: migrated authToken from legacy keychain to isolated keychain")
            migrated = true
        }

        return migrated
    }

    /// Helper to get string from a specific wrapper
    private func getString(forKey key: String, from wrapper: KeychainWrapper) -> String? {
        let data = wrapper.data(forKey: key)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }
    
    var email: String? {
        get {
            let data = wrapper.data(forKey: Const.Keychain.Key.email)
            
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }
        
        set {
            guard let token = newValue,
                  let data = token.data(using: .utf8) else {
                wrapper.removeValue(forKey: Const.Keychain.Key.email)
                return
            }
            
            wrapper.set(data, forKey: Const.Keychain.Key.email)
        }
    }
    
    var userId: String? {
        get {
            let data = wrapper.data(forKey: Const.Keychain.Key.userId)
            
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }
        
        set {
            guard let token = newValue,
                  let data = token.data(using: .utf8) else {
                wrapper.removeValue(forKey: Const.Keychain.Key.userId)
                return
            }
            
            wrapper.set(data, forKey: Const.Keychain.Key.userId)
        }
    }
    
    var userIdUnknownUser: String? {
        get {
            let data = wrapper.data(forKey: Const.Keychain.Key.userIdUnknownUser)
            
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }
        
        set {
            guard let token = newValue,
                  let data = token.data(using: .utf8) else {
                wrapper.removeValue(forKey: Const.Keychain.Key.userIdUnknownUser)
                return
            }
            
            wrapper.set(data, forKey: Const.Keychain.Key.userIdUnknownUser)
        }
    }
    
    var authToken: String? {
        get {
            let data = wrapper.data(forKey: Const.Keychain.Key.authToken)
            
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }
        
        set {
            guard let token = newValue,
                  let data = token.data(using: .utf8) else {
                wrapper.removeValue(forKey: Const.Keychain.Key.authToken)
                return
            }
            
            wrapper.set(data, forKey: Const.Keychain.Key.authToken)
        }
    }
    
    // MARK: - PRIVATE/INTERNAL

    private let wrapper: KeychainWrapper
    private let legacyWrapper: KeychainWrapper?
    
    private func encodeJsonPayload(_ json: [AnyHashable: Any]?) -> Data? {
        guard let json = json, JSONSerialization.isValidJSONObject(json) else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    private func decodeJsonPayload(_ data: Data?) -> [AnyHashable: Any]? {
        guard let data = data else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any]
    }
    
}
