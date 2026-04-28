//
//  UUANormalizationMigrationTests.swift
//  swift-sdk
//
//  Coverage for SDK-412 (Unknown User Activation naming normalization):
//  on-disk format migrations + public API deprecated alias forwarding.
//

import XCTest

@testable import IterableSDK

class UUANormalizationMigrationTests: XCTestCase {

    private static let suiteName = "uua.normalization.tests"

    private var userDefaults: UserDefaults!
    private var serviceName: String!

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: Self.suiteName)
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        serviceName = "test-uua-\(UUID().uuidString)"
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        KeychainWrapper(serviceName: serviceName).removeAll()
    }

    // MARK: - Keychain key migration: itbl_userid_unknown_user -> itbl_userid_unknown

    func testKeychainUnknownUserIdMigratesFromLegacyKeyOnRead() throws {
        let wrapper = KeychainWrapper(serviceName: serviceName)
        let legacyValue = "legacy-unknown-user-id"
        XCTAssertTrue(wrapper.set(legacyValue.data(using: .utf8)!,
                                  forKey: Const.Keychain.Key.legacyUserIdUnknownUser))

        let keychain = IterableKeychain(wrapper: wrapper)

        XCTAssertEqual(keychain.userIdUnknownUser, legacyValue)
        // After read, legacy should be cleaned up and new key populated.
        XCTAssertNil(wrapper.data(forKey: Const.Keychain.Key.legacyUserIdUnknownUser))
        XCTAssertEqual(String(data: wrapper.data(forKey: Const.Keychain.Key.userIdUnknownUser)!, encoding: .utf8),
                       legacyValue)
    }

    func testKeychainUnknownUserIdPrefersNewKeyOverLegacy() throws {
        let wrapper = KeychainWrapper(serviceName: serviceName)
        XCTAssertTrue(wrapper.set("new".data(using: .utf8)!, forKey: Const.Keychain.Key.userIdUnknownUser))
        XCTAssertTrue(wrapper.set("legacy".data(using: .utf8)!, forKey: Const.Keychain.Key.legacyUserIdUnknownUser))

        let keychain = IterableKeychain(wrapper: wrapper)
        XCTAssertEqual(keychain.userIdUnknownUser, "new")
    }

    // MARK: - UserDefaults sessions blob: itbl_unknown_user_sessions -> itbl_unknown_sessions

    func testSessionsBlobMigratesFromLegacyUserDefaultsKey() throws {
        let payload = #"{"itbl_unknown_user_sessions":{"totalUnknownUserSessionCount":7,"lastUnknownUserSession":2,"firstUnknownUserSession":1}}"#
            .data(using: .utf8)!
        userDefaults.set(payload, forKey: Const.UserDefault.legacyUnknownUserSessions)

        let defaults = IterableUserDefaults(userDefaults: userDefaults)
        let sessions = defaults.unknownUserSessions

        XCTAssertNotNil(sessions)
        XCTAssertEqual(sessions?.itbl_unknown_user_sessions.totalUnknownUserSessionCount, 7)
        XCTAssertEqual(sessions?.itbl_unknown_user_sessions.lastUnknownUserSession, 2)
        XCTAssertEqual(sessions?.itbl_unknown_user_sessions.firstUnknownUserSession, 1)

        XCTAssertNil(userDefaults.data(forKey: Const.UserDefault.legacyUnknownUserSessions))
        XCTAssertNotNil(userDefaults.data(forKey: Const.UserDefault.unknownUserSessions))
    }

    // MARK: - Sessions wrapper CodingKeys: decodes legacy + new, encodes new only

    func testSessionsWrapperDecodesLegacyAndNewKeys() throws {
        let decoder = JSONDecoder()
        let legacy = #"{"itbl_unknown_user_sessions":{"totalUnknownUserSessionCount":3,"lastUnknownUserSession":222,"firstUnknownUserSession":111}}"#
            .data(using: .utf8)!
        let modern = #"{"itbl_unknown_sessions":{"totalUnknownSessionCount":3,"lastUnknownSession":222,"firstUnknownSession":111}}"#
            .data(using: .utf8)!

        let fromLegacy = try decoder.decode(IterableUnknownUserSessionsWrapper.self, from: legacy)
        let fromModern = try decoder.decode(IterableUnknownUserSessionsWrapper.self, from: modern)

        XCTAssertEqual(fromLegacy.itbl_unknown_user_sessions.totalUnknownUserSessionCount, 3)
        XCTAssertEqual(fromModern.itbl_unknown_user_sessions.totalUnknownUserSessionCount, 3)
    }

    func testSessionsWrapperEncodesNewKeysOnly() throws {
        let sessions = IterableUnknownUserSessionsWrapper(
            itbl_unknown_user_sessions: IterableUnknownUserSessions(
                totalUnknownUserSessionCount: 5,
                lastUnknownUserSession: 22,
                firstUnknownUserSession: 11
            )
        )
        let data = try JSONEncoder().encode(sessions)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNotNil(json["itbl_unknown_sessions"])
        XCTAssertNil(json["itbl_unknown_user_sessions"])

        let inner = try XCTUnwrap(json["itbl_unknown_sessions"] as? [String: Any])
        XCTAssertEqual(inner["totalUnknownSessionCount"] as? Int, 5)
        XCTAssertEqual(inner["lastUnknownSession"] as? Int, 22)
        XCTAssertEqual(inner["firstUnknownSession"] as? Int, 11)
        XCTAssertNil(inner["totalUnknownUserSessionCount"])
        XCTAssertNil(inner["lastUnknownUserSession"])
        XCTAssertNil(inner["firstUnknownUserSession"])
    }

    // MARK: - Stored event discriminator: dataType -> eventType

    func testUnknownUserEventsRewritesLegacyDataTypeKeyOnRead() throws {
        let legacyEvent: [[String: Any]] = [
            ["dataType": EventType.customEvent, "eventName": "viewedProduct"],
            ["dataType": EventType.purchase, "total": "9.99"]
        ]
        userDefaults.set(legacyEvent, forKey: Const.UserDefault.unknownUserEvents)

        let defaults = IterableUserDefaults(userDefaults: userDefaults)
        let events = try XCTUnwrap(defaults.unknownUserEvents)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0][JsonKey.eventType] as? String, EventType.customEvent)
        XCTAssertNil(events[0][JsonKey.legacyEventType])
        XCTAssertEqual(events[1][JsonKey.eventType] as? String, EventType.purchase)

        // Migrated payload should be persisted back under the same key.
        let stored = try XCTUnwrap(userDefaults.array(forKey: Const.UserDefault.unknownUserEvents) as? [[AnyHashable: Any]])
        XCTAssertEqual(stored[0][JsonKey.eventType] as? String, EventType.customEvent)
        XCTAssertNil(stored[0][JsonKey.legacyEventType])
    }

    // MARK: - Identity resolution deprecated alias

    func testIdentityResolutionLegacyInitForwardsToNewName() {
        let resolution = IterableIdentityResolution(replayOnVisitorToKnown: true,
                                                    mergeOnUnknownUserToKnown: false)
        XCTAssertEqual(resolution.mergeOnUnknownToKnown, false)
        XCTAssertEqual(resolution.mergeOnUnknownUserToKnown, false)
    }
}
