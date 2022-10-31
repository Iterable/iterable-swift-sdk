//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

/// Basic wrapper for keychain
/// This should have no dependency on Iterable classes
class KeychainWrapper {
    init(serviceName: String = Const.Keychain.serviceName) {
        self.serviceName = serviceName
    }
    
    @discardableResult
    func set(_ value: Data, forKey key: String) -> Bool {
        var keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key)
        
        keychainQueryDictionary[SecValueData] = value
        
        // Assign default protection - Protect the keychain entry so it's only valid when the device is unlocked
        keychainQueryDictionary[SecAttrAccessible] = SecAttrAccessibleWhenUnlocked
        
        let status: OSStatus = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return update(value, forKey: key)
        } else {
            return false
        }
    }
    
    func data(forKey key: String) -> Data? {
        var keychainQueryDictionary = setupKeychainQueryDictionary(forKey: key)
        
        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = SecMatchLimitOne
        
        // Specify we want Data/CFData returned
        keychainQueryDictionary[SecReturnData] = CFBooleanTrue
        
        // Search
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &result)
        
        return status == noErr ? result as? Data : nil
    }
    
    @discardableResult
    func removeValue(forKey key: String) -> Bool {
        let keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key)
        
        // Delete
        let status: OSStatus = SecItemDelete(keychainQueryDictionary as CFDictionary)
        
        return status == errSecSuccess
    }
    
    @discardableResult
    func removeAll() -> Bool {
        var keychainQueryDictionary: [String: Any] = [SecClass: SecClassGenericPassword]
        
        keychainQueryDictionary[SecAttrService] = serviceName
        
        let status: OSStatus = SecItemDelete(keychainQueryDictionary as CFDictionary)
        
        return status == errSecSuccess
    }
    
    // MARK: - PRIVATE/INTERNAL
    
    private func setupKeychainQueryDictionary(forKey key: String) -> [String: Any] {
        // Setup default access as generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: [String: Any] = [SecClass: SecClassGenericPassword]
        
        // Uniquely identify this keychain accessor
        keychainQueryDictionary[SecAttrService] = serviceName
        
        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: Data? = key.data(using: .utf8)
        
        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifier
        
        keychainQueryDictionary[SecAttrAccount] = encodedIdentifier
        
        keychainQueryDictionary[SecAttrSynchronizable] = CFBooleanFalse
        
        return keychainQueryDictionary
    }
    
    private func update(_ value: Data, forKey key: String) -> Bool {
        let keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key)
        let updateDictionary = [SecValueData: value]
        
        // Update
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)
        
        return status == errSecSuccess
    }
    
    private let serviceName: String
    private let SecValueData = kSecValueData as String
    private let SecAttrAccessible: String = kSecAttrAccessible as String
    private let SecAttrAccessibleWhenUnlocked = kSecAttrAccessibleWhenUnlocked
    private let SecClass: String = kSecClass as String
    private let SecClassGenericPassword = kSecClassGenericPassword
    private let SecAttrService: String = kSecAttrService as String
    private let SecAttrGeneric: String = kSecAttrGeneric as String
    private let SecAttrAccount: String = kSecAttrAccount as String
    private let SecAttrSynchronizable: String = kSecAttrSynchronizable as String
    private let CFBooleanTrue = kCFBooleanTrue
    private let CFBooleanFalse = kCFBooleanFalse
    private let SecMatchLimit: String = kSecMatchLimit as String
    private let SecMatchLimitOne = kSecMatchLimitOne
    private let SecReturnData: String = kSecReturnData as String
}
