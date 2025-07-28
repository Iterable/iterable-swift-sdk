//
//  ValidateTokenForDestinationUserTest.swift
//  unit-tests
//
//  Created by Apple on 22/10/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import XCTest
@testable import IterableSDK

final class ValidateTokenForDestinationUserTest: XCTestCase {

    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"
    private static let userId = "testUserId"
    private static let userIdUnknownUserToken = "JWTAnnonToken"
    private static let mergeUserIdToken = "mergeUserIdToken"
    private static let mergeUserEmailToken = "mergeUserEmailToken"
    private let dateProvider = MockDateProvider()
    let mockSession = MockNetworkSession(statusCode: 200)
    let localStorage = MockLocalStorage()


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

    // Helper function to wait for a specified duration
    private func waitForDuration(seconds: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting for \(seconds) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: seconds + 1)
    }

    let mockData = """
    {
      "count": 1,
      "criteriaSets": [
        {
          "criteriaId": "6",
          "name": "EventCriteria",
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
                          "value": "animal-found",
                          "fieldType": "string"
                        },
                        {
                          "dataType": "customEvent",
                          "field": "animal-found.type",
                          "comparatorType": "Equals",
                          "value": "cat",
                          "fieldType": "string"
                        },
                        {
                          "dataType": "customEvent",
                          "field": "animal-found.count",
                          "comparatorType": "Equals",
                          "value": "6",
                          "fieldType": "string"
                        },
                        {
                          "dataType": "customEvent",
                          "field": "animal-found.vaccinated",
                          "comparatorType": "Equals",
                          "value": "true",
                          "fieldType": "boolean"
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

    class DefaultAuthDelegate: IterableAuthDelegate {
        var authTokenGenerator: (() -> String?)

        init(_ authTokenGenerator: @escaping () -> String?) {
            self.authTokenGenerator = authTokenGenerator
        }

        func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
            completion(authTokenGenerator())
        }

        func onAuthFailure(_ authFailure: AuthFailure) {

        }
    }

    private func createAuthDelegate(_ authTokenGenerator: @escaping () -> String?) -> IterableAuthDelegate {
        return DefaultAuthDelegate(authTokenGenerator)
    }

    func testCriteriaUserIdTokenCheck() {  // criteria not met with merge false with setUserId

        let authDelegate = createAuthDelegate({
            if self.localStorage.userIdUnknownUser == IterableAPI.userId {
                return  ValidateTokenForDestinationUserTest.userIdUnknownUserToken
            } else if IterableAPI.userId == ValidateTokenForDestinationUserTest.userId {
                return  ValidateTokenForDestinationUserTest.mergeUserIdToken
            } else {
                return nil
            }

        })

        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.authDelegate = authDelegate
        IterableAPI.initializeForTesting(apiKey: ValidateTokenForDestinationUserTest.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)

        IterableAPI.track(event: "button-clicked", dataFields: ["lastPageViewed":"signup page", "timestemp_createdAt": Int(Date().timeIntervalSince1970)])

        IterableAPI.track(event: "animal-found", dataFields: ["type": "cat",
                                                              "count": 6,
                                                              "vaccinated": true])

        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData

        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
       } else {
           XCTFail("Expected events to be logged but found nil")
       }

        let expectation = XCTestExpectation(description: "testTrackEventWithCreateAnnonUser")
        IterableAPI.track(event: "animal-found", dataFields: ["type": "cat",
                                                              "count": 6,
                                                              "vaccinated": true])

        let checker = CriteriaCompletionChecker(unknownUserCriteria: jsonData, unknownUserEvents:localStorage.unknownUserEvents ?? [])
        let matchedCriteriaId = checker.getMatchedCriteria()
        XCTAssertEqual(matchedCriteriaId, "6")
       
        waitForDuration(seconds: 5)

        let trackDataField = ["type": "cat",
                              "count": 6,
                              "vaccinated": true] as [String : Any]
        IterableAPI.track(event: "animal-found", dataFields:trackDataField , onSuccess: { _ in
            let request = self.mockSession.getRequest(withEndPoint: Const.Path.trackEvent)!
            TestUtils.validate(request: request, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.trackEvent, queryParams: [])
            if let requestHeader = request.allHTTPHeaderFields, let token = requestHeader["Authorization"] {
                XCTAssertEqual(token, "Bearer \(ValidateTokenForDestinationUserTest.userIdUnknownUserToken)")
            }
            expectation.fulfill()
        }) { reason, _ in
            expectation.fulfill()
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        wait(for: [expectation], timeout: testExpectationTimeout)

        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user")
       } else {
           XCTFail("Expected unknown user but found nil")
       }
        XCTAssertEqual(IterableAPI.userId, localStorage.userIdUnknownUser)
        XCTAssertNil(IterableAPI.email)
        XCTAssertEqual(IterableAPI.authToken, ValidateTokenForDestinationUserTest.userIdUnknownUserToken)


        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: true)
        IterableAPI.setUserId(ValidateTokenForDestinationUserTest.userId, nil, identityResolution)

        // Verify "merge user" API call is made
        let expectation1 = XCTestExpectation(description: "API call is made to merge user")
        DispatchQueue.main.async {
            if let request = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                TestUtils.validate(request: request, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.mergeUser, queryParams: [])
                if let requestHeader = request.allHTTPHeaderFields, let token = requestHeader["Authorization"] {
                    XCTAssertEqual(token, "Bearer \(ValidateTokenForDestinationUserTest.mergeUserIdToken)")
                }
                expectation1.fulfill()
            } else {
                expectation1.fulfill()
                XCTFail("Expected merge user API call was not made")
            }
        }
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(IterableAPI.userId, ValidateTokenForDestinationUserTest.userId)
        XCTAssertNil(IterableAPI.email)
        XCTAssertEqual(IterableAPI.authToken, ValidateTokenForDestinationUserTest.mergeUserIdToken)
    }

    func testCriteriaEmailTokenCheck() {  // criteria not met with merge false with setUserId

        let authDelegate = createAuthDelegate({
            if self.localStorage.userIdUnknownUser == IterableAPI.userId {
                return  ValidateTokenForDestinationUserTest.userIdUnknownUserToken
            } else if IterableAPI.userId == ValidateTokenForDestinationUserTest.userId {
                return  ValidateTokenForDestinationUserTest.mergeUserIdToken
            } else if IterableAPI.email == ValidateTokenForDestinationUserTest.email {
                return  ValidateTokenForDestinationUserTest.mergeUserEmailToken
            } else {
                return nil
            }

        })

        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.authDelegate = authDelegate
        IterableAPI.initializeForTesting(apiKey: ValidateTokenForDestinationUserTest.apiKey,
                                                                   config: config,
                                                                   networkSession: mockSession,
                                                                   localStorage: localStorage)

        IterableAPI.track(event: "button-clicked", dataFields: ["lastPageViewed":"signup page", "timestemp_createdAt": Int(Date().timeIntervalSince1970)])

        IterableAPI.track(event: "animal-found", dataFields: ["type": "cat",
                                                              "count": 6,
                                                              "vaccinated": true])

        guard let jsonData = mockData.data(using: .utf8) else { return }
        localStorage.criteriaData = jsonData

        if let events = localStorage.unknownUserEvents {
            XCTAssertFalse(events.isEmpty, "Expected events to be logged")
       } else {
           XCTFail("Expected events to be logged but found nil")
       }

        let expectation = XCTestExpectation(description: "testTrackEventWithCreateAnnonUser")
        IterableAPI.track(event: "animal-found", dataFields: ["type": "cat",
                                                              "count": 6,
                                                              "vaccinated": true])

        let checker = CriteriaCompletionChecker(unknownUserCriteria: jsonData, unknownUserEvents:localStorage.unknownUserEvents ?? [])
        let matchedCriteriaId = checker.getMatchedCriteria()
        XCTAssertEqual(matchedCriteriaId, "6")

        waitForDuration(seconds: 5)

        let trackDataField = ["type": "cat",
                              "count": 6,
                              "vaccinated": true] as [String : Any]
        IterableAPI.track(event: "animal-found", dataFields:trackDataField , onSuccess: { _ in
            let request = self.mockSession.getRequest(withEndPoint: Const.Path.trackEvent)!
            TestUtils.validate(request: request, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.trackEvent, queryParams: [])
            if let requestHeader = request.allHTTPHeaderFields, let token = requestHeader["Authorization"] {
                XCTAssertEqual(token, "Bearer \(ValidateTokenForDestinationUserTest.userIdUnknownUserToken)")
            }
            expectation.fulfill()
        }) { reason, _ in
            expectation.fulfill()
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }

        wait(for: [expectation], timeout: testExpectationTimeout)

        if let unknownUser = localStorage.userIdUnknownUser {
            XCTAssertFalse(unknownUser.isEmpty, "Expected unknown user")
       } else {
           XCTFail("Expected unknown user but found nil")
       }
        XCTAssertEqual(IterableAPI.userId, localStorage.userIdUnknownUser)
        XCTAssertNil(IterableAPI.email)
        XCTAssertEqual(IterableAPI.authToken, ValidateTokenForDestinationUserTest.userIdUnknownUserToken)

        let identityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: true)
        IterableAPI.setEmail(ValidateTokenForDestinationUserTest.email, nil, identityResolution)

        // Verify "merge user" API call is made
        let expectation1 = XCTestExpectation(description: "API call is made to merge user")
        DispatchQueue.main.async {
            if let request = self.mockSession.getRequest(withEndPoint: Const.Path.mergeUser) {
                // Pass the test if the API call was made
                TestUtils.validate(request: request, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.mergeUser, queryParams: [])
                if let requestHeader = request.allHTTPHeaderFields, let token = requestHeader["Authorization"] {
                    XCTAssertEqual(token, "Bearer \(ValidateTokenForDestinationUserTest.mergeUserEmailToken)")
                }
                expectation1.fulfill()
            } else {
                expectation1.fulfill()
                XCTFail("Expected merge user API call was not made")
            }
        }
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(IterableAPI.email, ValidateTokenForDestinationUserTest.email)
        XCTAssertNil(IterableAPI.userId)
        XCTAssertEqual(IterableAPI.authToken, ValidateTokenForDestinationUserTest.mergeUserEmailToken)
    }
}
