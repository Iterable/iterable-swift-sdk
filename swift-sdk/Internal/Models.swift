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

    enum CodingKeys: String, CodingKey {
        case totalUnknownUserSessionCount = "totalUnknownSessionCount"
        case lastUnknownUserSession = "lastUnknownSession"
        case firstUnknownUserSession = "firstUnknownSession"
    }

    // Legacy keys, kept only for one-shot decode migration.
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
            // New schema branch
            self.totalUnknownUserSessionCount = count
            self.lastUnknownUserSession = try container.decode(Int.self, forKey: .lastUnknownUserSession)
            self.firstUnknownUserSession = try container.decode(Int.self, forKey: .firstUnknownUserSession)
        } else {
            // Fallback to legacy schema with "User" in the keys.
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            self.totalUnknownUserSessionCount = try legacy.decode(Int.self, forKey: .totalUnknownUserSessionCount)
            self.lastUnknownUserSession = try legacy.decode(Int.self, forKey: .lastUnknownUserSession)
            self.firstUnknownUserSession = try legacy.decode(Int.self, forKey: .firstUnknownUserSession)
        }
    }
}

struct IterableUnknownUserSessionsWrapper: Codable {
    var itbl_unknown_user_sessions: IterableUnknownUserSessions

    enum CodingKeys: String, CodingKey {
        case itbl_unknown_user_sessions = "itbl_unknown_sessions"
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case itbl_unknown_user_sessions
    }

    init(itbl_unknown_user_sessions: IterableUnknownUserSessions) {
        self.itbl_unknown_user_sessions = itbl_unknown_user_sessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let sessions = try container.decodeIfPresent(IterableUnknownUserSessions.self, forKey: .itbl_unknown_user_sessions) {
            self.itbl_unknown_user_sessions = sessions
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            self.itbl_unknown_user_sessions = try legacy.decode(IterableUnknownUserSessions.self, forKey: .itbl_unknown_user_sessions)
        }
    }
}
