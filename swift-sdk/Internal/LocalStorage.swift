//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct LocalStorage: LocalStorageProtocol {
    init(userDefaults: UserDefaults = UserDefaults.standard,
         keychain: IterableKeychain = IterableKeychain()) {
        iterableUserDefaults = IterableUserDefaults(userDefaults: userDefaults)
        self.keychain = keychain
    }
    
    var userId: String? {
        get {
            iterableUserDefaults.userId
        } set {
            iterableUserDefaults.userId = newValue
        }
    }
    
    var email: String? {
        get {
            iterableUserDefaults.email
        } set {
            iterableUserDefaults.email = newValue
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
    
    var offlineModeBeta: Bool {
        get {
            iterableUserDefaults.offlineModeBeta
        }
        set {
            iterableUserDefaults.offlineModeBeta = newValue
        }
    }
    
    func getAttributionInfo(currentDate: Date) -> IterableAttributionInfo? {
        iterableUserDefaults.getAttributionInfo(currentDate: currentDate)
    }
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?) {
        iterableUserDefaults.save(attributionInfo: attributionInfo, withExpiration: expiration)
    }
    
    func getPayload(currentDate: Date) -> [AnyHashable: Any]? {
        iterableUserDefaults.getPayload(currentDate: currentDate)
    }
    
    func save(payload: [AnyHashable: Any]?, withExpiration expiration: Date?) {
        iterableUserDefaults.save(payload: payload, withExpiration: expiration)
    }
    
    func upgrade() {
        ITBInfo()
        moveJwtFromUserDefaultsToKeychain()
    }
    
    // MARK: Private
    
    private let iterableUserDefaults: IterableUserDefaults
    private let keychain: IterableKeychain

    private func moveJwtFromUserDefaultsToKeychain() {
        if let userDefaultAuthToken = iterableUserDefaults.authToken, keychain.authToken == nil {
            keychain.authToken = userDefaultAuthToken
            iterableUserDefaults.authToken = nil
            ITBInfo("updated: keychain auth token")
        }
    }
}
