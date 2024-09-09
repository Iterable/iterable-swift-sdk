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
        Auth(userId: nil, email: nil, authToken: authToken, userIdAnon: nil)
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
      "criterias": [
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
    
    func testCriteriaNotMatchDisableMergeAndReplayTrueWithUserId() {  // criteria not met with merge false with setUserId
        let config = IterableConfig()
        config.enableAnonTracking = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
       
        if let events = localStorage.anonymousUserEvents {
                    XCTAssertFalse(events.isEmpty, "Expected events to be logged")
               } else {
                   XCTFail("Expected events to be logged but found nil")
               }
        
        IterableAPI.setUserId("testuser123", disableReplay: true)
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
               } else {
                   XCTFail("Expected userId but found nil")
               }
        
        if let events = localStorage.anonymousUserEvents {
                    XCTAssertFalse(events.isEmpty, "Expected events to be logged")
               } else {
                   XCTFail("Expected events to be logged but found nil")
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
    
    func testCriteriaNotMatchDisableMergeAndReplayFalseWithUserId() {  // criteria not met with merge true with setUserId
        let config = IterableConfig()
        config.enableAnonTracking = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
       
        if let events = localStorage.anonymousUserEvents {
                    XCTAssertFalse(events.isEmpty, "Expected events to be logged")
               } else {
                   XCTFail("Expected events to be logged but found nil")
               }
        
        IterableAPI.setUserId("testuser123", disableReplay: false)
        if let userId = IterableAPI.userId {
            XCTAssertEqual(userId, "testuser123", "Expected userId to be 'testuser123'")
               } else {
                   XCTFail("Expected userId but found nil")
               }
        waitForDuration(seconds: 5)

        if let events = localStorage.anonymousUserEvents {
                XCTAssertFalse(events.isEmpty, "Expected events to be logged")
            } else {
                XCTAssertNil(localStorage.anonymousUserEvents, "Expected events to be nil")
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
    
    func testCriteriaNotMatchDisableMergeAndReplayDefaultWithUserId() {  // criteria not met with merge default with setUserId
        let config = IterableConfig()
        config.enableAnonTracking = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
       
        if let events = localStorage.anonymousUserEvents {
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

        if let events = localStorage.anonymousUserEvents {
                XCTAssertFalse(events.isEmpty, "Expected events to be logged")
            } else {
                XCTAssertNil(localStorage.anonymousUserEvents, "Expected events to be nil")
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
    
    func testCriteriaMatchDisableMergeAndReplayTrueWithUserId() {  // criteria met with merge false with setUserId
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)

        if let anonUser = localStorage.userIdAnnon {
            XCTAssertFalse(anonUser.isEmpty, "Expected anon user to be found")
               } else {
                   XCTFail("Expected anon user but found nil")
               }
        
        IterableAPI.setUserId("testuser123", nil, disableReplay: true)
 
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
    
    func testCriteriaMatchDisableMergeAndReplayFalseWithUserId() {  // criteria met with merge true with setUserId
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)

        if let anonUser = localStorage.userIdAnnon {
            XCTAssertFalse(anonUser.isEmpty, "Expected anon user nil")
               } else {
                   XCTFail("Expected anon user nil but found")
               }
        
        IterableAPI.setUserId("testuser123", disableReplay: false)
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
    
    func testCriteriaMatchDisableMergeAndReplayDefaultWithUserId() {  // criteria met with merge default with setUserId
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)

        if let anonUser = localStorage.userIdAnnon {
            XCTAssertFalse(anonUser.isEmpty, "Expected anon user nil")
               } else {
                   XCTFail("Expected anon user nil but found")
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
    
    
    func testCurrentUserIdentifiedWithDisableMergeAndReplayTrueWithUserId() {  // current user identified with setUserId merge false
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
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

        if let anonUser = localStorage.userIdAnnon {
                XCTFail("Expected anon user nil but found")
               } else {
                   XCTAssertNil(localStorage.userIdAnnon, "Expected anon user to be nil")
               }
        
        IterableAPI.setUserId("testuseranotheruser", disableReplay: true)
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
    
    
    func testCurrentUserIdentifiedWithDisableMergeAndReplayFalseWithUserId() {  // current user identified with setUserId true
        let config = IterableConfig()
        config.enableAnonTracking = true
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


        if let anonUser = localStorage.userIdAnnon {
                XCTFail("Expected anon user nil but found")
               } else {
                   XCTAssertNil(localStorage.anonymousUserEvents, "Expected anon user to be nil")
               }
        
        IterableAPI.setUserId("testuseranotheruser", disableReplay: false)
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
    
    func testCurrentUserIdentifiedWithDisableMergeAndReplayDefaultWithUserId() {  // current user identified with setUserId default
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
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


        if let anonUser = localStorage.userIdAnnon {
                XCTFail("Expected anon user nil but found")
               } else {
                   XCTAssertNil(localStorage.anonymousUserEvents, "Expected anon user to be nil")
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
    
    func testCriteriaNotMatchDisableMergeAndReplayTrueWithEmail() {  // criteria not met with merge false with setEmail
        let config = IterableConfig()
        config.enableAnonTracking = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
       
        if let events = localStorage.anonymousUserEvents {
                    XCTAssertFalse(events.isEmpty, "Expected events to be logged")
               } else {
                   XCTFail("Expected events to be logged but found nil")
               }
        
        IterableAPI.setEmail("testuser123@test.com", disableReplay: true)
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
               } else {
                   XCTFail("Expected email but found nil")
               }
        
        if let events = localStorage.anonymousUserEvents {
                    XCTAssertFalse(events.isEmpty, "Expected events to be logged")
               } else {
                   XCTFail("Expected events to be logged but found nil")
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
    
    func testCriteriaNotMatchDisableMergeAndReplayFalseWithEmail() {  // criteria not met with merge true with setEmail
        let config = IterableConfig()
        config.enableAnonTracking = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
       
        if let events = localStorage.anonymousUserEvents {
                    XCTAssertFalse(events.isEmpty, "Expected events to be logged")
               } else {
                   XCTFail("Expected events to be logged but found nil")
               }
        
        IterableAPI.setEmail("testuser123@test.com", disableReplay: false)
        if let userId = IterableAPI.email {
            XCTAssertEqual(userId, "testuser123@test.com", "Expected email to be 'testuser123@test.com'")
               } else {
                   XCTFail("Expected email but found nil")
               }
        waitForDuration(seconds: 5)

        if let events = localStorage.anonymousUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
            } else {
                XCTAssertNil(localStorage.anonymousUserEvents, "Expected events to be nil")
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
    
    func testCriteriaNotMatchDisableMergeAndReplayDefaultWithEmail() {  // criteria not met with merge default with setEmail
        let config = IterableConfig()
        config.enableAnonTracking = true
        IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent123")
       
        if let events = localStorage.anonymousUserEvents {
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

        if let events = localStorage.anonymousUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
            } else {
                XCTAssertNil(localStorage.anonymousUserEvents, "Expected events to be nil")
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
    
    func testCriteriaMatchDisableMergeAndReplayTrueWithEmail() {  // criteria met with merge false with setEmail
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)

        if let anonUser = localStorage.userIdAnnon {
            XCTAssertFalse(anonUser.isEmpty, "Expected anon user")
               } else {
                   XCTFail("Expected anon user but found nil")
               }
        
        IterableAPI.setEmail("testuser123@test.com", nil, disableReplay: true)
 
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
    
    func testCriteriaMatchDisableMergeAndReplayFalseWithEmail() {  // criteria met with merge true with setEmail
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)

        if let anonUser = localStorage.userIdAnnon {
            XCTAssertFalse(anonUser.isEmpty, "Expected anon user")
               } else {
                   XCTFail("Expected anon user but found nil")
               }
        
        IterableAPI.setEmail("testuser123@test.com", disableReplay: false)

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
    
    func testCriteriaMatchDisableMergeAndReplayDefaultWithEmail() {  // criteria met with merge default with setEmail
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)
        IterableAPI.logoutUser()
        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData
        IterableAPI.track(event: "testEvent")
        waitForDuration(seconds: 3)

        if let anonUser = localStorage.userIdAnnon {
            XCTAssertFalse(anonUser.isEmpty, "Expected anon user")
               } else {
                   XCTFail("Expected anon user but found nil")
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
    
    
    func testCurrentUserIdentifiedWithDisableMergeAndReplayTrueWithEmail() {  // current user identified with setEmail merge false
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
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


        if let anonUser = localStorage.userIdAnnon {
                XCTFail("Expected anon user nil but found")
               } else {
                   XCTAssertNil(localStorage.anonymousUserEvents, "Expected anon user to be nil")
               }
        
        IterableAPI.setEmail("testuseranotheruser@test.com", disableReplay: true)
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
    
    
    func testCurrentUserIdentifiedWithDisableMergeAndReplayFalseWithEmail() {  // current user identified with setEmail true
        let config = IterableConfig()
        config.enableAnonTracking = true
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


        if localStorage.userIdAnnon != nil {
                XCTFail("Expected anon user nil but found")
               } else {
                   XCTAssertNil(localStorage.anonymousUserEvents, "Expected anon user to be nil")
               }
        
        IterableAPI.setEmail("testuseranotheruser@test.com", nil, disableReplay: false)
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
    
    func testCurrentUserIdentifiedWithMergeDefaultWithEmail() {  // current user identified with setEmail default
        let config = IterableConfig()
        config.enableAnonTracking = true
        let internalAPI = IterableAPI.initializeForTesting(apiKey: UserMergeScenariosTests.apiKey,
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


        if let anonUser = localStorage.userIdAnnon {
                XCTFail("Expected anon user nil but found")
               } else {
                   XCTAssertNil(localStorage.anonymousUserEvents, "Expected anon user to be nil")
               }
        
        IterableAPI.setEmail("testuseranotheruser@test.com", disableReplay: true)
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
}


