//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

class IterableKeychain {
    init(wrapper: KeychainWrapper = KeychainWrapper()) {
        self.wrapper = wrapper
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
    
    func getLastPushPayload(currentDate: Date) -> [AnyHashable: Any]? {
        if isLastPushPayloadExpired(currentDate: currentDate) {
            wrapper.removeValue(forKey: Const.Keychain.Key.lastPushPayload)
            wrapper.removeValue(forKey: Const.Keychain.Key.lastPushPayloadExpiration)
            
            return nil
        }
        
        if let data = wrapper.data(forKey: Const.Keychain.Key.lastPushPayload) {
            return (try? JSONSerialization.jsonObject(with: data)) as? [AnyHashable: Any]
        }
        
        return nil
    }
    
    func setLastPushPayload(_ payload: [AnyHashable: Any]?, withExpiration expiration: Date?) {
        // save expiration here
        
        guard let value = payload?.jsonValue, JSONSerialization.isValidJSONObject(value) else {
            wrapper.removeValue(forKey: Const.Keychain.Key.lastPushPayload)
            return
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            wrapper.set(data, forKey: Const.Keychain.Key.lastPushPayload)
        } catch {
            wrapper.removeValue(forKey: Const.Keychain.Key.lastPushPayload)
        }
    }
    
    // MARK: - PRIVATE/INTERNAL
    
    private let wrapper: KeychainWrapper
    
    private func isLastPushPayloadExpired(currentDate: Date) -> Bool {
        // get expiration here
        
        guard let expiration = wrapper.data(forKey: Const.Keychain.Key.lastPushPayloadExpiration) as? Date else {
            return false
        }
        
        return !(expiration.timeIntervalSinceReferenceDate > currentDate.timeIntervalSinceReferenceDate)
    }
}
