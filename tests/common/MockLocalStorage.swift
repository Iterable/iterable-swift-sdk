//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockLocalStorage: LocalStorageProtocol {
    var userId: String? = nil
    
    var email: String? = nil
    
    var authToken: String? = nil
    
    var ddlChecked: Bool = false
    
    var deviceId: String? = nil
    
    var sdkVersion: String? = nil
    
    var offlineMode: Bool = false
    
    func getAttributionInfo(currentDate: Date) -> IterableAttributionInfo? {
        guard !MockLocalStorage.isExpired(expiration: attributionInfoExpiration, currentDate: currentDate) else {
            return nil
        }
        return attributionInfo
    }
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?) {
        self.attributionInfo = attributionInfo
        attributionInfoExpiration = expiration
    }
    
    func getLastPushPayload(_ currentDate: Date) -> [AnyHashable : Any]? {
        guard !MockLocalStorage.isExpired(expiration: payloadExpiration, currentDate: currentDate) else {
            return nil
        }
        
        return payload
    }
    
    func saveLastPushPayload(_ payload: [AnyHashable : Any]?, withExpiration expiration: Date?) {
        self.payload = payload
        payloadExpiration = expiration
    }
    
    private var payload: [AnyHashable: Any]? = nil
    private var payloadExpiration: Date? = nil
    
    private var attributionInfo: IterableAttributionInfo? = nil
    private var attributionInfoExpiration: Date? = nil
    
    private static func isExpired(expiration: Date?, currentDate: Date) -> Bool {
        guard let expiration = expiration else {
            return false
        }
        
        return !(expiration.timeIntervalSinceReferenceDate > currentDate.timeIntervalSinceReferenceDate)
    }
}
