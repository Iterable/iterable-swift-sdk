//
//  UserMergeScenariosTests.swift
//  unit-tests
//
//  Created by vishwa on 04/07/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class UserMergeScenariosTests: XCTestCase, AuthProvider {
    private static let apiKey = "zeeApiKey"
    private let authToken = "asdf"
    private let dateProvider = MockDateProvider()
    let mockSession = MockNetworkSession(statusCode: 200)
    let localStorage = MockLocalStorage()
    
    var auth: Auth {
        Auth(userId: nil, email: nil, authToken: authToken, userIdUnknownUser: nil)
    }
    
    override func setUp() {
        super.setUp()
    }
    
    func data(from jsonString: String) -> Data? {
        return jsonString.data(using: .utf8)
    }
    
    override func tearDown() {
        // Clean up after each test
        super.tearDown()
    }
    
    let mockData = """
    {
      "count": 1,
      "criteriaSets": [
        {
          "criteriaId": "96",
          "name": "Purchase: isSet Comparator",
          "createdAt": 1719328487701,
          "updatedAt": 1719328487701,
          "searchQuery": {
            "combinator": "And",
            "searchQueries": [
              {
                "combinator": "And",
                "searchQueries": [
                  {
                    "dataType": "customEvent",
                    "searchCombo": {
                      "combinator": "And",
                      "searchQueries": [
                        {
                          "dataType": "customEvent",
                          "field": "eventName",
                          "comparatorType": "Equals",
                          "value": "testEvent",
                          "fieldType": "string"
                        }
                      ]
                    }
                  }
                ]
              }
            ]
          }
        }
      ]
    }
    """
    
    
    // Helper function to wait for a specified duration
    private func waitForDuration(seconds: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting for \(seconds) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: seconds + 1)
    }
    
    func testCriteriaNotMetUserIdDefault() {  // criteria not met with merge default with setUserId
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        IterableAPI.setUserId("testuser123")
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        waitForDuration(seconds: 5)
        
        if localStorage.unknownUserEvents != nil {
            XCTFail("Events are not replayed")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected events to be nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaNotMetUserIdReplayTrueMergeFalse() {  // criteria not met with merge false with setUserId
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: false)
        IterableAPI.setUserId("testuser123", nil, identityResolution)
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        
        if localStorage.unknownUserEvents != nil {
            XCTFail("Events are not replayed")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected events to be nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaNotMetUserIdReplayFalseMergeFalse() {  // criteria not met with merge true with setUserId
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: false, mergeOnUnknownUserToKnown: false)
        IterableAPI.setUserId("testuser123", nil, identityResolution)
        
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        waitForDuration(seconds: 5)
        
        let expectation1 = self.expectation(description: "Events properly cleared")
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            expectation1.fulfill()
        }
        
        // Verify "merge user" API call is not made
        let expectation2 = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation2.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaNotMetUserIdReplayFalseMergeTrue() {  // criteria not met with merge true with setUserId
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: false, mergeOnUnknownUserToKnown: true)
        IterableAPI.setUserId("testuser123", nil, identityResolution)
        
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        waitForDuration(seconds: 5)
        
        let expectation1 = self.expectation(description: "Events properly cleared")
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            expectation1.fulfill()
        }
        
        // Verify "merge user" API call is not made
        let expectation2 = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation2.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaMetUserIdDefault() {  // criteria met with merge default with setUserId
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user nil")
        } else {
            XCTFail("Expected unknown user nil but found")
        }
        
        IterableAPI.setUserId("testuser123")
        
        // Verify "merge user" API call is made
        let apiCallExpectation = self.expectation(description: "API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                apiCallExpectation.fulfill()
            } else {
                XCTFail("Expected merge user API call was not made")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaMetUserIdMergeFalse() {  // criteria met with merge false with setUserId
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user to be found")
        } else {
            XCTFail("Expected unknown user but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: false)
        IterableAPI.setUserId("testuser123", nil, identityResolution)
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaMetUserIdMergeTrue() {  // criteria met with merge true with setUserId
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user nil")
        } else {
            XCTFail("Expected unknown user nil but found")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: true)
        IterableAPI.setUserId("testuser123", nil, identityResolution)
        
        waitForDuration(seconds: 3)
        
        // Verify "merge user" API call is made
        let apiCallExpectation = self.expectation(description: "API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                apiCallExpectation.fulfill()
            } else {
                XCTFail("Expected merge user API call was not made")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testIdentifiedUserIdDefault() {  // current user identified with setUserId default
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.setUserId("testuser123")
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        
        
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        
        if localStorage.userIdUnknownUser != nil {
            XCTFail("Expected unknown user nil but found")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected unknown user to be nil")
        }
        
        IterableAPI.setUserId("testuseranotheruser")
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuseranotheruser", "Expected userId to be 'testuseranotheruser'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testIdentifiedUserIdMergeFalse() {  // current user identified with setUserId merge false
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.setUserId("testuser123")
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        
        
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        if localStorage.userIdUnknownUser != nil {
            XCTFail("Expected unknown user nil but found")
        } else {
            XCTAssertNil(localStorage.userIdUnknownUser, "Expected unknown user to be nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: false)
        IterableAPI.setUserId("testuseranotheruser", nil, identityResolution)
        
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuseranotheruser", "Expected userId to be 'testuseranotheruser'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testIdentifiedUserIdMergeTrue() {  // current user identified with setUserId true
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.setUserId("testuser123")
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        
        
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        
        if localStorage.userIdUnknownUser != nil {
            XCTFail("Expected unknown user nil but found")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected unknown user to be nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: true)
        IterableAPI.setUserId("testuseranotheruser", nil, identityResolution)
        waitForDuration(seconds: 3)
        
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuseranotheruser", "Expected userId to be 'testuseranotheruser'")
        } else {
            XCTFail("Expected userId but found nil")
        }
        
        // Verify "merge user" API call is not made
        let apiCallExpectation = self.expectation(description: "API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                XCTFail("Expected merge user API call was made")
            } else {
                apiCallExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaNotMetEmailDefault() {  // criteria not met with merge default with setEmail
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        IterableAPI.setEmail("testuser123@test.com")
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        waitForDuration(seconds: 5)
        
        if localStorage.unknownUserEvents != nil {
            XCTFail("Events are not replayed")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected events to be nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaNotMetEmailReplayTrueMergeFalse() {  // criteria not met with merge false with setEmail
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: false)
        IterableAPI.setEmail("testuser123@test.com", nil, identityResolution)
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        
        if localStorage.unknownUserEvents != nil {
            XCTFail("Events are not replayed")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected events to be nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaNotMetEmailReplayFalseMergeFalse() {  // criteria not met with merge true with setEmail
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: false, mergeOnUnknownUserToKnown: false)
        IterableAPI.setEmail("testuser123@test.com", nil, identityResolution)
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        waitForDuration(seconds: 5)
        
        let expectation1 = self.expectation(description: "Events properly cleared")
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            expectation1.fulfill()
        }
        
        // Verify "merge user" API call is not made
        let expectation2 = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation2.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaNotMetEmailReplayFalseMergeTrue() {  // criteria not met with merge true with setEmail
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
        
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            XCTFail("Expected events to be logged but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: false, mergeOnUnknownUserToKnown: true)
        IterableAPI.setEmail("testuser123@test.com", nil, identityResolution)
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        waitForDuration(seconds: 5)
        
        let expectation1 = self.expectation(description: "Events properly cleared")
        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
        } else {
            expectation1.fulfill()
        }
        
        // Verify "merge user" API call is not made
        let expectation2 = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation2.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaMetEmailDefault() {  // criteria met with merge default with setEmail
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user")
        } else {
            XCTFail("Expected unknown user but found nil")
        }
        
        IterableAPI.setEmail("testuser123@test.com")
        
        // Verify "merge user" API call is made
        let apiCallExpectation = self.expectation(description: "API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                apiCallExpectation.fulfill()
            } else {
                XCTFail("Expected merge user API call was not made")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaMetEmailMergeFalse() {  // criteria met with merge false with setEmail
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user")
        } else {
            XCTFail("Expected unknown user but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: false)
        IterableAPI.setEmail("testuser123@test.com", nil, identityResolution)
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaMetEmailMergeTrue() {  // criteria met with merge true with setEmail
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user")
        } else {
            XCTFail("Expected unknown user but found nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: true)
        IterableAPI.setEmail("testuser123@test.com", nil, identityResolution)
        
        // Verify "merge user" API call is made
        let apiCallExpectation = self.expectation(description: "API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                apiCallExpectation.fulfill()
            } else {
                XCTFail("Expected merge user API call was not made")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testIdentifiedEmailDefault() {  // current user identified with setEmail default
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.setEmail("testuser123@test.com")
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        
        
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        
        if localStorage.userIdUnknownUser != nil {
            XCTFail("Expected unknown user nil but found")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected unknown user to be nil")
        }
        
        IterableAPI.setEmail("testuseranotheruser@test.com")
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuseranotheruser@test.com", "Expected email to be 'testuseranotheruser@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testIdentifiedEmailMergeFalse() {  // current user identified with setEmail merge false
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.setEmail("testuser123@test.com")
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        
        
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        
        if localStorage.userIdUnknownUser != nil {
            XCTFail("Expected unknown user nil but found")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected unknown user to be nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: false)
        IterableAPI.setEmail("testuseranotheruser@test.com", nil, identityResolution)
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuseranotheruser@test.com", "Expected email to be 'testuseranotheruser@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        
        // Verify "merge user" API call is not made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                XCTFail("merge user API call was made unexpectedly")
            } else {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testIdentifiedEmailMergeTrue() {  // current user identified with setEmail true
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.setEmail("testuser123@test.com")
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        
        
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)
        
        
        if localStorage.userIdUnknownUser != nil {
            XCTFail("Expected unknown user nil but found")
        } else {
            XCTAssertNil(localStorage.unknownUserEvents, "Expected unknown user to be nil")
        }
        
        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: true)
        IterableAPI.setEmail("testuseranotheruser@test.com", nil, identityResolution)
        waitForDuration(seconds: 3)
        
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuseranotheruser@test.com", "Expected email to be 'testuseranotheruser@test.com'")
        } else {
            XCTFail("Expected email but found nil")
        }
        
        // Verify "merge user" API call is made
        let expectation = self.expectation(description: "No API call is made to merge user")
        DispatchQueue.main.async {
            if let _ = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                XCTFail("merge user API call was made unexpectedly")
            } else {
                // Pass the test if the API call was not made
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCriteriaMetTwice() {
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        
        let mockSession = MockNetworkSession()
        
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                         config: config,
                                         networkSession: mockSession,
                                         localStorage: localStorage)
        
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        
        IterableAPI.track(event: "testEvent")
        IterableAPI.track(event: "testEvent")
        
        waitForDuration(seconds: 3)
        
        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user nil")
        } else {
            XCTFail("Expected unknown user nil but found")
        }
        
        // Verify that unknown user session request was made exactly once
        let unknownUserSessionRequest = mockSession.getRequest(withEndPoint: Const.Path.trackUnknownUserSession)
        XCTAssertNotNil(unknownUserSessionRequest, "Unknown user session request should not be nil")
        
        // Count total requests with unknown user session endpoint
        let unknownUserSessionRequests = mockSession.requests.filter { request in
            request.url?.absoluteString.contains(Const.Path.trackUnknownUserSession) == true
        }
        XCTAssertEqual(unknownUserSessionRequests.count, 1, "Unknown user session should be called exactly once")

        // Verify track events were made
        let trackRequests = mockSession.requests.filter { request in
            request.url?.absoluteString.contains(Const.Path.trackEvent) == true
        }
        XCTAssertEqual(trackRequests.count, 2, "Track event should be called twice")
    }
}


