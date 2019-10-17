//
//  Created by Tapash Majumder on 8/15/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableAutoRegistrationTests: XCTestCase {
    private static let apiKey = "zeeApiKey"
    
    override func setUp() {
        super.setUp()
        
        TestUtils.clearTestUserDefaults()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCallDisableAndEnable() {
        let expectation1 = expectation(description: "call register device API")
        let expectation2 = expectation(description: "call registerForRemoteNotifications twice")
        expectation2.expectedFulfillmentCount = 2
        let expectation3 = expectation(description: "call disable on user1@example.com")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = true
        
        let notificationStateProvider = MockNotificationStateProvider(enabled: false, expectation: expectation2)
        
        IterableAPI.initializeForTesting(apiKey: IterableAutoRegistrationTests.apiKey, config: config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        IterableAPI.email = "user1@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = { _, _, _ in
            // First call, API call to register endpoint
            expectation1.fulfill()
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.registerDeviceToken, queryParams: [])
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath("device.dataFields.notificationsEnabled"), value: false, inDictionary: body)
            
            networkSession.callback = { _, _, _ in
                // Second call, API call to disable endpoint
                expectation3.fulfill()
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.disableDevice, queryParams: [])
                let body = networkSession.getRequestBody() as! [String: Any]
                TestUtils.validateElementPresent(withName: JsonKey.token.jsonKey, andValue: token.hexString(), inDictionary: body)
                TestUtils.validateElementPresent(withName: JsonKey.email.jsonKey, andValue: "user1@example.com", inDictionary: body)
            }
            
            IterableAPI.email = "user2@example.com"
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
    
    func testDoNotCallDisableAndEnableWhenSameValue() {
        let expectation1 = expectation(description: "registerForRemoteNotifications")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = true
        // notifications are enabled
        let notificationStateProvider = MockNotificationStateProvider(enabled: true, expectation: expectation1)
        
        IterableAPI.initializeForTesting(apiKey: IterableAutoRegistrationTests.apiKey, config: config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        let email = "user1@example.com"
        IterableAPI.email = email
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = { _, _, _ in
            // first call back will be called on register
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.registerDeviceToken, queryParams: [])
            networkSession.callback = { _, _, _ in
                // Second callback should not happen
                XCTFail("Should not call disable")
            }
            // set same value
            IterableAPI.email = email
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDoNotCallDisableOrEnableWhenAutoPushIsOff() {
        let expectation1 = expectation(description: "do not call register for remote")
        expectation1.isInverted = true
        
        let networkSession = MockNetworkSession()
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = false
        let notificationStateProvider = MockNotificationStateProvider(enabled: true, expectation: expectation1)
        
        IterableAPI.initializeForTesting(apiKey: IterableAutoRegistrationTests.apiKey, config: config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        IterableAPI.email = "user1@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = { _, _, _ in
            // first call back will be called on register
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.registerDeviceToken, queryParams: [])
            networkSession.callback = { _, _, _ in
                // Second callback should not happen
                XCTFail("should not call disable")
            }
            IterableAPI.email = "user2@example.com"
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation1], timeout: 1.0)
    }
    
    func testAutomaticPushRegistrationOnInit() {
        let expectation1 = expectation(description: "call register for remote")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = true
        let notificationStateProvider = MockNotificationStateProvider(enabled: true, expectation: expectation1)
        
        TestUtils.getTestUserDefaults().set("user1@example.com", forKey: Const.UserDefaults.emailKey)
        IterableAPI.initializeForTesting(apiKey: IterableAutoRegistrationTests.apiKey, config: config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}
