//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class LocalStorageTests: XCTestCase {
    override func setUp() {
        super.setUp()
        LocalStorageTests.clearTestUserDefaults()
    }
    
    static let userDefaultsSuiteName = "localstorage.tests"
    
    private static func getTestUserDefaults() -> UserDefaults {
        UserDefaults(suiteName: userDefaultsSuiteName)!
    }
    
    private static func clearTestUserDefaults() {
        getTestUserDefaults().removePersistentDomain(forName: userDefaultsSuiteName)
    }
    
    func testUserIdAndEmail() throws {
        var localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let userId = "zeeUserId"
        let email = "user@example.com"
        localStorage.userId = userId
        localStorage.email = email
        
        XCTAssertEqual(localStorage.userId, userId)
        XCTAssertEqual(localStorage.email, email)
    }
    
    func testAuthDataInKeychain() {
        let testUserDefaults = LocalStorageTests.getTestUserDefaults()
        let testKeychain = IterableKeychain.init(wrapper: KeychainWrapper.init(serviceName: "test-localstorage"))
        
        var localStorage = LocalStorage(userDefaults: testUserDefaults,
                                        keychain: testKeychain)
        
        let userId = "user-id"
        
        localStorage.userId = userId
        
        XCTAssertNil(testUserDefaults.string(forKey: Const.UserDefault.userIdKey))
        
        XCTAssertEqual(testKeychain.userId, userId)
        
        let email = "test@example.com"
        
        localStorage.email = email
        
        XCTAssertNil(testUserDefaults.string(forKey: Const.UserDefault.emailKey))
        
        XCTAssertEqual(testKeychain.email, email)
        
        let authToken = "token"
        
        localStorage.authToken = authToken
        
        XCTAssertNil(testUserDefaults.string(forKey: Const.UserDefault.authTokenKey))
        
        XCTAssertEqual(testKeychain.authToken, authToken)
    }
    
    func testDDLChecked() throws {
        var localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        localStorage.ddlChecked = true
        XCTAssertTrue(localStorage.ddlChecked)
        
        localStorage.ddlChecked = false
        XCTAssertFalse(localStorage.ddlChecked)
    }
    
    func testAttributionInfo() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let attributionInfo = IterableAttributionInfo(campaignId: 1, templateId: 2, messageId: "3")
        let currentDate = Date()
        let expiration = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: currentDate)!
        localStorage.save(attributionInfo: attributionInfo, withExpiration: expiration)
        // 23 hours, not expired, still present
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: currentDate)!
        let fromLocalStorage: IterableAttributionInfo = localStorage.getAttributionInfo(currentDate: mockDateProvider.currentDate)!
        XCTAssert(fromLocalStorage == attributionInfo)
        
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 25, to: currentDate)!
        let fromLocalStorage2: IterableAttributionInfo? = localStorage.getAttributionInfo(currentDate: mockDateProvider.currentDate)
        XCTAssertNil(fromLocalStorage2)
        
        XCTAssertEqual(attributionInfo.description,
                       "\(JsonKey.campaignId): \(attributionInfo.campaignId), \(JsonKey.templateId): \(attributionInfo.templateId), \(JsonKey.messageId): \(attributionInfo.messageId)")
    }
    
    func testPayload() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let payload: [AnyHashable: Any] = [
            "email": "ilya@iterable.com",
            "device": [
                "token": "foo",
                "platform": "bar",
                "applicationName": "baz",
                "dataFields": [
                    "name": "green",
                    "localizedModel": "eggs",
                    "userInterfaceIdiom": "and",
                    "identifierForVendor": "ham",
                    "systemName": "iterable",
                    "systemVersion": "is",
                    "model": "awesome",
                ],
            ],
        ]
        let currentDate = Date()
        let expiration = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: currentDate)!
        localStorage.save(payload: payload, withExpiration: expiration)
        // 23 hours, not expired, still present
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: currentDate)!
        let fromLocalStorage: [AnyHashable: Any] = localStorage.getPayload(currentDate: mockDateProvider.currentDate)!
        XCTAssertTrue(NSDictionary(dictionary: payload).isEqual(to: fromLocalStorage))
        
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 25, to: currentDate)!
        let fromLocalStorage2: [AnyHashable: Any]? = localStorage.getPayload(currentDate: mockDateProvider.currentDate)
        XCTAssertNil(fromLocalStorage2)
    }
    
    func testSaveBadPayload() throws {
        class A {}
        
        let mockDateProvider = MockDateProvider()
        let localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let payload: [AnyHashable: Any] = [
            "email": "ilya@iterable.com",
            "device": [
                "token": "foo",
                "platform": "bar",
                "applicationName": "baz",
                "dataFields": [
                    "name": "green",
                    "localizedModel": "eggs",
                    "userInterfaceIdiom": "and",
                    "identifierForVendor": "ham",
                    "systemName": "iterable",
                    "systemVersion": "is",
                    "model": "awesome",
                ],
            ],
            "someClass": A(),
        ]
        let currentDate = Date()
        let expiration = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: currentDate)!
        localStorage.save(payload: payload, withExpiration: expiration)
        
        // 23 hours, not expired, still present
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: currentDate)!
        let fromLocalStorage = localStorage.getPayload(currentDate: mockDateProvider.currentDate)
        XCTAssertNil(fromLocalStorage)
    }
    
    func testDeviceId() {
        var localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let deviceId = UUID().uuidString
        localStorage.deviceId = deviceId
        XCTAssertEqual(localStorage.deviceId, deviceId)
    }
    
    func testSdkVersion() {
        var localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let sdkVersion = "6.0.2"
        localStorage.sdkVersion = sdkVersion
        XCTAssertEqual(localStorage.sdkVersion, sdkVersion)
    }
    
    func testAuthToken() {
        var localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let authToken = "03.10.11"
        localStorage.authToken = authToken
        XCTAssertEqual(localStorage.authToken, authToken)
        
        let newAuthToken = "09.09.1999"
        localStorage.authToken = newAuthToken
        XCTAssertEqual(localStorage.authToken, newAuthToken)
        
        localStorage.authToken = nil
        XCTAssertNil(localStorage.authToken)
    }
    
    func testOfflineMode() {
        let saver = { (storage: LocalStorageProtocol, value: Bool) -> Void in
            var localStorage = storage
            localStorage.offlineMode = value
        }
        let retriever = { (storage: LocalStorageProtocol) -> Bool? in
            storage.offlineMode
        }
        
        testLocalStorage(saver: saver, retriever: retriever, value: true)
        testLocalStorage(saver: saver, retriever: retriever, value: false)
    }
    
    private func testLocalStorage<T>(saver: (LocalStorageProtocol, T) -> Void,
                                     retriever: (LocalStorageProtocol) -> T?, value: T) where T: Equatable {
        let localStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        saver(localStorage, value)
        let retrievedLocalStorage = LocalStorage(userDefaults: LocalStorageTests.getTestUserDefaults())
        let retrieved = retriever(retrievedLocalStorage)
        XCTAssertEqual(value, retrieved)
    }
}
