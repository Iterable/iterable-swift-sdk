//
//  Created by Tapash Majumder on 8/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class LocalStorageTests: XCTestCase {
    func testUserIdAndEmail() throws {
        var localStorage = UserDefaultsLocalStorage(userDefaults: TestUtils.getTestUserDefaults())
        let userId = "zeeUserId"
        let email = "user@example.com"
        localStorage.userId = userId
        localStorage.email = email
        
        XCTAssertEqual(localStorage.userId, userId)
        XCTAssertEqual(localStorage.email, email)
    }
    
    func testDDLChecked() throws {
        var localStorage = UserDefaultsLocalStorage(userDefaults: TestUtils.getTestUserDefaults())
        localStorage.ddlChecked = true
        XCTAssertTrue(localStorage.ddlChecked)
        
        localStorage.ddlChecked = false
        XCTAssertFalse(localStorage.ddlChecked)
    }
    
    func testAttributionInfo() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = UserDefaultsLocalStorage(userDefaults: TestUtils.getTestUserDefaults())
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
                       "\(JsonKey.campaignId.jsonKey): \(attributionInfo.campaignId), \(JsonKey.templateId.jsonKey): \(attributionInfo.templateId), \(JsonKey.messageId.jsonKey): \(attributionInfo.messageId)")
    }
    
    func testPayload() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = UserDefaultsLocalStorage(userDefaults: TestUtils.getTestUserDefaults())
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
    
    func testDeviceId() {
        var localStorage = UserDefaultsLocalStorage(userDefaults: TestUtils.getTestUserDefaults())
        let deviceId = UUID().uuidString
        localStorage.deviceId = deviceId
        XCTAssertEqual(localStorage.deviceId, deviceId)
    }
    
    func testSdkVersion() {
        var localStorage = UserDefaultsLocalStorage(userDefaults: TestUtils.getTestUserDefaults())
        let sdkVersion = "6.0.2"
        localStorage.sdkVersion = sdkVersion
        XCTAssertEqual(localStorage.sdkVersion, sdkVersion)
    }
}
