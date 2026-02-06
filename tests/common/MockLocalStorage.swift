//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockLocalStorage: LocalStorageProtocol {

    var userIdUnknownUser: String?
    
    var unknownUserEvents: [[AnyHashable : Any]]?
    
    var criteriaData: Data?
    
    var unknownUserSessions: IterableSDK.IterableUnknownUserSessionsWrapper?
    
    var userId: String? = nil
    
    var email: String? = nil
    
    var authToken: String? = nil
    
    var ddlChecked: Bool = false
    
    var deviceId: String? = nil
    
    var sdkVersion: String? = nil
    
    var offlineMode: Bool = false

    var autoRetry: Bool = false

    var visitorUsageTracked: Bool = true
    
    var visitorConsentTimestamp: Int64?
    
    var unknownUserUpdate: [AnyHashable : Any]?

    var isNotificationsEnabled: Bool = false
    
    var hasStoredNotificationSetting: Bool = false
    
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
    
    private var attributionInfo: IterableAttributionInfo? = nil
    private var attributionInfoExpiration: Date? = nil
    
    private static func isExpired(expiration: Date?, currentDate: Date) -> Bool {
        guard let expiration = expiration else {
            return false
        }
        
        return !(expiration.timeIntervalSinceReferenceDate > currentDate.timeIntervalSinceReferenceDate)
    }
}
