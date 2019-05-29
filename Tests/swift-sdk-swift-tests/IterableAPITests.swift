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
        TestUtils.clearTestUserDefaults()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitialize() {
        IterableAPI.initialize(apiKey: IterableAPITests.apiKey)
        
        XCTAssertEqual(IterableAPI.internalImplementation?.apiKey, IterableAPITests.apiKey)
    }

    func testTrackEventWithNoEmailOrUser() {
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = nil
        IterableAPI.userId = nil
        IterableAPI.track(event: eventName)
        XCTAssertNil(networkSession.request)
    }

    func testTrackEventWithEmail() {
        let expectation = XCTestExpectation(description: "testTrackEventWithEmail")
        
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = IterableAPITests.email
        IterableAPI.track(event: eventName, dataFields: nil, onSuccess: { (json) in
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK, queryParams: [(name: "api_key", IterableAPITests.apiKey)])
            let body = networkSession.getRequestBody()
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_EVENT_NAME, andValue: eventName, inDictionary: body)
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_EMAIL, andValue: IterableAPITests.email, inDictionary: body)
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

    // without callback
    func testTrackEventWithEmail2() {
        let expectation = XCTestExpectation(description: "testTrackEventWithEmail using no callback")
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = IterableAPITests.email
        IterableAPI.track(event: eventName, dataFields: ["key1" : "value1", "key2" : "value2"])
        
        networkSession.callback = {(_, _, _) in
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK, queryParams: [(name: "api_key", IterableAPITests.apiKey)])
            let body = networkSession.getRequestBody()
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_EVENT_NAME, andValue: eventName, inDictionary: body)
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_EMAIL, andValue: IterableAPITests.email, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("dataFields"), value: ["key1" : "value1", "key2" : "value2"], inDictionary: body as! [String : Any], message: "data fields did not match")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testTrackEventBadNetwork() {
        let expectation = XCTestExpectation(description: "testTrackEventBadNetwork")
        
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 502)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
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
    
    func testEmailUserIdPersistence() {
        IterableAPI.initializeForTesting()
        
        IterableAPI.email = IterableAPITests.email
        XCTAssertEqual(IterableAPI.email, IterableAPITests.email)
        XCTAssertNil(IterableAPI.userId)
        
        let userId = "testUserId"
        IterableAPI.userId = userId
        XCTAssertEqual(IterableAPI.userId, userId)
        XCTAssertNil(IterableAPI.email)
    }
    
    func testUpdateUser() {
        let expectation = XCTestExpectation(description: "testUpdateUser")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = IterableAPITests.email
        let dataFields: Dictionary<String, String> = ["var1" : "val1", "var2" : "val2"]
        IterableAPI.updateUser(dataFields, mergeNestedObjects: true, onSuccess: {(json) in
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_UPDATE_USER, queryParams: [(name: "api_key", IterableAPITests.apiKey)])
            let body = networkSession.getRequestBody()
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_EMAIL, andValue: IterableAPITests.email, inDictionary: body)
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_MERGE_NESTED, andValue: true, inDictionary: body)
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_DATA_FIELDS, andValue: dataFields, inDictionary: body)
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

    func testUpdateEmailWithEmail() {
        let expectation = XCTestExpectation(description: "testUpdateEmailWithEmail")

        let newEmail = "new_user@example.com"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.email = IterableAPITests.email
        IterableAPI.updateEmail(newEmail,
                                onSuccess: {json in
                                    TestUtils.validate(request: networkSession.request!,
                                                       requestType: .post,
                                                       apiEndPoint: .ITBL_ENDPOINT_API,
                                                       path: .ITBL_PATH_UPDATE_EMAIL,
                                                       queryParams: [(name: "api_key", value: IterableAPITests.apiKey)])
                                    let body = networkSession.getRequestBody()
                                    TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_NEW_EMAIL, andValue: newEmail, inDictionary: body)
                                    TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_CURRENT_EMAIL, andValue: IterableAPITests.email, inDictionary: body)
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

    func testUpdateEmailWithUserId() {
        let expectation = XCTestExpectation(description: "testUpdateEmailWithUserId")
        
        let currentUserId = IterableUtil.generateUUID()
        let newEmail = "new_user@example.com"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        IterableAPI.userId = currentUserId
        IterableAPI.updateEmail(newEmail,
                                onSuccess: {json in
                                    TestUtils.validate(request: networkSession.request!,
                                                       requestType: .post,
                                                       apiEndPoint: .ITBL_ENDPOINT_API,
                                                       path: .ITBL_PATH_UPDATE_EMAIL,
                                                       queryParams: [(name: "api_key", value: IterableAPITests.apiKey)])
                                    let body = networkSession.getRequestBody()
                                    TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_NEW_EMAIL, andValue: newEmail, inDictionary: body)
                                    TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_CURRENT_USER_ID, andValue: currentUserId, inDictionary: body)
                                    XCTAssertEqual(IterableAPI.userId, currentUserId)
                                    XCTAssertNil(IterableAPI.email)
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
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, networkSession: networkSession)
        
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
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = nil
        IterableAPI.userId = nil
        
        IterableAPI.register(token: "zeeToken".data(using: .utf8)!, onSuccess: { (dict) in
            XCTFail("did not expect success here")
        }) {(_,_) in
            // failure
            expectation.fulfill()
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testRegisterToken() {
        let expectation = XCTestExpectation(description: "testRegisterToken")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { (dict) in
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateElementPresent(withName: "email", andValue: "user@example.com", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.applicationName"), value: "my-push-integration", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.platform"), value: String.ITBL_KEY_APNS_SANDBOX, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.token"), value: token.hexString(), inDictionary: body)

            // more device fields
            let appPackageName = "iterable.host-app"
            let appVersion = "1.0.0"
            let appBuild = "2"
            TestUtils.validateExists(keyPath: KeyPath("device.dataFields.deviceId"), type: String.self, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.dataFields.appPackageName"), value: appPackageName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.dataFields.appVersion"), value: appVersion, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.dataFields.appBuild"), value: appBuild, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("device.dataFields.iterableSdkVersion"), value: IterableAPI.sdkVersion, inDictionary: body)

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
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
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
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token)
        networkSession.callback = {(data, response, error) in
            networkSession.callback = nil
            IterableAPI.disableDeviceForCurrentUser(withOnSuccess: { (json) in
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_DISABLE_DEVICE, queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
                TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_TOKEN, andValue: token.hexString(), inDictionary: body)
                TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_EMAIL, andValue: "user@example.com", inDictionary: body)
                expectation.fulfill()
            }) { (errorMessage, data) in
                expectation.fulfill()
            }
        }

        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    // Same test as above but without using success/failure callback
    func testDisableDeviceForCurrentUserWithoutCallback() {
        let expectation = XCTestExpectation(description: "testDisableDeviceForCurrentUserWithoutCallback")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token)
        networkSession.callback = {(_, _, _) in
            networkSession.callback = {(_, _, _) in
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_DISABLE_DEVICE, queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
                TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_TOKEN, andValue: token.hexString(), inDictionary: body)
                TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_EMAIL, andValue: "user@example.com", inDictionary: body)
                expectation.fulfill()
            }
            IterableAPI.disableDeviceForCurrentUser()
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    func testDisableDeviceForAllUsers() {
        let expectation = XCTestExpectation(description: "testDisableDeviceForAllUsers")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(data, response, error) in
            networkSession.callback = nil
            IterableAPI.disableDeviceForAllUsers(withOnSuccess: { (json) in
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_DISABLE_DEVICE, queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
                TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_TOKEN, andValue: token.hexString(), inDictionary: body)
                TestUtils.validateElementNotPresent(withName: AnyHashable.ITBL_KEY_EMAIL, inDictionary: body)
                TestUtils.validateElementNotPresent(withName: AnyHashable.ITBL_KEY_USER_ID, inDictionary: body)
                expectation.fulfill()
            }) { (errorMessage, data) in
                expectation.fulfill()
            }
        }
        IterableAPI.register(token: token)
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }

    // Same test as above but without using success/failure callback
    func testDisableDeviceForAllUsersWithoutCallback() {
        let expectation = XCTestExpectation(description: "testDisableDeviceForAllUsersWithoutCallback")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        networkSession.callback = {(_, _, _) in
            networkSession.callback = {(_, _, _) in
                let body = networkSession.getRequestBody() as! [String : Any]
                TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_DISABLE_DEVICE, queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
                TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_TOKEN, andValue: token.hexString(), inDictionary: body)
                TestUtils.validateElementNotPresent(withName: AnyHashable.ITBL_KEY_EMAIL, inDictionary: body)
                TestUtils.validateElementNotPresent(withName: AnyHashable.ITBL_KEY_USER_ID, inDictionary: body)
                expectation.fulfill()
            }
            IterableAPI.disableDeviceForAllUsers()
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
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)

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
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.userId = "zeeUserId"
        
        IterableAPI.track(purchase: 10.55, items: [], dataFields: nil, onSuccess: { (json) in
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_COMMERCE_TRACK_PURCHASE, queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            TestUtils.validateMatch(keyPath: KeyPath("\(AnyHashable.ITBL_KEY_USER).\(AnyHashable.ITBL_KEY_USER_ID)"), value: "zeeUserId", inDictionary: body)
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_TOTAL, andValue: 10.55, inDictionary: body)

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
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let total = NSNumber(value: 15.32)
        let items = [CommerceItem(id: "id1", name: "myCommerceItem", price: 5.0, quantity: 2)]
        
        IterableAPI.track(purchase: total, items: items, dataFields: nil, onSuccess: { (json) in
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_COMMERCE_TRACK_PURCHASE, queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            TestUtils.validateMatch(keyPath: KeyPath("\(AnyHashable.ITBL_KEY_USER).\(AnyHashable.ITBL_KEY_EMAIL)"), value: "user@example.com", inDictionary: body)
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_TOTAL, andValue: total, inDictionary: body)
            let itemsElement = body[AnyHashable.ITBL_KEY_ITEMS] as! [[AnyHashable : Any]]
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
    
    // Same test as above but without using success/failure handler
    func testPurchaseWithoutSuccessAndFailure() {
        let expectation = XCTestExpectation(description: "testTrackPurchaseWithoutSuccessAndFailure")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let total = NSNumber(value: 15.32)
        let items = [CommerceItem(id: "id1", name: "myCommerceItem", price: 5.0, quantity: 2)]
        
        networkSession.callback = {(_, _, _) in
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validate(request: networkSession.request!, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_COMMERCE_TRACK_PURCHASE, queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            TestUtils.validateMatch(keyPath: KeyPath("\(AnyHashable.ITBL_KEY_USER).\(AnyHashable.ITBL_KEY_EMAIL)"), value: "user@example.com", inDictionary: body)
            TestUtils.validateElementPresent(withName: AnyHashable.ITBL_KEY_TOTAL, andValue: total, inDictionary: body)
            let itemsElement = body[AnyHashable.ITBL_KEY_ITEMS] as! [[AnyHashable : Any]]
            XCTAssertEqual(itemsElement.count, 1)
            let firstElement = itemsElement[0]
            TestUtils.validateElementPresent(withName: "id", andValue: "id1", inDictionary: firstElement)
            TestUtils.validateElementPresent(withName: "name", andValue: "myCommerceItem", inDictionary: firstElement)
            TestUtils.validateElementPresent(withName: "price", andValue: 5.0, inDictionary: firstElement)
            TestUtils.validateElementPresent(withName: "quantity", andValue: 2, inDictionary: firstElement)
            expectation.fulfill()
        }
        IterableAPI.track(purchase: total, items: items)
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testGetInAppMessages() {
        let expectation1 = expectation(description: "get in app messages")
        let networkSession = MockNetworkSession(statusCode: 200)
        networkSession.callback = {(_,_,_) in
            let expectedQueryParams = [
                (name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey),
                (name: AnyHashable.ITBL_KEY_COUNT, value: 1.description),
                (name: AnyHashable.ITBL_KEY_PLATFORM, value: .ITBL_PLATFORM_IOS),
                (name: AnyHashable.ITBL_KEY_SDK_VERSION, value: IterableAPI.sdkVersion),
                (name: AnyHashable.ITBL_KEY_PACKAGE_NAME, value: Bundle.main.appPackageName!),
            ]
            TestUtils.validate(request: networkSession.request!,
                               requestType: .get,
                               apiEndPoint: .ITBL_ENDPOINT_API,
                               path: .ITBL_PATH_GET_INAPP_MESSAGES,
                               queryParams: expectedQueryParams)
            expectation1.fulfill()
        }
        let config = IterableConfig()
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config: config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        IterableAPI.get(inAppMessages: 1)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testGetInAppMessagesWithCallback() {
        let expectation1 = expectation(description: "get in app messages with callback")
        let networkSession = MockNetworkSession(statusCode: 200)

        let config = IterableConfig()
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config: config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        IterableAPI.get(
            inAppMessages: 1,
            onSuccess: {(_) in
                let expectedQueryParams = [
                    (name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey),
                    (name: AnyHashable.ITBL_KEY_COUNT, value: 1.description),
                    (name: AnyHashable.ITBL_KEY_PLATFORM, value: .ITBL_PLATFORM_IOS),
                    (name: AnyHashable.ITBL_KEY_SDK_VERSION, value: IterableAPI.sdkVersion),
                    ]
                TestUtils.validate(request: networkSession.request!,
                                   requestType: .get,
                                   apiEndPoint: .ITBL_ENDPOINT_API,
                                   path: .ITBL_PATH_GET_INAPP_MESSAGES,
                                   queryParams: expectedQueryParams)
                expectation1.fulfill()
        },
            onFailure:nil
        )
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testInAppConsume() {
        let expectation1 = expectation(description: "get in app messages")
        let messageId = UUID().uuidString
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config: config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        networkSession.callback = {(_,_,_) in
            let expectedQueryParams = [
                (name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey),
                ]
            TestUtils.validate(request: networkSession.request!,
                               requestType: .post,
                               apiEndPoint: .ITBL_ENDPOINT_API,
                               path: .ITBL_PATH_INAPP_CONSUME,
                               queryParams: expectedQueryParams)
            TestUtils.validateElementPresent(withName: "messageId", andValue: messageId, inDictionary: networkSession.getRequestBody())
            expectation1.fulfill()
        }
        IterableAPI.inAppConsume(messageId: messageId)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testUpdateSubscriptions() {
        let expectation1 = expectation(description: "update subscriptions")
        let emailListIds = ["user1@example.com"]
        let unsubscriptedChannelIds = ["channedl1", "channel2"]
        let unsubscribedMessageTypeIds = ["messageType1" ,"messageType2"]
        
        let networkSession = MockNetworkSession(statusCode: 200)
        networkSession.callback = {(_,_,_) in
            TestUtils.validate(request: networkSession.request!,
                               requestType: .post,
                               apiEndPoint: .ITBL_ENDPOINT_API,
                               path: .ITBL_PATH_UPDATE_SUBSCRIPTIONS,
                               queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: IterableAPITests.apiKey)])
            
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath(AnyHashable.ITBL_KEY_EMAIL_LIST_IDS), value: emailListIds, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(AnyHashable.ITBL_KEY_UNSUB_CHANNEL), value: unsubscriptedChannelIds, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(AnyHashable.ITBL_KEY_UNSUB_MESSAGE), value: unsubscribedMessageTypeIds, inDictionary: body)
            expectation1.fulfill()
        }
        let config = IterableConfig()
        TestUtils.getTestUserDefaults().set("user1@example.com", forKey: .ITBL_USER_DEFAULTS_EMAIL_KEY)
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey, config:config, networkSession: networkSession)
        IterableAPI.updateSubscriptions(emailListIds, unsubscribedChannelIds: unsubscriptedChannelIds, unsubscribedMessageTypeIds: unsubscribedMessageTypeIds)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testInitializeWithLaunchOptionsAndCustomAction() {
        let expectation1 = expectation(description: "initializeWithLaunchOptions")
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": "messageId",
                "defaultAction": [
                    "type": "customAction"
                ]
            ]
        ]
        let launchOptions: [UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.remoteNotification : userInfo]
        let customActionDelegate = MockCustomActionDelegate(returnValue: false)
        customActionDelegate.callback = {(name, _) in
            XCTAssertEqual(name, "customAction")
            expectation1.fulfill()
        }
        let config = IterableConfig()
        config.customActionDelegate = customActionDelegate
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey,
                               launchOptions: launchOptions,
                               config: config)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testInitializeWithLaunchOptionsAndUrl() {
        let expectation1 = expectation(description: "initializeWithLaunchOptions")
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": "messageId",
                "defaultAction": [
                    "type": "openUrl",
                    "data": "http://somewhere.com"
                ]
            ]
        ]
        let launchOptions: [UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.remoteNotification : userInfo]
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = {(url, _) in
            XCTAssertEqual(url.absoluteString, "http://somewhere.com")
            expectation1.fulfill()
        }
        let config = IterableConfig()
        config.urlDelegate = urlDelegate
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey,
                               launchOptions: launchOptions,
                               config: config)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testTrackPushOpen() {
        let expectation1 = expectation(description: "trackPushOpen")
        let messageId = UUID().uuidString
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "messageId": messageId,
                "isGhostPush" : false,
                "defaultAction": [
                    "type": "openUrl",
                    "data": "http://somewhere.com"
                ]
            ]
        ]

        let networkSession = MockNetworkSession(statusCode: 200)
        
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey,
                               networkSession: networkSession)
        networkSession.callback = {(_, _, _) in
            TestUtils.validate(request: networkSession.request!, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK)
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath("campaignId"), value: 1234, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("templateId"), value: 4321, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("messageId"), value: messageId, inDictionary: body)
            expectation1.fulfill()
        }
        IterableAPI.track(pushOpen: userInfo)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackPushOpenWithDataFields() {
        let expectation1 = expectation(description: "trackPushOpen with datafields")
        let messageId = UUID().uuidString
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "messageId": messageId,
                "isGhostPush" : false
            ]
        ]
        
        let networkSession = MockNetworkSession(statusCode: 200)
        
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey,
                               networkSession: networkSession)
        networkSession.callback = {(_, _, _) in
            TestUtils.validate(request: networkSession.request!, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK)
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath("campaignId"), value: 1234, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("templateId"), value: 4321, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("messageId"), value: messageId, inDictionary: body)
            let dataFields: Dictionary<String, AnyHashable> = ["appAlreadyRunning" : false, "key1" : "value1"]
            TestUtils.validateMatch(keyPath: KeyPath("dataFields"), value: dataFields, inDictionary: body)
            expectation1.fulfill()
        }
        IterableAPI.track(pushOpen: userInfo, dataFields: ["key1" : "value1"])
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackPushOpenWithCallback() {
        let expectation1 = expectation(description: "trackPushOpen with callback")
        let messageId = UUID().uuidString
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "messageId": messageId,
                "isGhostPush" : false
            ]
        ]
        
        let networkSession = MockNetworkSession(statusCode: 200)
        
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey,
                               networkSession: networkSession)
        IterableAPI.track(pushOpen: userInfo, dataFields: ["key1" : "value1"], onSuccess: {_ in
            TestUtils.validate(request: networkSession.request!, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK)
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath("campaignId"), value: 1234, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("templateId"), value: 4321, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("messageId"), value: messageId, inDictionary: body)
            let dataFields: Dictionary<String, AnyHashable> = ["appAlreadyRunning" : false, "key1" : "value1"]
            TestUtils.validateMatch(keyPath: KeyPath("dataFields"), value: dataFields, inDictionary: body)
            expectation1.fulfill()
        }, onFailure: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackPushOpenWithCampaignIdEtc() {
        let expectation1 = expectation(description: "trackPushOpen with campaignId etc")
        let messageId = UUID().uuidString
        
        let networkSession = MockNetworkSession(statusCode: 200)
        
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey,
                               networkSession: networkSession)
        networkSession.callback = {(_, _, _) in
            TestUtils.validate(request: networkSession.request!, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK)
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath("campaignId"), value: 1234, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("templateId"), value: 4321, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("messageId"), value: messageId, inDictionary: body)
            let dataFields: Dictionary<String, AnyHashable> = ["appAlreadyRunning" : true, "key1" : "value1"]
            TestUtils.validateMatch(keyPath: KeyPath("dataFields"), value: dataFields, inDictionary: body, message: "dataFields did not match")
            expectation1.fulfill()
        }
        IterableAPI.track(pushOpen: 1234, templateId: 4321, messageId: messageId, appAlreadyRunning: true, dataFields: ["key1" : "value1"])
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackPushOpenWithCampaignIdEtcWithCallback() {
        let expectation1 = expectation(description: "trackPushOpen with campaignId etc with callback")
        let messageId = UUID().uuidString
        
        let networkSession = MockNetworkSession(statusCode: 200)
        
        IterableAPI.initializeForTesting(apiKey: IterableAPITests.apiKey,
                               networkSession: networkSession)
        IterableAPI.track(pushOpen: 1234,
                          templateId: 4321,
                          messageId: messageId,
                          appAlreadyRunning: true,
                          dataFields: ["key1" : "value1"],
                          onSuccess: {(_) in
                            TestUtils.validate(request: networkSession.request!, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK)
                            let body = networkSession.getRequestBody() as! [String : Any]
                            TestUtils.validateMatch(keyPath: KeyPath("campaignId"), value: 1234, inDictionary: body)
                            TestUtils.validateMatch(keyPath: KeyPath("templateId"), value: 4321, inDictionary: body)
                            TestUtils.validateMatch(keyPath: KeyPath("messageId"), value: messageId, inDictionary: body)
                            let dataFields: Dictionary<String, AnyHashable> = ["appAlreadyRunning" : true, "key1" : "value1"]
                            TestUtils.validateMatch(keyPath: KeyPath("dataFields"), value: dataFields, inDictionary: body, message: "dataFields did not match")
                            expectation1.fulfill()
        },
                          onFailure:nil
        )
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}
