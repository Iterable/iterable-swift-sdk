//
//  IterableAPITests.swift
//  swift-sdk-swift-tests
//
//  Created by Tapash Majumder on 7/24/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableAPITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTrackEventWithNoEmailOrUser() {
        let apiKey = "zeeApiKey"
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: apiKey, networkSession: networkSession)
        IterableAPI.email = nil
        IterableAPI.userId = nil
        IterableAPI.track(event: eventName)
        XCTAssertNil(networkSession.request)
    }

    func testTrackEventWithEmail() {
        let expectation = XCTestExpectation(description: "")
        
        let apiKey = "zeeApiKey"
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: apiKey, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        IterableAPI.track(event: eventName, dataFields: nil, onSuccess: { (json) in
            TestUtils.validate(request: networkSession.request!, requestType: .post, endPoint: ENDPOINT_TRACK, queryParams: [(name: "api_key", apiKey)])
            let body = networkSession.getRequestBody()
            TestUtils.validateElementPresent(withName: ITBL_KEY_EVENT_NAME, andValue: eventName, inBody: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_EMAIL, andValue: "user@example.com", inBody: body)
            expectation.fulfill()
        }) { (reason, data) in
            expectation.fulfill()
            XCTFail()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTrackEventBadNetwork() {
        let expectation = XCTestExpectation(description: "")
        
        let eventName = "MyCustomEvent"
        let networkSession = MockNetworkSession(statusCode: 502)
        IterableAPI.initialize(apiKey: "", networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        IterableAPI.track(
            event: eventName,
            dataFields: nil,
            onSuccess:{json in
                // fail on success
                expectation.fulfill()
                XCTFail()
            },
            onFailure: {(reason, data) in expectation.fulfill()})
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUpdateUser() {
        let expectation = XCTestExpectation(description: "")
        
        let apiKey = "zeeApiKey"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: apiKey, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let dataFields: Dictionary<String, String> = ["var1" : "val1", "var2" : "val2"]
        IterableAPI.updateUser(dataFields, mergeNestedObjects: true, onSuccess: {(json) in
            TestUtils.validate(request: networkSession.request!, requestType: .post, endPoint: ENDPOINT_UPDATE_USER, queryParams: [(name: "api_key", apiKey)])
            let body = networkSession.getRequestBody()
            TestUtils.validateElementPresent(withName: ITBL_KEY_EMAIL, andValue: "user@example.com", inBody: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_MERGE_NESTED, andValue: true, inBody: body)
            TestUtils.validateElementPresent(withName: ITBL_KEY_DATA_FIELDS, andValue: dataFields, inBody: body)
            expectation.fulfill()
        }) {(error, data) in
            XCTFail()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testUpdateEmail() {
        let expectation = XCTestExpectation(description: "")

        let apiKey = "zeeApiKey"
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initialize(apiKey: apiKey, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        IterableAPI.updateEmail("new_user@example.com",
                                onSuccess: {json in
                                    TestUtils.validate(request: networkSession.request!,
                                                       requestType: .post,
                                                       endPoint: ENDPOINT_UPDATE_EMAIL,
                                                       queryParams: [(name: "api_key", value: apiKey)])
                                    let body = networkSession.getRequestBody()
                                    TestUtils.validateElementPresent(withName: ITBL_KEY_NEW_EMAIL, andValue: "new_user@example.com", inBody: body)
                                    TestUtils.validateElementPresent(withName: ITBL_KEY_CURRENT_EMAIL, andValue: "user@example.com", inBody: body)
                                    XCTAssertEqual(IterableAPI.email, "new_user@example.com")
                                    expectation.fulfill()
                                },
                                onFailure: {(reason, data) in
                                    expectation.fulfill()
                                    XCTFail()
                                })

        wait(for: [expectation], timeout: 5.0)
    }
}
