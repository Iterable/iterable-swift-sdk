//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

protocol LocalStorageProtocol {
    var userId: String? { get set }
    
    var userIdUnknownUser: String? { get set }
    
    var email: String? { get set }
    
    var authToken: String? { get set }
    
    var ddlChecked: Bool { get set }
    
    var deviceId: String? { get set }
    
    var sdkVersion: String? { get set }
    
    var offlineMode: Bool { get set }

    var visitorUsageTracked: Bool { get set }

    var unknownUserEvents: [[AnyHashable: Any]]? { get set }

    var visitorConsentTimestamp: Int64? { get set }
    
    var unknownUserUpdate: [AnyHashable: Any]? { get set }

    var criteriaData: Data? { get set }

    var unknownUserSessions: IterableUnknownUserSessionsWrapper? { get set }
    
    var isNotificationsEnabled: Bool { get set }
    
    var hasStoredNotificationSetting: Bool { get set }
    
    func getAttributionInfo(currentDate: Date) -> IterableAttributionInfo?
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?)
    
    func upgrade()

    func migrateKeychainToIsolatedStorage()
}

extension LocalStorageProtocol {
    func upgrade() {
    }

    func migrateKeychainToIsolatedStorage() {
    }
}
