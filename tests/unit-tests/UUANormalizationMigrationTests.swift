//
//  UUANormalizationMigrationTests.swift
//  swift-sdk
//
//  Coverage for SDK-412 (Unknown User Activation naming normalization):
//  stored-event discriminator migration (`dataType` -> `eventType`), public
//  API deprecated alias forwarding, and `IterableIdentityResolution` alias.
//

import XCTest

@testable import IterableSDK

class UUANormalizationMigrationTests: XCTestCase {

    private static let suiteName = "uua.normalization.tests"

    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: Self.suiteName)
        userDefaults.removePersistentDomain(forName: Self.suiteName)
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: Self.suiteName)
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

        let stored = try XCTUnwrap(userDefaults.array(forKey: Const.UserDefault.unknownUserEvents) as? [[AnyHashable: Any]])
        XCTAssertEqual(stored[0][JsonKey.eventType] as? String, EventType.customEvent)
        XCTAssertNil(stored[0][JsonKey.legacyEventType])
    }

    func testUnknownUserUpdateRewritesLegacyDataTypeKeyOnRead() throws {
        let legacyUpdate: [String: Any] = [
            "dataType": EventType.updateUser,
            "email": "user@example.com",
        ]
        userDefaults.set(legacyUpdate, forKey: Const.UserDefault.unknownUserUpdate)

        let defaults = IterableUserDefaults(userDefaults: userDefaults)
        let update = try XCTUnwrap(defaults.unknownUserUpdate)

        XCTAssertEqual(update[JsonKey.eventType] as? String, EventType.updateUser)
        XCTAssertNil(update[JsonKey.legacyEventType])

        let stored = try XCTUnwrap(userDefaults.dictionary(forKey: Const.UserDefault.unknownUserUpdate))
        XCTAssertEqual(stored[JsonKey.eventType] as? String, EventType.updateUser)
        XCTAssertNil(stored[JsonKey.legacyEventType])
    }

    func testUnknownUserEventsLeavesModernEventsUntouched() throws {
        let modern: [[String: Any]] = [[JsonKey.eventType: EventType.customEvent, "eventName": "foo"]]
        userDefaults.set(modern, forKey: Const.UserDefault.unknownUserEvents)

        let defaults = IterableUserDefaults(userDefaults: userDefaults)
        let events = try XCTUnwrap(defaults.unknownUserEvents)
        XCTAssertEqual(events[0][JsonKey.eventType] as? String, EventType.customEvent)
        XCTAssertNil(events[0][JsonKey.legacyEventType])
    }

    func testCriteriaCheckerNormalizesLegacyDataTypeOnInit() {
        let events: [[AnyHashable: Any]] = [
            ["dataType": EventType.customEvent, "eventName": "x"]
        ]
        let checker = CriteriaCompletionChecker(unknownUserCriteria: Data(),
                                                unknownUserEvents: events)
        XCTAssertNil(checker.getMatchedCriteria())
        // Indirect: matcher reads work via JsonKey.eventType, so a legacy event
        // becomes filterable via the new key. Use the public filter to assert.
        let nonCart = checker.getNonCartEvents()
        XCTAssertEqual(nonCart.first?[JsonKey.eventType] as? String, EventType.customEvent)
        XCTAssertNil(nonCart.first?[JsonKey.legacyEventType])
    }

    // MARK: - Sessions inner-struct field alignment (SDK-412 #3)

    func testSessionsEncoderUsesAndroidAlignedFieldNames() throws {
        let sessions = IterableUnknownUserSessions(totalUnknownUserSessionCount: 5,
                                                   lastUnknownUserSession: 22,
                                                   firstUnknownUserSession: 11)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(sessions)) as? [String: Any])
        XCTAssertEqual(json["totalUnknownSessionCount"] as? Int, 5)
        XCTAssertEqual(json["lastUnknownSession"] as? Int, 22)
        XCTAssertEqual(json["firstUnknownSession"] as? Int, 11)
        XCTAssertNil(json["totalUnknownUserSessionCount"])
        XCTAssertNil(json["lastUnknownUserSession"])
        XCTAssertNil(json["firstUnknownUserSession"])
    }

    func testSessionsDecoderAcceptsLegacyAndModernKeys() throws {
        let legacy = #"{"totalUnknownUserSessionCount":3,"lastUnknownUserSession":2,"firstUnknownUserSession":1}"#
            .data(using: .utf8)!
        let modern = #"{"totalUnknownSessionCount":3,"lastUnknownSession":2,"firstUnknownSession":1}"#
            .data(using: .utf8)!
        let fromLegacy = try JSONDecoder().decode(IterableUnknownUserSessions.self, from: legacy)
        let fromModern = try JSONDecoder().decode(IterableUnknownUserSessions.self, from: modern)
        XCTAssertEqual(fromLegacy.totalUnknownUserSessionCount, 3)
        XCTAssertEqual(fromLegacy.lastUnknownUserSession, 2)
        XCTAssertEqual(fromLegacy.firstUnknownUserSession, 1)
        XCTAssertEqual(fromModern.totalUnknownUserSessionCount, 3)
        XCTAssertEqual(fromModern.lastUnknownUserSession, 2)
        XCTAssertEqual(fromModern.firstUnknownUserSession, 1)
    }

    // MARK: - Identity resolution deprecated alias

    func testIdentityResolutionLegacyInitForwardsToNewName() {
        let resolution = IterableIdentityResolution(replayOnVisitorToKnown: true,
                                                    mergeOnUnknownUserToKnown: false)
        XCTAssertEqual(resolution.mergeOnUnknownToKnown, false)
        XCTAssertEqual(resolution.mergeOnUnknownUserToKnown, false)
    }

    func testIdentityResolutionDesignatedInitSetsBothAccessors() {
        let resolution = IterableIdentityResolution(replayOnVisitorToKnown: false,
                                                    mergeOnUnknownToKnown: true)
        XCTAssertEqual(resolution.replayOnVisitorToKnown, false)
        XCTAssertEqual(resolution.mergeOnUnknownToKnown, true)
        XCTAssertEqual(resolution.mergeOnUnknownUserToKnown, true)
    }

    // MARK: - UnknownUserManager deprecated forwarders

    private func makeManager(storage: MockLocalStorage = MockLocalStorage()) -> (UnknownUserManager, MockLocalStorage) {
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        let mgr = UnknownUserManager(config: config,
                                     localStorage: storage,
                                     dateProvider: MockDateProvider(),
                                     notificationStateProvider: MockNotificationStateProvider(enabled: false))
        return (mgr, storage)
    }

    @available(*, deprecated)
    func testDeprecatedTrackUnknownUserEventForwards() {
        let (mgr, storage) = makeManager()
        mgr.trackUnknownUserEvent(name: "viewed", dataFields: ["k": "v"])
        XCTAssertEqual(storage.unknownUserEvents?.count, 1)
    }

    @available(*, deprecated)
    func testDeprecatedTrackUnknownUserPurchaseEventForwards() {
        let (mgr, storage) = makeManager()
        mgr.trackUnknownUserPurchaseEvent(total: 10, items: [], dataFields: nil)
        XCTAssertEqual(storage.unknownUserEvents?.count, 1)
    }

    @available(*, deprecated)
    func testDeprecatedTrackUnknownUserUpdateCartForwards() {
        let (mgr, storage) = makeManager()
        mgr.trackUnknownUserUpdateCart(items: [])
        XCTAssertEqual(storage.unknownUserEvents?.count, 1)
    }

    @available(*, deprecated)
    func testDeprecatedTrackUnknownUserTokenRegistrationForwards() {
        let (mgr, storage) = makeManager()
        mgr.trackUnknownUserTokenRegistration(token: "tok")
        XCTAssertEqual(storage.unknownUserEvents?.count, 1)
    }

    @available(*, deprecated)
    func testDeprecatedTrackUnknownUserUpdateUserForwards() {
        let (mgr, storage) = makeManager()
        mgr.trackUnknownUserUpdateUser(["foo": "bar"])
        XCTAssertNotNil(storage.unknownUserUpdate)
    }

    @available(*, deprecated)
    func testDeprecatedUpdateUnknownUserSessionForwards() {
        let (mgr, storage) = makeManager()
        mgr.updateUnknownUserSession()
        XCTAssertEqual(storage.unknownUserSessions?.itbl_unknown_user_sessions.totalUnknownUserSessionCount, 1)
    }

    @available(*, deprecated)
    func testDeprecatedGetUnknownUserCriteriaForwards() {
        let (mgr, _) = makeManager()
        mgr.getUnknownUserCriteria()
        XCTAssertGreaterThan(mgr.getLastCriteriaFetch(), 0)
    }

    func testUpdateUnknownSessionIncrementsExistingSessions() {
        let (mgr, storage) = makeManager()
        mgr.updateUnknownSession()
        mgr.updateUnknownSession()
        XCTAssertEqual(storage.unknownUserSessions?.itbl_unknown_user_sessions.totalUnknownUserSessionCount, 2)
    }

    func testClearVisitorEventsAndUserDataWipesStorage() {
        let (mgr, storage) = makeManager()
        mgr.trackUnknownEvent(name: "x", dataFields: nil)
        mgr.updateUnknownSession()
        mgr.clearVisitorEventsAndUserData()
        XCTAssertNil(storage.unknownUserEvents)
        XCTAssertNil(storage.unknownUserSessions)
        XCTAssertNil(storage.unknownUserUpdate)
    }
}
