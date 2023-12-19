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

struct IterableAnonSessions: Codable {
    var number_of_sessions: Int
    var last_session: String
    var first_session: String
}

struct IterableAnonSessionsWrapper: Codable {
    var itbl_anon_sessions: IterableAnonSessions
}
