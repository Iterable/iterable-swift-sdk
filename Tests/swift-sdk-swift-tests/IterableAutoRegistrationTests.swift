//
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

        TestUtils.clearUserDefaults()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCallDisableAndEnable() {
        let expectation1 = XCTestExpectation(description: "call register device API")
        let expectation2 = XCTestExpectation(description: "call registerForRemoteNotifications twice")
        let expectation3 = XCTestExpectation(description: "call disable on user1@example.com")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = true
        
        let notificationStateProvider = MockNotificationStateProvider(enabled: true)
        var registerForRemoteNotificationsCount = 0
        notificationStateProvider.callback = {
            registerForRemoteNotificationsCount += 1
            
            if registerForRemoteNotificationsCount == 2 {
                expectation2.fulfill()
            }
        }
        
        IterableAPI.initialize(apiKey: IterableAutoRegistrationTests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        IterableAPI.email = "user1@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // First call, API call to register endpoint
            expectation1.fulfill()
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAutoRegistrationTests.apiKey)])
            networkSession.callback = {(_, _, _)in
                // Second call, API call to disable endpoint
                expectation3.fulfill()
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_DISABLE_DEVICE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAutoRegistrationTests.apiKey)])
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validateElementPresent(withName: ITBL_KEY_TOKEN, andValue: (token as NSData).iteHexadecimalString(), inDictionary: body)
                TestUtils.validateElementPresent(withName: ITBL_KEY_EMAIL, andValue: "user1@example.com", inDictionary: body)
            }
            
            IterableAPI.email = "user2@example.com"
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
    
    func testDoNotCallDisableAndEnableWhenSameValue() {
        let expectation = XCTestExpectation(description: "testDoNotCallDisableAndEnableWhenSameValue")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = true
        // notifications are enabled
        let notificationStateProvider = MockNotificationStateProvider(enabled: true) // Notifications are on.
        
        IterableAPI.initialize(apiKey: IterableAutoRegistrationTests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        let email = "user1@example.com"
        var registerForRemoteNotificationsCount = 0
        notificationStateProvider.callback = {
            registerForRemoteNotificationsCount += 1
        }
        IterableAPI.email = email
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // first call back will be called on register
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAutoRegistrationTests.apiKey)])
            networkSession.callback = {(_, _, _)in
                // Second callback should not happen
                XCTFail("Should not call disable")
            }
            // set same value
            IterableAPI.email = email
            
            // wait for 1 second to make sure that registerForRemoteNotifications is not called
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                XCTAssertEqual(registerForRemoteNotificationsCount, 1) // should be called only once (when setting user1@example.com).
                expectation.fulfill()
            })
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testDoNotCallRegisterForRemoteNotificationsWhenNotificationsAreDisabled() {
        let expectation1 = XCTestExpectation(description: "Call registerToken API endpoint")
        let expectation2 = XCTestExpectation(description: "Disable API endpoint called")
        let expectation3 = XCTestExpectation(description: "Waited for register for remote notificaitions")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        let notificationStateProvider = MockNotificationStateProvider(enabled: false) // Notifications are disabled
        notificationStateProvider.callback = {
            XCTFail("should not call registerForRemoteNotification")
        }
        
        IterableAPI.initialize(apiKey: IterableAutoRegistrationTests.apiKey,
                               config: config,
                               networkSession: networkSession,
                               notificationStateProvider: notificationStateProvider)
        IterableAPI.userId = "userId1"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // first call back will be called on register
            expectation1.fulfill()
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAutoRegistrationTests.apiKey)])
            networkSession.callback = {(_, _, _) in
                // second call back is for disable when we set new user id
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_DISABLE_DEVICE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAutoRegistrationTests.apiKey)])
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validateElementPresent(withName: ITBL_KEY_TOKEN, andValue: (token as NSData).iteHexadecimalString(), inDictionary: body)
                TestUtils.validateElementPresent(withName: ITBL_KEY_USER_ID, andValue: "userId1", inDictionary: body)
                expectation2.fulfill()
            }
            IterableAPI.userId = "userId2"
            
            // wait for 1 second to make sure that registerForRemoteNotifications is not called
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                expectation3.fulfill()
            })
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
    
    func testDoNotCallDisableOrEnableWhenAutoPushIsOff() {
        let expectation = XCTestExpectation(description: "testDoNotCallDisableOrEnableWhenAutoPushIsOff")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = false
        let notificationStateProvider = MockNotificationStateProvider(enabled: true) // Notifications are on.
        notificationStateProvider.callback = {
            XCTFail("should not call registerForRemoteNotification")
        }
        
        IterableAPI.initialize(apiKey: IterableAutoRegistrationTests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        IterableAPI.email = "user1@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // first call back will be called on register
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAutoRegistrationTests.apiKey)])
            networkSession.callback = {(_, _, _)in
                // Second callback should not happen
                XCTFail("should not call disable")
            }
            IterableAPI.email = "user2@example.com"
            
            // wait for 1 second to make sure that registerForRemoteNotifications is not called
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                expectation.fulfill()
            })
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testAutomaticPushRegistrationOnInit() {
        let expectation = XCTestExpectation(description: "testAutomaticPushRegistrationOnInit")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.autoPushRegistration = true
        let notificationStateProvider = MockNotificationStateProvider(enabled: true) // Notifications are on.
        notificationStateProvider.callback = {
            expectation.fulfill()
        }
        
        UserDefaults.standard.set("user1@example.com", forKey:ITBConsts.UserDefaults.emailKey)
        IterableAPI.initialize(apiKey: IterableAutoRegistrationTests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
}
