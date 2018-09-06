//
//
//  Created by Tapash Majumder on 8/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct UserDefaultsLocalStorage : LocalStorageProtocol {
    init(dateProvider: DateProviderProtocol) {
        self.dateProvider = dateProvider
    }
    
    var userId : String? {
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
    
    var attributionInfo: IterableAttributionInfo? {
        return (try? codable(withKey: .attributionInfo)) ?? nil
    }
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?) {
        try? save(codable: attributionInfo, withKey: .attributionInfo, andExpiration: expiration)
    }
    
    var payload: [AnyHashable : Any]? {
        return (try? dict(withKey: .payload)) ?? nil
    }
    
    func save(payload: [AnyHashable : Any]?, withExpiration expiration: Date?) {
        try? save(dict: payload, withKey: .payload, andExpiration: expiration)
    }

    // MARK: Private implementation
    private let dateProvider: DateProviderProtocol

    private func dict(withKey key: LocalStorageKey) throws -> [AnyHashable : Any]? {
        guard let encodedEnvelope = UserDefaults.standard.value(forKey: key.value) as? Data else {
            return nil
        }
        let envelope = try JSONDecoder().decode(Envelope.self, from: encodedEnvelope)
        
        let decoded = try JSONSerialization.jsonObject(with: envelope.payload, options: []) as? [AnyHashable : Any]
        
        if isExpired(expiration: envelope.expiration) {
            return nil
        } else {
            return decoded
        }
    }
    
    private func codable<T: Codable>(withKey key: LocalStorageKey) throws -> T? {
        guard let encodedEnvelope = UserDefaults.standard.value(forKey: key.value) as? Data else {
            return nil
        }
        let envelope = try JSONDecoder().decode(Envelope.self, from: encodedEnvelope)

        let decoded = try JSONDecoder().decode(T.self, from: envelope.payload)
        
        if isExpired(expiration: envelope.expiration) {
            return nil
        } else {
            return decoded
        }
    }
    
    private func string(withKey key: LocalStorageKey) -> String? {
        return UserDefaults.standard.string(forKey: key.value)
    }
    
    private func bool(withKey key: LocalStorageKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.value)
    }
    
    private func isExpired(expiration: Date?) -> Bool {
        if let expiration = expiration {
            if expiration.timeIntervalSinceReferenceDate > dateProvider.currentDate.timeIntervalSinceReferenceDate {
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
    
    private func save<T:Codable>(codable: T?, withKey key: LocalStorageKey, andExpiration expiration: Date? = nil) throws {
        if let value = codable {
            let data = try JSONEncoder().encode(value)
            try save(data: data, withKey: key, andExpiration: expiration)
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    private func save(dict: [AnyHashable : Any]?, withKey key: LocalStorageKey, andExpiration expiration: Date? = nil) throws {
        if let value = dict {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            try save(data: data, withKey: key, andExpiration: expiration)
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    private func save(string: String?, withKey key: LocalStorageKey) {
        UserDefaults.standard.set(string, forKey: key.value)
    }
    
    private func save(bool: Bool, withKey key: LocalStorageKey) {
        UserDefaults.standard.set(bool, forKey: key.value)
    }

    private func save(data: Data?, withKey key: LocalStorageKey, andExpiration expiration: Date?) throws {
        guard let data = data else {
            UserDefaults.standard.removeObject(forKey: key.value)
            return
        }
        
        let envelope = Envelope(payload: data, expiration: expiration)
        let encodedEnvelope = try JSONEncoder().encode(envelope)
        UserDefaults.standard.set (encodedEnvelope, forKey: key.value)
    }
    
    private struct LocalStorageKey {
        let value: String
        
        private init(value: String) {
            self.value = value
        }
        
        static let payload = LocalStorageKey(value: ITBL_USER_DEFAULTS_PAYLOAD_KEY)
        static let attributionInfo = LocalStorageKey(value: ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY)
        static let email = LocalStorageKey(value: ITBL_USER_DEFAULTS_EMAIL_KEY)
        static let userId = LocalStorageKey(value: ITBL_USER_DEFAULTS_USERID_KEY)
        static let ddlChecked = LocalStorageKey(value: ITBL_USER_DEFAULTS_DDL_CHECKED)
        static let deviceId = LocalStorageKey(value: ITBL_USER_DEFAULTS_DEVICE_ID)
        static let sdkVersion = LocalStorageKey(value: ITBL_USER_DEFAULTS_SDK_VERSION)
    }
    
    private struct Envelope : Codable {
        let payload: Data
        let expiration: Date?
    }
}
