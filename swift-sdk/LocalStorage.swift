//
//
//  Created by Tapash Majumder on 8/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct LocalStorageKey {
    let value: String
    
    private init(value: String) {
        self.value = value
    }
    
    static let payload = LocalStorageKey(value: ITBL_USER_DEFAULTS_PAYLOAD_KEY)
    static let attributionInfo = LocalStorageKey(value: ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY)
    static let email = LocalStorageKey(value: ITBL_USER_DEFAULTS_EMAIL_KEY)
    static let userId = LocalStorageKey(value: ITBL_USER_DEFAULTS_USERID_KEY)
}

protocol LocalStorageProtocolNew {
    func save(userId: String?)
    func getUserId() -> String?
    func save(email: String?)
    func getEmail() -> String?
    func save(attributionInfo: IterableAttributionInfo?)
    func getAttributionInfo() -> IterableAttributionInfo?
    func save(payload: [AnyHashable : Any]?)
    func getPayload() -> [AnyHashable : Any]?
}

protocol LocalStorageProtocol {
    
    func dict(withKey key: LocalStorageKey) throws -> [AnyHashable : Any]?
    func codable<T: Codable>(withKey key: LocalStorageKey) throws -> T?
    func string(withKey key: LocalStorageKey) throws -> String?
    func save(dict: [AnyHashable : Any]?, withKey key: LocalStorageKey) throws
    func save(dict: [AnyHashable : Any]?, withKey key: LocalStorageKey, andExpiration expiration: Date?) throws
    func save<T:Codable>(codable: T?, withKey key: LocalStorageKey) throws
    func save<T:Codable>(codable: T?, withKey key: LocalStorageKey, andExpiration expiration: Date?) throws
    func save(string: String?, withKey key: LocalStorageKey) throws
}

struct LocalStorage : LocalStorageProtocol {
    struct Envelope : Codable {
        let payload: Data
        let expiration: Date?
    }
    
    init(dateProvider: DateProviderProtocol) {
        self.dateProvider = dateProvider
    }
    
    private let dateProvider: DateProviderProtocol

    func dict(withKey key: LocalStorageKey) throws -> [AnyHashable : Any]? {
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
    
    func codable<T: Codable>(withKey key: LocalStorageKey) throws -> T? {
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
    
    func string(withKey key: LocalStorageKey) throws -> String? {
        return UserDefaults.standard.string(forKey: key.value)
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
    
    func save<T:Codable>(codable: T?, withKey key: LocalStorageKey) throws {
        try save(codable: codable, withKey: key, andExpiration: nil)
    }

    func save<T:Codable>(codable: T?, withKey key: LocalStorageKey, andExpiration expiration: Date?) throws {
        if let value = codable {
            let data = try JSONEncoder().encode(value)
            try save(data: data, withKey: key, andExpiration: expiration)
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    func save(dict: [AnyHashable : Any]?, withKey key: LocalStorageKey, andExpiration expiration: Date?) throws {
        if let value = dict {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            try save(data: data, withKey: key, andExpiration: expiration)
        } else {
            try save(data: nil, withKey: key, andExpiration: expiration)
        }
    }
    
    func save(dict: [AnyHashable : Any]?, withKey key: LocalStorageKey) throws {
        try save(dict: dict, withKey: key, andExpiration: nil)
    }
    
    func save(string: String?, withKey key: LocalStorageKey) throws {
        UserDefaults.standard.set(string, forKey: key.value)
    }

    private func save(data: Data?, withKey key: LocalStorageKey, andExpiration expiration: Date?) throws {
        guard let data = data else {
            UserDefaults.standard.removeObject(forKey: key.value)
            return
        }
        
        let envelope = Envelope(payload: data, expiration: expiration)
        let encodedEnvelope = try JSONEncoder().encode(envelope)
        UserDefaults.standard.set(encodedEnvelope, forKey: key.value)
    }
    
}
