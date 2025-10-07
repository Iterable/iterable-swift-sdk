//
//  Copyright © 2021 Iterable. All rights reserved.
//
// Misc JSON serialization models.

import Foundation

struct RemoteConfiguration: Codable, Equatable {
    let offlineMode: Bool
}

struct Criteria: Codable {
    let criteriaId: String
    let criteriaList: [CriteriaItem]
}

struct CriteriaItem: Codable {
    let criteriaType: String
    let comparator: String?
    let name: String?
    let aggregateCount: Int?
    let total: Int?
}

struct IterableUnknownUserSessions: Codable {
    var totalUnknownUserSessionCount: Int
    var lastUnknownUserSession: Int
    var firstUnknownUserSession: Int
}

struct IterableUnknownUserSessionsWrapper: Codable {
    var itbl_unknown_user_sessions: IterableUnknownUserSessions
}
