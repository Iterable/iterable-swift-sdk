//
//  IterableAPITests.swift
//  swift-sdk-swift-tests
//
//  Created by Tapash Majumder on 7/24/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest
import UserNotifications

@testable import IterableSDK

class IterableAPITests: XCTestCase {
    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: ITBConsts.UserDefaults.emailKey)
        UserDefaults.standard.removeObject(forKey: ITBConsts.UserDefaults.userIdKey)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTrackEventWithNoEmailOrUser() {
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = nil
        IterableAPI.userId = nil
        IterableAPI.track(event: eventName)
        XCTAssertNil(networkSession.request)
    }

    func testTrackEventWithEmail() {
        let expectation = XCTestExpectation(description: "testTrackEventWithEmail")
        
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = IterableAPITests.email
        IterableAPI.track(event: eventName, dataFields: nil, onSuccess: { (json) in
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_TRACK, queryParams: [(name: "api_key", IterableAPITests.apiKey)])
            let body = networkSession.getRequestBody()
            TestUtils.validateElementPresent(withName: ITBL_KEY_EVENT_NAME, andValue: eventName, inDictionary: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_EMAIL, andValue: IterableAPITests.email, inDictionary: body)
            expectation.fulfill()
        }) { (reason, data) in
            expectation.fulfill()
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }

        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testTrackEventBadNetwork() {
        let expectation = XCTestExpectation(description: "testTrackEventBadNetwork")
        
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 502)
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        IterableAPI.track(
            event: eventName,
            dataFields: nil,
            onSuccess:{json in
                // fail on success
                expectation.fulfill()
                XCTFail("did not expect success")
            },
            onFailure: {(reason, data) in expectation.fulfill()})
        
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testUpdateUser() {
        let expectation = XCTestExpectation(description: "testUpdateUser")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = IterableAPITests.email
        let dataFields: Dictionary<String, String> = ["var1" : "val1", "var2" : "val2"]
        IterableAPI.updateUser(dataFields, mergeNestedObjects: true, onSuccess: {(json) in
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_UPDATE_USER, queryParams: [(name: "api_key", IterableAPITests.apiKey)])
            let body = networkSession.getRequestBody()
            TestUtils.validateElementPresent(withName: ITBL_KEY_EMAIL, andValue: IterableAPITests.email, inDictionary: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_MERGE_NESTED, andValue: true, inDictionary: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_DATA_FIELDS, andValue: dataFields, inDictionary: body)
            expectation.fulfill()
        }) {(reason, _) in
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testUpdateEmail() {
        let expectation = XCTestExpectation(description: "testUpdateEmail")

        let newEmail = "new_user@example.com"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = IterableAPITests.email
        IterableAPI.updateEmail(newEmail,
                                onSuccess: {json in
                                    TestUtils.validate(request: networkSession.request!,
                                                       requestType: .post,
                                                       apiEndPoint: ITBConsts.apiEndpoint,
                                                       path: ENDPOINT_UPDATE_EMAIL,
                                                       queryParams: [(name: "api_key", value: IterableAPITests.apiKey)])
                                    let body = networkSession.getRequestBody()
                                    TestUtils.validateElementPresent(withName: ITBL_KEY_NEW_EMAIL, andValue: newEmail, inDictionary: body)
                                    TestUtils.validateElementPresent(withName: ITBL_KEY_CURRENT_EMAIL, andValue: IterableAPITests.email, inDictionary: body)
                                    XCTAssertEqual(IterableAPI.email, newEmail)
                                    expectation.fulfill()
                                },
                                onFailure: {(reason, _) in
                                    expectation.fulfill()
                                    if let reason = reason {
                                        XCTFail("encountered error: \(reason)")
                                    } else {
                                        XCTFail("encountered error")
                                    }
                                })

        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testRegisterTokenNilAppName() {
        let expectation = XCTestExpectation(description: "testRegisterToken")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        
        IterableAPI.register(token: "zeeToken".data(using: .utf8)!, onSuccess: { (dict) in
            XCTFail("did not expect success here")
        }) {(_,_) in
            // failure
            expectation.fulfill()
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: 1.0)
    }

    func testRegisterTokenNilEmailAndUserId() {
        let expectation = XCTestExpectation(description: "testRegisterToken")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = nil
        IterableAPI.userId = nil
        
        IterableAPI.register(token: "zeeToken".data(using: .utf8)!, onSuccess: { (dict) in
            XCTFail("did not expect success here")
        }) {(_,_) in
            // failure
            expectation.fulfill()
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: 10.0)
    }

    func testRegisterToken() {
        let expectation = XCTestExpectation(description: "testRegisterToken")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { (dict) in
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateElementPresent(withName: "email", andValue: "user@example.com", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.applicationName"), value: "my-push-integration", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.platform"), value: ITBL_KEY_APNS_SANDBOX, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.token"), value: (token as NSData).iteHexadecimalString(), inDictionary: body)

            expectation.fulfill()
        }) {(reason, _) in
            // failure
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testDisableDeviceNotRegistered() {
        let expectation = XCTestExpectation(description: "testDisableDevice")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"

        IterableAPI.disableDeviceForCurrentUser(withOnSuccess: { (json) in
            XCTFail("did not expect success here")
        }) { (errorMessage, data) in
            expectation.fulfill()
        }

        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testDisableDeviceForCurrentUser() {
        let expectation = XCTestExpectation(description: "testDisableDeviceForCurrentUser")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token)
        networkSession.callback = {(data, response, error) in
            networkSession.callback = nil
            IterableAPI.disableDeviceForCurrentUser(withOnSuccess: { (json) in
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_DISABLE_DEVICE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
                TestUtils.validateElementPresent(withName: ITBL_KEY_TOKEN, andValue: (token as NSData).iteHexadecimalString(), inDictionary: body)
                TestUtils.validateElementPresent(withName: ITBL_KEY_EMAIL, andValue: "user@example.com", inDictionary: body)
                expectation.fulfill()
            }) { (errorMessage, data) in
                expectation.fulfill()
            }
        }

        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testDisableDeviceForAllUsers() {
        let expectation = XCTestExpectation(description: "testDisableDeviceForAllUsers")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(data, response, error) in
            networkSession.callback = nil
            IterableAPI.disableDeviceForAllUsers(withOnSuccess: { (json) in
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_DISABLE_DEVICE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
                TestUtils.validateElementPresent(withName: ITBL_KEY_TOKEN, andValue: (token as NSData).iteHexadecimalString(), inDictionary: body)
                TestUtils.validateElementNotPresent(withName: ITBL_KEY_EMAIL, inDictionary: body)
                TestUtils.validateElementNotPresent(withName: ITBL_KEY_USER_ID, inDictionary: body)
                expectation.fulfill()
            }) { (errorMessage, data) in
                expectation.fulfill()
            }
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testTrackPurchaseNoUserIdOrEmail() {
        let expectation = XCTestExpectation(description: "testTrackPurchaseNoUserIdOrEmail")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)

        IterableAPI.track(purchase: 10.0, items: [], dataFields: nil, onSuccess: { (json) in
            // no userid or email should fail
            XCTFail("did not expect success here")
        }) { (errorMessage, data) in
            expectation.fulfill()
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testTrackPurchaseWithUserId() {
        let expectation = XCTestExpectation(description: "testTrackPurchaseWithUserId")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.userId = "zeeUserId"
        
        IterableAPI.track(purchase: 10.55, items: [], dataFields: nil, onSuccess: { (json) in
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_COMMERCE_TRACK_PURCHASE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            TestUtils.validateMatch(keyPath: KeyPath("\(ITBL_KEY_USER).\(ITBL_KEY_USER_ID)"), value: "zeeUserId", inDictionary: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_TOTAL, andValue: 10.55, inDictionary: body)

            expectation.fulfill()
        }) { (reason, _) in
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testTrackPurchaseWithEmail() {
        let expectation = XCTestExpectation(description: "testTrackPurchaseWithEmail")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let total = NSNumber(value: 15.32)
        let items = [CommerceItem(id: "id1", name: "myCommerceItem", price: 5.0, quantity: 2)]
        
        IterableAPI.track(purchase: total, items: items, dataFields: nil, onSuccess: { (json) in
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_COMMERCE_TRACK_PURCHASE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            TestUtils.validateMatch(keyPath: KeyPath("\(ITBL_KEY_USER).\(ITBL_KEY_EMAIL)"), value: "user@example.com", inDictionary: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_TOTAL, andValue: total, inDictionary: body)
            let itemsElement = body[ITBL_KEY_ITEMS] as! [[AnyHashable : Any]]
            XCTAssertEqual(itemsElement.count, 1)
            let firstElement = itemsElement[0]
            TestUtils.validateElementPresent(withName: "id", andValue: "id1", inDictionary: firstElement)
            TestUtils.validateElementPresent(withName: "name", andValue: "myCommerceItem", inDictionary: firstElement)
            TestUtils.validateElementPresent(withName: "price", andValue: 5.0, inDictionary: firstElement)
            TestUtils.validateElementPresent(withName: "quantity", andValue: 2, inDictionary: firstElement)
            expectation.fulfill()
        }) { (reason, _) in
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        wait(for: [expectation], timeout: testExpectationTimeout)
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

        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        IterableAPI.email = "user1@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // First call, API call to register endpoint
            expectation1.fulfill()
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            networkSession.callback = {(_, _, _)in
                // Second call, API call to disable endpoint
                expectation3.fulfill()
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_DISABLE_DEVICE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
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

        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        let email = "user1@example.com"
        var registerForRemoteNotificationsCount = 0
        notificationStateProvider.callback = {
            registerForRemoteNotificationsCount += 1
        }
        IterableAPI.email = email
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // first call back will be called on register
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
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

        IterableAPI.initialize(apiKey: IterableAPITests.apiKey,
                               config: config,
                               networkSession: networkSession,
                               notificationStateProvider: notificationStateProvider)
        IterableAPI.userId = "userId1"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // first call back will be called on register
            expectation1.fulfill()
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            networkSession.callback = {(_, _, _) in
                // second call back is for disable when we set new user id
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_DISABLE_DEVICE, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
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

        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)
        IterableAPI.email = "user1@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            // first call back will be called on register
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: ITBConsts.apiEndpoint, path: ENDPOINT_REGISTER_DEVICE_TOKEN, queryParams: [(name: ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
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
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession, notificationStateProvider: notificationStateProvider)

        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

}
