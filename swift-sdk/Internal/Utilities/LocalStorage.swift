//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct LocalStorage: LocalStorageProtocol {

    init(userDefaults: UserDefaults = UserDefaults.standard,
         keychain: IterableKeychain = LocalStorage.createKeychain()) {
        iterableUserDefaults = IterableUserDefaults(userDefaults: userDefaults)
        self.keychain = keychain
    }

    /// Creates the keychain with isolated storage and legacy wrapper for migration
    private static func createKeychain() -> IterableKeychain {
        let isolatedWrapper = KeychainWrapper() // Uses isolated service name by default
        let legacyWrapper = KeychainWrapper(serviceName: KeychainWrapper.legacyServiceName)
        return IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: legacyWrapper)
    }
    
    var userId: String? {
        get {
            keychain.userId
        } set {
            keychain.userId = newValue
        }
    }
    
    var userIdUnknownUser: String? {
        get {
            keychain.userIdUnknownUser
        } set {
            keychain.userIdUnknownUser = newValue
        }
    }
    
    var email: String? {
        get {
            keychain.email
        } set {
            keychain.email = newValue
        }
    }
    
    var authToken: String? {
        get {
            keychain.authToken
        } set {
            keychain.authToken = newValue
        }
    }
    
    var ddlChecked: Bool {
        get {
            iterableUserDefaults.ddlChecked
        } set {
            iterableUserDefaults.ddlChecked = newValue
        }
    }
    
    var deviceId: String? {
        get {
            iterableUserDefaults.deviceId
        } set {
            iterableUserDefaults.deviceId = newValue
        }
    }
    
    var sdkVersion: String? {
        get {
            iterableUserDefaults.sdkVersion
        } set {
            iterableUserDefaults.sdkVersion = newValue
        }
    }
    
    var offlineMode: Bool {
        get {
            iterableUserDefaults.offlineMode
        } set {
            iterableUserDefaults.offlineMode = newValue
        }
    }
    
        var unknownUserEvents: [[AnyHashable: Any]]? {
        get {
            iterableUserDefaults.unknownUserEvents
        } set {
            iterableUserDefaults.unknownUserEvents = newValue
        }
    }

    var unknownUserUpdate: [AnyHashable: Any]? {
        get {
            iterableUserDefaults.unknownUserUpdate
        } set {
            iterableUserDefaults.unknownUserUpdate = newValue
        }
    }

    var unknownUserSessions: IterableUnknownUserSessionsWrapper? {
        get {
            iterableUserDefaults.unknownUserSessions
        } set {
            iterableUserDefaults.unknownUserSessions = newValue
        }
    }

    var criteriaData: Data? {
        get {
            iterableUserDefaults.criteriaData
        } set {
            iterableUserDefaults.criteriaData = newValue
        }
    }

    var visitorUsageTracked: Bool {
        get {
            iterableUserDefaults.visitorUsageTracked
        } set {
            iterableUserDefaults.visitorUsageTracked = newValue
        }
    }

    var visitorConsentTimestamp: Int64? {
        get {
            iterableUserDefaults.visitorConsentTimestamp
        } set {
            iterableUserDefaults.visitorConsentTimestamp = newValue
        }
    }

    var isNotificationsEnabled: Bool {
        get {
            iterableUserDefaults.isNotificationsEnabled
        } set {
            iterableUserDefaults.isNotificationsEnabled = newValue
        }
    }
    
    var hasStoredNotificationSetting: Bool {
        get {
            iterableUserDefaults.hasStoredNotificationSetting
        } set {
            iterableUserDefaults.hasStoredNotificationSetting = newValue
        }
    }
    
    func getAttributionInfo(currentDate: Date) -> IterableAttributionInfo? {
        iterableUserDefaults.getAttributionInfo(currentDate: currentDate)
    }
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?) {
        iterableUserDefaults.save(attributionInfo: attributionInfo, withExpiration: expiration)
    }
    
    func upgrade() {
        ITBInfo()

        /// moves `email`, `userId`, and `authToken` from `UserDefaults` to `IterableKeychain`
        moveAuthDataFromUserDefaultsToKeychain()
    }

    func migrateKeychainToIsolatedStorage() {
        keychain.migrateFromLegacy()
    }
    
    // MARK: Private
    
    private let iterableUserDefaults: IterableUserDefaults
    private let keychain: IterableKeychain
    
    private func moveAuthDataFromUserDefaultsToKeychain() {
        let (userDefaultEmail, userDefaultUserId, userDefaultAuthToken) = iterableUserDefaults.getAuthDataForMigration()
        
        if let userDefaultEmail = userDefaultEmail {
            if keychain.email == nil {
                keychain.email = userDefaultEmail
            }
            
            iterableUserDefaults.email = nil
            
            ITBInfo("UPDATED: migrated email from UserDefaults to IterableKeychain")
        }
        
        if let userDefaultUserId = userDefaultUserId {
            if keychain.userId == nil {
                keychain.userId = userDefaultUserId
            }
            
            iterableUserDefaults.userId = nil
            
            ITBInfo("UPDATED: migrated userId from UserDefaults to IterableKeychain")
        }
        
        if let userDefaultAuthToken = userDefaultAuthToken {
            if keychain.authToken == nil {
                keychain.authToken = userDefaultAuthToken
            }
            
            iterableUserDefaults.authToken = nil
            
            ITBInfo("UPDATED: migrated authToken from UserDefaults to IterableKeychain")
        }
    }
}
