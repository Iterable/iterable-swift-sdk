//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

/// This is Iterable encapsulation around UserDefaults
class IterableUserDefaults {
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    // migrated to IterableKeychain
    var userId: String? {
        get {
            string(withKey: .userId)
        } set {
            save(string: newValue, withKey: .userId)
        }
    }
    
    // migrated to IterableKeychain
    var email: String? {
        get {
            string(withKey: .email)
        } set {
            save(string: newValue, withKey: .email)
        }
    }
    
    // migrated to IterableKeychain
    var authToken: String? {
        get {
            string(withKey: .authToken)
        } set {
            save(string: newValue, withKey: .authToken)
        }
    }
    
    // deprecated, not in use anymore
    var ddlChecked: Bool {
        get {
            bool(withKey: .ddlChecked)
        } set {
            save(bool: newValue, withKey: .ddlChecked)
        }
    }
    
    var deviceId: String? {
        get {
            string(withKey: .deviceId)
        } set {
            save(string: newValue, withKey: .deviceId)
        }
    }
    
    var sdkVersion: String? {
        get {
            string(withKey: .sdkVersion)
        } set {
            save(string: newValue, withKey: .sdkVersion)
        }
    }
    
    var offlineMode: Bool {
        get {
            bool(withKey: .offlineMode)
        } set {
            save(bool: newValue, withKey: .offlineMode)
        }
    }
    
    var isNotificationsEnabled: Bool {
        get {
            bool(withKey: .isNotificationsEnabled)
        } set {
            save(bool: newValue, withKey: .isNotificationsEnabled)
        }
    }
    
    var hasStoredNotificationSetting: Bool {
        get {
            bool(withKey: .hasStoredNotificationSetting)
        } set {
            save(bool: newValue, withKey: .hasStoredNotificationSetting)
        }
    }
    
    func getAttributionInfo(currentDate: Date) -> IterableAttributionInfo? {
        (try? codable(withKey: .attributionInfo, currentDate: currentDate)) ?? nil
    }
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?) {
        try? save(codable: attributionInfo, withKey: .attributionInfo, andExpiration: expiration)
    }
    
    
    // MARK: data migration functions
    
    func getAuthDataForMigration() -> (email: String?, userId: String?, authToken: String?) {
        return (email: email, userId: userId, authToken: authToken)
    }
    
    // MARK: Private implementation
    
    private let userDefaults: UserDefaults
    
    private func dict(withKey key: UserDefaultsKey, currentDate: Date) throws -> [AnyHashable: Any]? {
        guard let encodedEnvelope = userDefaults.value(forKey: key.value) as? Data else {
            return nil
        }
        
        let envelope = try JSONDecoder().decode(Envelope.self, from: encodedEnvelope)
        let decoded = try JSONSerialization.jsonObject(with: envelope.payload, options: []) as? [AnyHashable: Any]
        
        if Self.isExpired(expiration: envelope.expiration, currentDate: currentDate) {
            return nil
        } else {
            return decoded
        }
    }
    
    private func codable<T: Codable>(withKey key: UserDefaultsKey, currentDate: Date) throws -> T? {
        guard let encodedEnvelope = userDefaults.value(forKey: key.value) as? Data else {
            return nil
        }
        
        let envelope = try JSONDecoder().decode(Envelope.self, from: encodedEnvelope)
        
        let decoded = try JSONDecoder().decode(T.self, from: envelope.payload)
        
        if Self.isExpired(expiration: envelope.expiration, currentDate: currentDate) {
            return nil
        } else {
            return decoded
        }
    }
    
    private func string(withKey key: UserDefaultsKey) -> String? {
        userDefaults.string(forKey: key.value)
    }
    
    private func bool(withKey key: UserDefaultsKey) -> Bool {
        userDefaults.bool(forKey: key.value)
    }
    
    private static func isExpired(expiration: Date?, currentDate: Date) -> Bool {
        if let expiration = expiration {
            if expiration.timeIntervalSinceReferenceDate > currentDate.timeIntervalSinceReferenceDate {
                // expiration is later
                return false
            } else {
                // expired
                return true
            }
        } else {
            // no expiration
            return false
        }
    }
    
    private func save<T: Codable>(codable: T?, withKey key: UserDefaultsKey, andExpiration expiration: Date? = nil) throws {
        if let value = codable {
            let data = try JSONEncoder().encode(value)
            try save(data: data, withKey: key, andExpiration: expiration)
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    private func save(dict: [AnyHashable: Any]?, withKey key: UserDefaultsKey, andExpiration expiration: Date? = nil) throws {
        if let value = dict {
            if JSONSerialization.isValidJSONObject(value) {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                try save(data: data, withKey: key, andExpiration: expiration)
            }
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    private func save(string: String?, withKey key: UserDefaultsKey) {
        userDefaults.set(string, forKey: key.value)
    }
    
    private func save(bool: Bool, withKey key: UserDefaultsKey) {
        userDefaults.set(bool, forKey: key.value)
    }
    
    private func save(data: Data?, withKey key: UserDefaultsKey, andExpiration expiration: Date?) throws {
        guard let data = data else {
            userDefaults.removeObject(forKey: key.value)
            return
        }
        
        let envelope = Envelope(payload: data, expiration: expiration)
        let encodedEnvelope = try JSONEncoder().encode(envelope)
        userDefaults.set(encodedEnvelope, forKey: key.value)
    }
    
    private struct UserDefaultsKey {
        let value: String
        
        private init(value: String) {
            self.value = value
        }
        static let attributionInfo = UserDefaultsKey(value: Const.UserDefault.attributionInfoKey)
        static let email = UserDefaultsKey(value: Const.UserDefault.emailKey)
        static let userId = UserDefaultsKey(value: Const.UserDefault.userIdKey)
        static let authToken = UserDefaultsKey(value: Const.UserDefault.authTokenKey)
        static let ddlChecked = UserDefaultsKey(value: Const.UserDefault.ddlChecked)
        static let deviceId = UserDefaultsKey(value: Const.UserDefault.deviceId)
        static let sdkVersion = UserDefaultsKey(value: Const.UserDefault.sdkVersion)
        static let offlineMode = UserDefaultsKey(value: Const.UserDefault.offlineMode)
        static let isNotificationsEnabled = UserDefaultsKey(value: Const.UserDefault.isNotificationsEnabled)
        static let hasStoredNotificationSetting = UserDefaultsKey(value: Const.UserDefault.hasStoredNotificationSetting)
    }
    
    private struct Envelope: Codable {
        let payload: Data
        let expiration: Date?
    }
}
