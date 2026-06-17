//
//  Copyright © 2021 Iterable. All rights reserved.
//
// Misc JSON serialization models.

import Foundation

struct RemoteConfiguration: Codable, Equatable {
    let offlineMode: Bool
    let autoRetry: Bool

    init(offlineMode: Bool, autoRetry: Bool = false) {
        self.offlineMode = offlineMode
        self.autoRetry = autoRetry
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        offlineMode = try container.decode(Bool.self, forKey: .offlineMode)
        autoRetry = try container.decodeIfPresent(Bool.self, forKey: .autoRetry) ?? false
    }
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

    // Cross-SDK alignment (SDK-412): backend payload uses the de-"User"'d
    // names that Android already sends. Swift property names stay put to keep
    // call sites unchanged.
    enum CodingKeys: String, CodingKey {
        case totalUnknownUserSessionCount = "totalUnknownSessionCount"
        case lastUnknownUserSession = "lastUnknownSession"
        case firstUnknownUserSession = "firstUnknownSession"
    }

    // Legacy keys, kept only so on-disk blobs written by pre-SDK-412 builds
    // continue to decode after upgrade.
    private enum LegacyCodingKeys: String, CodingKey {
        case totalUnknownUserSessionCount
        case lastUnknownUserSession
        case firstUnknownUserSession
    }

    init(totalUnknownUserSessionCount: Int,
         lastUnknownUserSession: Int,
         firstUnknownUserSession: Int) {
        self.totalUnknownUserSessionCount = totalUnknownUserSessionCount
        self.lastUnknownUserSession = lastUnknownUserSession
        self.firstUnknownUserSession = firstUnknownUserSession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let count = try container.decodeIfPresent(Int.self, forKey: .totalUnknownUserSessionCount) {
            self.totalUnknownUserSessionCount = count
            self.lastUnknownUserSession = try container.decode(Int.self, forKey: .lastUnknownUserSession)
            self.firstUnknownUserSession = try container.decode(Int.self, forKey: .firstUnknownUserSession)
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            self.totalUnknownUserSessionCount = try legacy.decode(Int.self, forKey: .totalUnknownUserSessionCount)
            self.lastUnknownUserSession = try legacy.decode(Int.self, forKey: .lastUnknownUserSession)
            self.firstUnknownUserSession = try legacy.decode(Int.self, forKey: .firstUnknownUserSession)
        }
    }
}

struct IterableUnknownUserSessionsWrapper: Codable {
    var itbl_unknown_user_sessions: IterableUnknownUserSessions
}
