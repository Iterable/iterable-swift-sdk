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
        guard let payloadExpirationPair = getPayloadExpirationPairFromKeychain() else {
            return nil
        }
        
        if isLastPushPayloadExpired(expiration: payloadExpirationPair.expiration, currentDate: currentDate) {
            removePayloadExpirationPairFromKeychain()
            return nil
        }
        
        return decodeJsonPayload(payloadExpirationPair.payload)
    }
    
    func setLastPushPayload(_ payload: [AnyHashable: Any]?, withExpiration expiration: Date?) {
        guard let payload = payload, JSONSerialization.isValidJSONObject(payload) else {
            removePayloadExpirationPairFromKeychain()
            return
        }
        
        savePayloadExpirationPairToKeychain(payload: payload, expiration: expiration)
    }
    
    // MARK: - PRIVATE/INTERNAL
    
    private let wrapper: KeychainWrapper
    
    private func getPayloadExpirationPairFromKeychain() -> (payload: Data, expiration: Date?)? {
        // get the value from the keychain
        guard let keychainValue = wrapper.data(forKey: Const.Keychain.Key.lastPushPayloadAndExpiration) else {
            return nil
        }
        
        // decode the payload/expiration pair
        guard let payloadExpirationPair = try? JSONDecoder().decode(LastPushPayloadValue.self, from: keychainValue) else {
            return nil
        }
        
        // cast the payload as a JSON object
        guard let lastPushPayloadJSON = try? JSONSerialization.jsonObject(with: payloadExpirationPair.payload, options: []) as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let lastPushPayloadData = try? JSONSerialization.data(withJSONObject: lastPushPayloadJSON) else {
            return nil
        }
        
        return (payload: lastPushPayloadData, expiration: payloadExpirationPair.expiration)
    }
    
    private func savePayloadExpirationPairToKeychain(payload: [AnyHashable: Any]?, expiration: Date?) {
        guard let payload = payload else {
            removePayloadExpirationPairFromKeychain()
            return
        }
        
        guard let payloadAsData = encodeJsonPayload(payload) else {
            return
        }
        
        let payloadExpirationPair = LastPushPayloadValue(payload: payloadAsData, expiration: expiration)
        
        guard let encodedPair = try? JSONEncoder().encode(payloadExpirationPair) else {
            return
        }
        
        wrapper.set(encodedPair, forKey: Const.Keychain.Key.lastPushPayloadAndExpiration)
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
    
    private func removePayloadExpirationPairFromKeychain() {
        wrapper.removeValue(forKey: Const.Keychain.Key.lastPushPayloadAndExpiration)
    }
    
    private func isLastPushPayloadExpired(expiration: Date?, currentDate: Date) -> Bool {
        guard let expiration = expiration else {
            return false
        }
        
        return !(expiration.timeIntervalSinceReferenceDate > currentDate.timeIntervalSinceReferenceDate)
    }
    
    private struct LastPushPayloadValue: Codable {
        let payload: Data
        let expiration: Date?
    }
}
