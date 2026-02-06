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

    var autoRetry: Bool {
        get {
            bool(withKey: .autoRetry)
        } set {
            save(bool: newValue, withKey: .autoRetry)
        }
    }

    var visitorUsageTracked: Bool {
        get {
            return bool(withKey: .visitorUsageTracked)
        } set {
            save(bool: newValue, withKey: .visitorUsageTracked)
        }
    }

    var visitorConsentTimestamp: Int64? {
        get {
            return int64(withKey: .visitorConsentTimestamp)
        } set {
            save(int64: newValue, withKey: .visitorConsentTimestamp)
        }
    }

    var unknownUserEvents: [[AnyHashable: Any]]? {
        get {
            return eventData(withKey: .unknownUserEvents)
        } set {
            saveEventData(unknownUserEvents: newValue, withKey: .unknownUserEvents)
        }
    }
    
    var unknownUserUpdate: [AnyHashable: Any]? {
        get {
            return userUpdateData(withKey: .unknownUserUpdate)
        } set {
            saveUserUpdate(newValue, withKey: .unknownUserUpdate)
        }
    }
    
    var criteriaData: Data? {
        get {
            return getCriteriaData(withKey: .criteriaData)
        } set {
            saveCriteriaData(data: newValue, withKey: .criteriaData)
        }
    }
    
    var unknownUserSessions: IterableUnknownUserSessionsWrapper? {
        get {
            return unknownUserSessionsData(withKey: .unknownUserSessions)
        } set {
            saveUnknownUserSessionsData(data: newValue, withKey: .unknownUserSessions)
        }
    }
    
    var body = [AnyHashable: Any]()
    
    private func unknownUserSessionsData(withKey key: UserDefaultsKey) -> IterableUnknownUserSessionsWrapper? {
        if let savedData = UserDefaults.standard.data(forKey: key.value) {
            let decodedData = try? JSONDecoder().decode(IterableUnknownUserSessionsWrapper.self, from: savedData)
            return decodedData
        }
        return nil
    }
    
    private func saveUnknownUserSessionsData(data: IterableUnknownUserSessionsWrapper?, withKey key: UserDefaultsKey) {
        if let encodedData = try? JSONEncoder().encode(data) {
            userDefaults.set(encodedData, forKey: key.value)
        }
    }
    
    private func criteriaData(withKey key: UserDefaultsKey) -> [Criteria]? {
        if let savedData = UserDefaults.standard.data(forKey: key.value) {
            let decodedData = try? JSONDecoder().decode([Criteria].self, from: savedData)
            return decodedData
        }
        return nil
    }
    
    private func saveCriteriaData(data: Data?, withKey key: UserDefaultsKey) {
        userDefaults.set(data, forKey: key.value)
    }
    
    private func saveEventData(unknownUserEvents: [[AnyHashable: Any]]?, withKey key: UserDefaultsKey) {
        userDefaults.set(unknownUserEvents, forKey: key.value)
    }
    
    private func saveUserUpdate(_ update: [AnyHashable: Any]?, withKey key: UserDefaultsKey) {
        userDefaults.set(update, forKey: key.value)
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
    
    private func dict(withKey key: UserDefaultsKey) throws -> [AnyHashable: Any]? {
        guard let encodedEnvelope = userDefaults.value(forKey: key.value) as? Data else {
            return nil
        }

        let envelope = try JSONDecoder().decode(EnvelopeNoExpiration.self, from: encodedEnvelope)
        let decoded = try JSONSerialization.jsonObject(with: envelope.payload, options: []) as? [AnyHashable: Any]
        return decoded
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
    
    private func eventData(withKey key: UserDefaultsKey) -> [[AnyHashable: Any]]? {
        userDefaults.array(forKey: key.value) as? [[AnyHashable: Any]]
    }
    
    private func userUpdateData(withKey key: UserDefaultsKey) -> [AnyHashable: Any]? {
        userDefaults.object(forKey: key.value) as? [AnyHashable: Any]
    }
    
    private func getCriteriaData(withKey key: UserDefaultsKey) -> Data? {
        userDefaults.object(forKey: key.value) as? Data
    }
    
    private func int64(withKey key: UserDefaultsKey) -> Int64? {
        userDefaults.object(forKey: key.value) as? Int64
    }

    private func save(int64: Int64?, withKey key: UserDefaultsKey) {
        userDefaults.set(int64, forKey: key.value)
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
    
    private func save(data: Data?, withKey key: UserDefaultsKey) throws {
        guard let data = data else {
            userDefaults.removeObject(forKey: key.value)
            return
        }

        let envelope = EnvelopeNoExpiration(payload: data)
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
        static let autoRetry = UserDefaultsKey(value: Const.UserDefault.autoRetry)
        static let unknownUserEvents = UserDefaultsKey(value: Const.UserDefault.unknownUserEvents)
        static let unknownUserUpdate = UserDefaultsKey(value: Const.UserDefault.unknownUserUpdate)
        static let criteriaData = UserDefaultsKey(value: Const.UserDefault.criteriaData)
        static let unknownUserSessions = UserDefaultsKey(value: Const.UserDefault.unknownUserSessions)
        static let visitorUsageTracked = UserDefaultsKey(value: Const.UserDefault.visitorUsageTracked)
        static let visitorConsentTimestamp = UserDefaultsKey(value: Const.UserDefault.visitorConsentTimestamp)

        static let isNotificationsEnabled = UserDefaultsKey(value: Const.UserDefault.isNotificationsEnabled)
        static let hasStoredNotificationSetting = UserDefaultsKey(value: Const.UserDefault.hasStoredNotificationSetting)
    }
    private struct Envelope: Codable {
        let payload: Data
        let expiration: Date?
    }
    
    private struct EnvelopeNoExpiration: Codable {
        let payload: Data
    }
}
