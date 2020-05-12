//
//  Created by Tapash Majumder on 8/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct UserDefaultsLocalStorage: LocalStorageProtocol {
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    var userId: String? {
        get {
            return string(withKey: .userId)
        } set {
            save(string: newValue, withKey: .userId)
        }
    }
    
    var email: String? {
        get {
            return string(withKey: .email)
        } set {
            save(string: newValue, withKey: .email)
        }
    }
    
    var ddlChecked: Bool {
        get {
            return bool(withKey: .ddlChecked)
        } set {
            save(bool: newValue, withKey: .ddlChecked)
        }
    }
    
    var deviceId: String? {
        get {
            return string(withKey: .deviceId)
        } set {
            save(string: newValue, withKey: .deviceId)
        }
    }
    
    var sdkVersion: String? {
        get {
            return string(withKey: .sdkVersion)
        } set {
            save(string: newValue, withKey: .sdkVersion)
        }
    }
    
    func getAttributionInfo(currentDate: Date) -> IterableAttributionInfo? {
        return (try? codable(withKey: .attributionInfo, currentDate: currentDate)) ?? nil
    }
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?) {
        try? save(codable: attributionInfo, withKey: .attributionInfo, andExpiration: expiration)
    }
    
    func getPayload(currentDate: Date) -> [AnyHashable: Any]? {
        return (try? dict(withKey: .payload, currentDate: currentDate)) ?? nil
    }
    
    func save(payload: [AnyHashable: Any]?, withExpiration expiration: Date?) {
        try? save(dict: payload, withKey: .payload, andExpiration: expiration)
    }
    
    // MARK: Private implementation
    
    private let userDefaults: UserDefaults
    
    private func dict(withKey key: LocalStorageKey, currentDate: Date) throws -> [AnyHashable: Any]? {
        guard let encodedEnvelope = userDefaults.value(forKey: key.value) as? Data else {
            return nil
        }
        
        let envelope = try JSONDecoder().decode(Envelope.self, from: encodedEnvelope)
        let decoded = try JSONSerialization.jsonObject(with: envelope.payload, options: []) as? [AnyHashable: Any]
        
        if UserDefaultsLocalStorage.isExpired(expiration: envelope.expiration, currentDate: currentDate) {
            return nil
        } else {
            return decoded
        }
    }
    
    private func codable<T: Codable>(withKey key: LocalStorageKey, currentDate: Date) throws -> T? {
        guard let encodedEnvelope = userDefaults.value(forKey: key.value) as? Data else {
            return nil
        }
        
        let envelope = try JSONDecoder().decode(Envelope.self, from: encodedEnvelope)
        
        let decoded = try JSONDecoder().decode(T.self, from: envelope.payload)
        
        if UserDefaultsLocalStorage.isExpired(expiration: envelope.expiration, currentDate: currentDate) {
            return nil
        } else {
            return decoded
        }
    }
    
    private func string(withKey key: LocalStorageKey) -> String? {
        return userDefaults.string(forKey: key.value)
    }
    
    private func bool(withKey key: LocalStorageKey) -> Bool {
        return userDefaults.bool(forKey: key.value)
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
    
    private func save<T: Codable>(codable: T?, withKey key: LocalStorageKey, andExpiration expiration: Date? = nil) throws {
        if let value = codable {
            let data = try JSONEncoder().encode(value)
            try save(data: data, withKey: key, andExpiration: expiration)
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    private func save(dict: [AnyHashable: Any]?, withKey key: LocalStorageKey, andExpiration expiration: Date? = nil) throws {
        if let value = dict {
            if JSONSerialization.isValidJSONObject(value) {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                try save(data: data, withKey: key, andExpiration: expiration)
            }
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    private func save(string: String?, withKey key: LocalStorageKey) {
        userDefaults.set(string, forKey: key.value)
    }
    
    private func save(bool: Bool, withKey key: LocalStorageKey) {
        userDefaults.set(bool, forKey: key.value)
    }
    
    private func save(data: Data?, withKey key: LocalStorageKey, andExpiration expiration: Date?) throws {
        guard let data = data else {
            userDefaults.removeObject(forKey: key.value)
            return
        }
        
        let envelope = Envelope(payload: data, expiration: expiration)
        let encodedEnvelope = try JSONEncoder().encode(envelope)
        userDefaults.set(encodedEnvelope, forKey: key.value)
    }
    
    private struct LocalStorageKey {
        let value: String
        
        private init(value: String) {
            self.value = value
        }
        
        static let payload = LocalStorageKey(value: Const.UserDefaults.payloadKey)
        static let attributionInfo = LocalStorageKey(value: Const.UserDefaults.attributionInfoKey)
        static let email = LocalStorageKey(value: Const.UserDefaults.emailKey)
        static let userId = LocalStorageKey(value: Const.UserDefaults.userIdKey)
        static let ddlChecked = LocalStorageKey(value: Const.UserDefaults.ddlChecked)
        static let deviceId = LocalStorageKey(value: Const.UserDefaults.deviceId)
        static let sdkVersion = LocalStorageKey(value: Const.UserDefaults.sdkVersion)
    }
    
    private struct Envelope: Codable {
        let payload: Data
        let expiration: Date?
    }
}
