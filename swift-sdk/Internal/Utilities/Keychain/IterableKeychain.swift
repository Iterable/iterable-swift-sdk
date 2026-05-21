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
    ///
    /// Runs as a barrier on `coordinatorQueue` so it blocks until in-flight
    /// reads finish, then blocks subsequent reads / writes until the barrier
    /// returns. After it returns, reads run fully in parallel. Uses raw
    /// `wrapper`/`legacyWrapper` access internally to avoid re-entering the
    /// queue (the public properties also go through the queue and would
    /// deadlock if used from inside the barrier).
    @discardableResult
    func migrateFromLegacy() -> Bool {
        guard let legacyWrapper = legacyWrapper else {
            return false
        }

        return coordinatorQueue.sync(flags: .barrier) {
            var migrated = false
            let migrationStartedAt = Date()

            if rawString(forKey: Const.Keychain.Key.email, from: wrapper) == nil,
               let legacyEmail = rawString(forKey: Const.Keychain.Key.email, from: legacyWrapper) {
                rawWrite(string: legacyEmail, forKey: Const.Keychain.Key.email, to: wrapper)
                legacyWrapper.removeValue(forKey: Const.Keychain.Key.email)
                ITBInfo("UPDATED: migrated email from legacy keychain to isolated keychain")
                migrated = true
            }

            if rawString(forKey: Const.Keychain.Key.userId, from: wrapper) == nil,
               let legacyUserId = rawString(forKey: Const.Keychain.Key.userId, from: legacyWrapper) {
                rawWrite(string: legacyUserId, forKey: Const.Keychain.Key.userId, to: wrapper)
                legacyWrapper.removeValue(forKey: Const.Keychain.Key.userId)
                ITBInfo("UPDATED: migrated userId from legacy keychain to isolated keychain")
                migrated = true
            }

            if rawString(forKey: Const.Keychain.Key.userIdUnknownUser, from: wrapper) == nil,
               let legacyUserIdUnknownUser = rawString(forKey: Const.Keychain.Key.userIdUnknownUser, from: legacyWrapper) {
                rawWrite(string: legacyUserIdUnknownUser, forKey: Const.Keychain.Key.userIdUnknownUser, to: wrapper)
                legacyWrapper.removeValue(forKey: Const.Keychain.Key.userIdUnknownUser)
                ITBInfo("UPDATED: migrated userIdUnknownUser from legacy keychain to isolated keychain")
                migrated = true
            }

            if rawString(forKey: Const.Keychain.Key.authToken, from: wrapper) == nil,
               let legacyAuthToken = rawString(forKey: Const.Keychain.Key.authToken, from: legacyWrapper) {
                rawWrite(string: legacyAuthToken, forKey: Const.Keychain.Key.authToken, to: wrapper)
                legacyWrapper.removeValue(forKey: Const.Keychain.Key.authToken)
                ITBInfo("UPDATED: migrated authToken from legacy keychain to isolated keychain")
                migrated = true
            }

            let elapsedMs = Int(Date().timeIntervalSince(migrationStartedAt) * 1000)
            ITBInfo("keychain migrateFromLegacy completed in \(elapsedMs)ms migrated=\(migrated)")

            return migrated
        }
    }

    var email: String? {
        get { coordinatorQueue.sync { rawString(forKey: Const.Keychain.Key.email, from: wrapper) } }
        set {
            coordinatorQueue.sync(flags: .barrier) {
                rawWrite(string: newValue, forKey: Const.Keychain.Key.email, to: wrapper)
            }
        }
    }

    var userId: String? {
        get { coordinatorQueue.sync { rawString(forKey: Const.Keychain.Key.userId, from: wrapper) } }
        set {
            coordinatorQueue.sync(flags: .barrier) {
                rawWrite(string: newValue, forKey: Const.Keychain.Key.userId, to: wrapper)
            }
        }
    }

    var userIdUnknownUser: String? {
        get { coordinatorQueue.sync { rawString(forKey: Const.Keychain.Key.userIdUnknownUser, from: wrapper) } }
        set {
            coordinatorQueue.sync(flags: .barrier) {
                rawWrite(string: newValue, forKey: Const.Keychain.Key.userIdUnknownUser, to: wrapper)
            }
        }
    }

    var authToken: String? {
        get { coordinatorQueue.sync { rawString(forKey: Const.Keychain.Key.authToken, from: wrapper) } }
        set {
            coordinatorQueue.sync(flags: .barrier) {
                rawWrite(string: newValue, forKey: Const.Keychain.Key.authToken, to: wrapper)
            }
        }
    }

    // MARK: - PRIVATE/INTERNAL

    private let wrapper: KeychainWrapper
    private let legacyWrapper: KeychainWrapper?

    /// Concurrent queue used to serialize the migration (which runs as a
    /// barrier) against the property reads/writes. Reads run fully in
    /// parallel after migration completes. See SDK-478.
    private let coordinatorQueue = DispatchQueue(label: "com.iterable.IterableKeychain.coordinator",
                                                 attributes: .concurrent)

    /// Raw read - bypasses the coordinator queue. Only safe to call from
    /// inside a `coordinatorQueue.sync { }` block.
    private func rawString(forKey key: String, from wrapper: KeychainWrapper) -> String? {
        let data = wrapper.data(forKey: key)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }

    /// Raw write - bypasses the coordinator queue. Only safe to call from
    /// inside a `coordinatorQueue.sync(flags: .barrier) { }` block.
    private func rawWrite(string: String?, forKey key: String, to wrapper: KeychainWrapper) {
        guard let value = string, let data = value.data(using: .utf8) else {
            wrapper.removeValue(forKey: key)
            return
        }
        wrapper.set(data, forKey: key)
    }
    
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
