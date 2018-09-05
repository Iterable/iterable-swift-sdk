//
//
//  Created by Tapash Majumder on 8/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK


class LocalStorageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUserIdAndEmail() throws {
        let mockDateProvider = MockDateProvider()
        var localStorage = UserDefaultsLocalStorage(dateProvider: mockDateProvider)
        let userId = "zeeUserId"
        let email = "user@example.com"
        localStorage.userId = userId
        localStorage.email = email
        
        XCTAssertEqual(localStorage.userId, userId)
        XCTAssertEqual(localStorage.email, email)
    }

    func testDDLChecked() throws {
        let mockDateProvider = MockDateProvider()
        var localStorage = UserDefaultsLocalStorage(dateProvider: mockDateProvider)
        localStorage.ddlChecked = true
        XCTAssertTrue(localStorage.ddlChecked)
        
        localStorage.ddlChecked = false
        XCTAssertFalse(localStorage.ddlChecked)
    }

    func testAttributionInfo() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = UserDefaultsLocalStorage(dateProvider: mockDateProvider)
        let attributionInfo = IterableAttributionInfo(campaignId: 1, templateId: 2, messageId: "3")
        let currentDate = Date()
        let expiration = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: currentDate)!
        localStorage.save(attributionInfo: attributionInfo, withExpiration: expiration)
        // 23 hours, not expired, still present
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: currentDate)!
        let fromLocalStorage:IterableAttributionInfo = localStorage.attributionInfo!
        XCTAssert(fromLocalStorage == attributionInfo)

        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 25, to: currentDate)!
        let fromLocalStorage2:IterableAttributionInfo? = localStorage.attributionInfo
        XCTAssertNil(fromLocalStorage2)
    }
    
    func testPayload() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = UserDefaultsLocalStorage(dateProvider: mockDateProvider)
        let payload: [AnyHashable : Any] = [
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
                    "model": "awesome"
                ]
            ]
        ]
        let currentDate = Date()
        let expiration = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: currentDate)!
        localStorage.save(payload: payload, withExpiration: expiration)
        // 23 hours, not expired, still present
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: currentDate)!
        let fromLocalStorage:[AnyHashable : Any] = localStorage.payload!
        XCTAssertTrue(NSDictionary(dictionary: payload).isEqual(to: fromLocalStorage))
        
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 25, to: currentDate)!
        let fromLocalStorage2:[AnyHashable : Any]? = localStorage.payload
        XCTAssertNil(fromLocalStorage2)
    }
    
    func testDeviceId() {
        let mockDateProvider = MockDateProvider()
        var localStorage: LocalStorageProtocol = UserDefaultsLocalStorage(dateProvider: mockDateProvider)
        let deviceId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        localStorage.deviceId = deviceId
        XCTAssertEqual(localStorage.deviceId, deviceId)
    }

    func testSdkVersion() {
        let mockDateProvider = MockDateProvider()
        var localStorage: LocalStorageProtocol = UserDefaultsLocalStorage(dateProvider: mockDateProvider)
        let sdkVersion = "6.0.2"
        localStorage.deviceId = sdkVersion
        XCTAssertEqual(localStorage.deviceId, sdkVersion)
    }
}
