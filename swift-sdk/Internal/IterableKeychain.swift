//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

class IterableKeychain {
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
        guard let data = wrapper.data(forKey: Const.Keychain.Key.lastPushPayload) else {
            return nil
        }
        
        let lastPushPayload = (try? JSONSerialization.jsonObject(with: data)) as? [AnyHashable: Any]
        
        // check for expiration here
        
        return lastPushPayload
    }
    
    func setLastPushPayload(_ payload: [AnyHashable: Any]?, withExpiration expiration: Date?) {
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
    
    init(wrapper: KeychainWrapper = KeychainWrapper()) {
        self.wrapper = wrapper
    }
    
    private let wrapper: KeychainWrapper
}
