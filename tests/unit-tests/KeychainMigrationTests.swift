//
//  Copyright © 2025 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class KeychainMigrationTests: XCTestCase {

    private var legacyServiceName: String!
    private var isolatedServiceName: String!

    override func setUpWithError() throws {
        // Use unique service names for each test to avoid interference
        let testId = UUID().uuidString
        legacyServiceName = "test-legacy-\(testId)"
        isolatedServiceName = "test-isolated-\(testId)"
    }

    override func tearDownWithError() throws {
        // Clean up any leftover keychain data
        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)
        legacyWrapper.removeAll()
        isolatedWrapper.removeAll()
    }

    // MARK: - Migration Tests

    func testMigrationFromLegacyToIsolatedKeychain() throws {
        // Setup: Create legacy keychain with data
        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)

        let testEmail = "test@example.com"
        let testUserId = "user123"
        let testAuthToken = "jwt-token-abc"

        // Store data in legacy keychain
        XCTAssertTrue(legacyWrapper.set(testEmail.data(using: .utf8)!, forKey: Const.Keychain.Key.email))
        XCTAssertTrue(legacyWrapper.set(testUserId.data(using: .utf8)!, forKey: Const.Keychain.Key.userId))
        XCTAssertTrue(legacyWrapper.set(testAuthToken.data(using: .utf8)!, forKey: Const.Keychain.Key.authToken))

        // Verify isolated keychain is empty before migration
        XCTAssertNil(isolatedWrapper.data(forKey: Const.Keychain.Key.email))
        XCTAssertNil(isolatedWrapper.data(forKey: Const.Keychain.Key.userId))
        XCTAssertNil(isolatedWrapper.data(forKey: Const.Keychain.Key.authToken))

        // Create IterableKeychain with migration support
        let keychain = IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: legacyWrapper)

        // Perform migration
        let migrated = keychain.migrateFromLegacy()

        // Verify migration occurred
        XCTAssertTrue(migrated)

        // Verify data is now in isolated keychain
        XCTAssertEqual(keychain.email, testEmail)
        XCTAssertEqual(keychain.userId, testUserId)
        XCTAssertEqual(keychain.authToken, testAuthToken)

        // Verify data was removed from legacy keychain
        XCTAssertNil(legacyWrapper.data(forKey: Const.Keychain.Key.email))
        XCTAssertNil(legacyWrapper.data(forKey: Const.Keychain.Key.userId))
        XCTAssertNil(legacyWrapper.data(forKey: Const.Keychain.Key.authToken))
    }

    func testMigrationDoesNotOverwriteExistingData() throws {
        // Setup: Create both keychains with data
        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)

        let legacyEmail = "legacy@example.com"
        let isolatedEmail = "isolated@example.com"
        let legacyUserId = "legacy-user"
        let legacyAuthToken = "legacy-token"

        // Store data in legacy keychain
        XCTAssertTrue(legacyWrapper.set(legacyEmail.data(using: .utf8)!, forKey: Const.Keychain.Key.email))
        XCTAssertTrue(legacyWrapper.set(legacyUserId.data(using: .utf8)!, forKey: Const.Keychain.Key.userId))
        XCTAssertTrue(legacyWrapper.set(legacyAuthToken.data(using: .utf8)!, forKey: Const.Keychain.Key.authToken))

        // Store email in isolated keychain (should not be overwritten)
        XCTAssertTrue(isolatedWrapper.set(isolatedEmail.data(using: .utf8)!, forKey: Const.Keychain.Key.email))

        // Create IterableKeychain with migration support
        let keychain = IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: legacyWrapper)

        // Perform migration
        let migrated = keychain.migrateFromLegacy()

        // Migration should still return true (for userId and authToken)
        XCTAssertTrue(migrated)

        // Email should NOT have been overwritten - isolated value preserved
        XCTAssertEqual(keychain.email, isolatedEmail)

        // UserId and authToken should be migrated
        XCTAssertEqual(keychain.userId, legacyUserId)
        XCTAssertEqual(keychain.authToken, legacyAuthToken)

        // Legacy email should NOT be removed (since we didn't migrate it)
        XCTAssertNotNil(legacyWrapper.data(forKey: Const.Keychain.Key.email))

        // Legacy userId and authToken should be removed
        XCTAssertNil(legacyWrapper.data(forKey: Const.Keychain.Key.userId))
        XCTAssertNil(legacyWrapper.data(forKey: Const.Keychain.Key.authToken))
    }

    func testMigrationWithNoLegacyData() throws {
        // Setup: Create empty keychains
        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)

        // Create IterableKeychain with migration support
        let keychain = IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: legacyWrapper)

        // Perform migration
        let migrated = keychain.migrateFromLegacy()

        // No migration should occur
        XCTAssertFalse(migrated)

        // Verify keychain is still empty
        XCTAssertNil(keychain.email)
        XCTAssertNil(keychain.userId)
        XCTAssertNil(keychain.authToken)
    }

    func testMigrationWithNoLegacyWrapper() throws {
        // Setup: Create IterableKeychain without legacy wrapper
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)
        let keychain = IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: nil)

        // Perform migration
        let migrated = keychain.migrateFromLegacy()

        // No migration should occur without legacy wrapper
        XCTAssertFalse(migrated)
    }

    func testMigrationOfPartialData() throws {
        // Setup: Create legacy keychain with only some data
        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)

        let testEmail = "partial@example.com"

        // Only store email in legacy keychain
        XCTAssertTrue(legacyWrapper.set(testEmail.data(using: .utf8)!, forKey: Const.Keychain.Key.email))

        // Create IterableKeychain with migration support
        let keychain = IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: legacyWrapper)

        // Perform migration
        let migrated = keychain.migrateFromLegacy()

        // Migration should occur
        XCTAssertTrue(migrated)

        // Email should be migrated
        XCTAssertEqual(keychain.email, testEmail)

        // Other fields should remain nil
        XCTAssertNil(keychain.userId)
        XCTAssertNil(keychain.authToken)

        // Legacy email should be removed
        XCTAssertNil(legacyWrapper.data(forKey: Const.Keychain.Key.email))
    }

    func testMigrationOfUserIdUnknownUser() throws {
        // Setup: Create legacy keychain with userIdUnknownUser
        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)

        let testUserIdUnknownUser = "unknown-user-123"

        // Store userIdUnknownUser in legacy keychain
        XCTAssertTrue(legacyWrapper.set(testUserIdUnknownUser.data(using: .utf8)!, forKey: Const.Keychain.Key.userIdUnknownUser))

        // Create IterableKeychain with migration support
        let keychain = IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: legacyWrapper)

        // Perform migration
        let migrated = keychain.migrateFromLegacy()

        // Migration should occur
        XCTAssertTrue(migrated)

        // userIdUnknownUser should be migrated
        XCTAssertEqual(keychain.userIdUnknownUser, testUserIdUnknownUser)

        // Legacy userIdUnknownUser should be removed
        XCTAssertNil(legacyWrapper.data(forKey: Const.Keychain.Key.userIdUnknownUser))
    }

    func testMultipleMigrationCallsAreIdempotent() throws {
        // Setup: Create legacy keychain with data
        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper = KeychainWrapper(serviceName: isolatedServiceName)

        let testEmail = "idempotent@example.com"

        // Store data in legacy keychain
        XCTAssertTrue(legacyWrapper.set(testEmail.data(using: .utf8)!, forKey: Const.Keychain.Key.email))

        // Create IterableKeychain with migration support
        let keychain = IterableKeychain(wrapper: isolatedWrapper, legacyWrapper: legacyWrapper)

        // Perform migration multiple times
        let migrated1 = keychain.migrateFromLegacy()
        let migrated2 = keychain.migrateFromLegacy()
        let migrated3 = keychain.migrateFromLegacy()

        // First migration should succeed
        XCTAssertTrue(migrated1)

        // Subsequent migrations should not perform any action (no data to migrate)
        XCTAssertFalse(migrated2)
        XCTAssertFalse(migrated3)

        // Email should still be correct
        XCTAssertEqual(keychain.email, testEmail)
    }
}
