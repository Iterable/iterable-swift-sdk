//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class KeychainWrapperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSave() throws {
        let wrapper = KeychainWrapper(serviceName: "test-keychain")
        let valueString = "this is a string value"
        let value = valueString.data(using: .utf8)!
        let key = "zee-key"
        let isSaved = wrapper.set(value, forKey: key)
        
        let retrievedData = wrapper.data(forKey: key)!
        let retrieved = String(data: retrievedData, encoding: .utf8)!
        
        XCTAssertTrue(isSaved)
        XCTAssertEqual(retrieved, valueString)
    }

    func testRewrite() throws {
        let wrapper = KeychainWrapper(serviceName: "test-keychain")
        let key = "zee-key"

        let valueString = "this is a string value"
        let value = valueString.data(using: .utf8)!
        XCTAssertTrue(wrapper.set(value, forKey: key))

        let newValueString = "new string"
        let newValue = newValueString.data(using: .utf8)!
        XCTAssertTrue(wrapper.set(newValue, forKey: key))

        let retrievedData = wrapper.data(forKey: key)!
        let retrieved = String(data: retrievedData, encoding: .utf8)!
        
        XCTAssertEqual(retrieved, newValueString)
    }
    
    func testDelete() throws {
        let wrapper = KeychainWrapper(serviceName: "test-keychain")
        let key = "zee-key"

        let valueString = "this is a string value"
        let value = valueString.data(using: .utf8)!
        XCTAssertTrue(wrapper.set(value, forKey: key))

        wrapper.removeValue(forKey: key)
        XCTAssertNil(wrapper.data(forKey: key))
    }
    
    func testRemoveAll() throws {
        let wrapper = KeychainWrapper(serviceName: UUID().uuidString)
        let key1 = "zee-key-1"
        let key2 = "zee-key-2"

        XCTAssertNil(wrapper.data(forKey:key1))
        XCTAssertNil(wrapper.data(forKey:key2))

        XCTAssertTrue(wrapper.set("zee value1".data(using: .utf8)!, forKey: key1))
        XCTAssertTrue(wrapper.set("zee value2".data(using: .utf8)!, forKey: key2))

        XCTAssertNotNil(wrapper.data(forKey:key1))
        XCTAssertNotNil(wrapper.data(forKey:key2))

        wrapper.removeAll()

        XCTAssertNil(wrapper.data(forKey: key1))
        XCTAssertNil(wrapper.data(forKey: key2))
    }

    // MARK: - Isolated Service Name Tests

    func testIsolatedServiceNameWithBundleId() throws {
        // Get the isolated service name
        let isolatedName = KeychainWrapper.isolatedServiceName()

        // Should contain the base service name
        XCTAssertTrue(isolatedName.hasPrefix("itbl_keychain"))

        // If there's a bundle identifier, it should be appended
        if let bundleId = Bundle.main.bundleIdentifier {
            XCTAssertEqual(isolatedName, "itbl_keychain.\(bundleId)")
        } else {
            // If no bundle identifier (unlikely in tests), should fall back to base name
            XCTAssertEqual(isolatedName, "itbl_keychain")
        }
    }

    func testIsolatedServiceNameWithCustomBaseName() throws {
        let customBaseName = "custom_service"
        let isolatedName = KeychainWrapper.isolatedServiceName(baseServiceName: customBaseName)

        if let bundleId = Bundle.main.bundleIdentifier {
            XCTAssertEqual(isolatedName, "\(customBaseName).\(bundleId)")
        } else {
            XCTAssertEqual(isolatedName, customBaseName)
        }
    }

    func testLegacyServiceName() throws {
        let legacyName = KeychainWrapper.legacyServiceName
        XCTAssertEqual(legacyName, "itbl_keychain")
    }

    func testKeychainIsolationBetweenDifferentServiceNames() throws {
        let serviceName1 = "test-keychain-app1-\(UUID().uuidString)"
        let serviceName2 = "test-keychain-app2-\(UUID().uuidString)"

        let wrapper1 = KeychainWrapper(serviceName: serviceName1)
        let wrapper2 = KeychainWrapper(serviceName: serviceName2)

        let key = "shared-key"
        let value1 = "value-from-app1"
        let value2 = "value-from-app2"

        // Store different values with the same key in different service names
        XCTAssertTrue(wrapper1.set(value1.data(using: .utf8)!, forKey: key))
        XCTAssertTrue(wrapper2.set(value2.data(using: .utf8)!, forKey: key))

        // Verify each wrapper returns its own value (no collision)
        let retrieved1 = String(data: wrapper1.data(forKey: key)!, encoding: .utf8)!
        let retrieved2 = String(data: wrapper2.data(forKey: key)!, encoding: .utf8)!

        XCTAssertEqual(retrieved1, value1)
        XCTAssertEqual(retrieved2, value2)
        XCTAssertNotEqual(retrieved1, retrieved2)

        // Clean up
        wrapper1.removeAll()
        wrapper2.removeAll()
    }

    func testIsolatedAndLegacyKeychainDontCollide() throws {
        // Simulate the scenario where two apps share a keychain access group
        // but should have isolated storage due to different service names

        let legacyServiceName = "legacy-service-\(UUID().uuidString)"
        let isolatedServiceName1 = "\(legacyServiceName).com.app1"
        let isolatedServiceName2 = "\(legacyServiceName).com.app2"

        let legacyWrapper = KeychainWrapper(serviceName: legacyServiceName)
        let isolatedWrapper1 = KeychainWrapper(serviceName: isolatedServiceName1)
        let isolatedWrapper2 = KeychainWrapper(serviceName: isolatedServiceName2)

        let key = "itbl_auth_token"

        // Simulate old SDK storing in legacy location
        let legacyToken = "legacy-shared-token"
        XCTAssertTrue(legacyWrapper.set(legacyToken.data(using: .utf8)!, forKey: key))

        // App 1 stores its own token
        let app1Token = "app1-unique-token"
        XCTAssertTrue(isolatedWrapper1.set(app1Token.data(using: .utf8)!, forKey: key))

        // App 2 stores its own token
        let app2Token = "app2-unique-token"
        XCTAssertTrue(isolatedWrapper2.set(app2Token.data(using: .utf8)!, forKey: key))

        // Verify all three have independent storage
        XCTAssertEqual(String(data: legacyWrapper.data(forKey: key)!, encoding: .utf8), legacyToken)
        XCTAssertEqual(String(data: isolatedWrapper1.data(forKey: key)!, encoding: .utf8), app1Token)
        XCTAssertEqual(String(data: isolatedWrapper2.data(forKey: key)!, encoding: .utf8), app2Token)

        // Clean up
        legacyWrapper.removeAll()
        isolatedWrapper1.removeAll()
        isolatedWrapper2.removeAll()
    }
}
