//
//  Created by Jay Kim on 7/6/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class AuthTests: XCTestCase {
    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"
    private static let userId = "testUserId"
    private static let authToken = "testAuthToken"
    
    override func setUp() {
        super.setUp()
    }
    
    func testEmailPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        internalAPI.email = AuthTests.email
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testUserIdPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        internalAPI.userId = AuthTests.userId
        
        XCTAssertNil(internalAPI.email)
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testEmailWithTokenPersistence() {
        let config = IterableConfig()
        
        let emailToken = "asdf"
        
        config.onAuthTokenRequestedCallback = { () in
            emailToken
        }
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.email = "previous.user@example.com"
        
        internalAPI.setEmail(AuthTests.email)
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertEqual(internalAPI.auth.authToken, emailToken)
    }
    
    func testUserIdWithTokenPersistence() {
        let config = IterableConfig()
        
        let userIdToken = "qwer"
        
        config.onAuthTokenRequestedCallback = { () in
            userIdToken
        }
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)

        internalAPI.userId = "previousUserId"
        
        internalAPI.setUserId(AuthTests.userId)

        XCTAssertNil(internalAPI.email)
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        XCTAssertEqual(internalAPI.auth.authToken, userIdToken)
    }

    func testUserLoginAndLogout() {
        let internalAPI = IterableAPIInternal.initializeForTesting()

        internalAPI.setEmail(AuthTests.email)

        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)

        internalAPI.email = nil

        XCTAssertNil(internalAPI.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }

    func testNewEmailWithTokenChange() {
        var internalAPI: IterableAPIInternal?
        
        let originalEmail = "first@example.com"
        let originalToken = "fdsa"
        
        let newEmail = "second@example.com"
        let newToken = "jay"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            if internalAPI?.email == originalEmail { return originalToken }
            if internalAPI?.email == newEmail { return newToken }
            return nil
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }

        API.setEmail(originalEmail)

        XCTAssertEqual(API.email, originalEmail)
        XCTAssertNil(API.userId)
        XCTAssertEqual(API.auth.authToken, originalToken)

        API.setEmail(newEmail)

        XCTAssertEqual(API.email, newEmail)
        XCTAssertNil(API.userId)
        XCTAssertEqual(API.auth.authToken, newToken)
    }
    
    func testNewUserIdWithTokenChange() {
        var internalAPI: IterableAPIInternal?

        let originalUserId = "firstUserId"
        let originalToken = "nen"

        let newUserId = "secondUserId"
        let newToken = "greedIsland"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            if internalAPI?.userId == originalUserId { return originalToken }
            if internalAPI?.userId == newUserId { return newToken }
            return nil
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setUserId(originalUserId)

        XCTAssertNil(API.email)
        XCTAssertEqual(API.userId, originalUserId)
        XCTAssertEqual(API.auth.authToken, originalToken)

        API.setUserId(newUserId)

        XCTAssertNil(API.email)
        XCTAssertEqual(API.userId, newUserId)
        XCTAssertEqual(API.auth.authToken, newToken)
    }
    
    func testUpdateEmailWithToken() {
        let condition1 = expectation(description: "update email with auth token")
        
        var internalAPI: IterableAPIInternal?
        
        let originalEmail = "first@example.com"
        let originalToken = "fdsa"
        
        let updatedEmail = "second@example.com"
        let updatedToken = "jay"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            if internalAPI?.email == originalEmail { return originalToken }
            if internalAPI?.email == updatedEmail { return updatedToken }
            return nil
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setEmail(originalEmail)
        
        XCTAssertEqual(API.email, originalEmail)
        XCTAssertNil(API.userId)
        XCTAssertEqual(API.auth.authToken, originalToken)
        
        API.updateEmail(updatedEmail,
                        onSuccess: { data in
                            XCTAssertEqual(API.email, updatedEmail)
                            XCTAssertNil(API.userId)
                            XCTAssertEqual(API.auth.authToken, updatedToken)
                            condition1.fulfill()
        },
                        onFailure: nil)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testLogoutUser() {
        let config = IterableConfig()
        
        config.onAuthTokenRequestedCallback = { () in
            AuthTests.authToken
        }
        
        let localStorage = MockLocalStorage()

        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   localStorage: localStorage)
        
        XCTAssertNil(localStorage.email)
        XCTAssertNil(localStorage.userId)
        XCTAssertNil(localStorage.authToken)

        internalAPI.setEmail(AuthTests.email)

        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertEqual(internalAPI.auth.authToken, AuthTests.authToken)

        XCTAssertEqual(localStorage.email, AuthTests.email)
        XCTAssertNil(localStorage.userId)
        XCTAssertEqual(localStorage.authToken, AuthTests.authToken)

        internalAPI.logoutUser()

        XCTAssertNil(internalAPI.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)

        XCTAssertNil(localStorage.email)
        XCTAssertNil(localStorage.userId)
        XCTAssertNil(localStorage.authToken)
    }
    
    func testAuthTokenChangeWithSameEmail() {
        var authTokenChanged = false
        
        var internalAPI: IterableAPIInternal?
        
        let newAuthToken = AuthTests.authToken + "3984ru398gj893"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            guard internalAPI?.email == AuthTests.email else { return nil }
            
            return authTokenChanged ? newAuthToken : AuthTests.authToken
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }

        API.setEmail(AuthTests.email)
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken(false)
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testAuthTokenChangeWithSameUserId() {
        var authTokenChanged = false
        
        var internalAPI: IterableAPIInternal?
        
        let newAuthToken = AuthTests.authToken + "3984ru398gj893"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            guard internalAPI?.userId == AuthTests.userId else { return nil }
            
            return authTokenChanged ? newAuthToken : AuthTests.authToken
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setUserId(AuthTests.userId)

        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken(false)
        
        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testOnNewAuthTokenCallbackCalled() {
        let condition1 = expectation(description: "\(#function) - auth failure callback didn't get called")
        
        var callbackCalled = false
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = {
            callbackCalled = true
            return nil
        }
        
        let mockNetworkSession = MockNetworkSession(statusCode: 401,
                                                    json: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload])
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   networkSession: mockNetworkSession)
        
        internalAPI.email = AuthTests.email
        
        internalAPI.track("event",
                          dataFields: nil,
                          onSuccess: { data in
                            XCTFail("track event shouldn't have succeeded")
        }, onFailure: { reason, data in
            XCTAssertTrue(callbackCalled)
            condition1.fulfill()
        })
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testDecodeExpirationDate() {
        // generated using https://jwt.io
        let encodedExpDate = 1516239122
        let jwt = """
        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkxMjJ9.-fM8Z-u88K5GGomqJxRCilYkjXZusY_Py6kdyzh1EAg
        """
        
        guard let decodedExpDate = AuthManager.decodeExpirationDateFromAuthToken(jwt) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(decodedExpDate, encodedExpDate)
    }
    
    func testAuthTokenRefreshQueued() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called when refresh was fired")
        
        let authTokenRequestedCallback: (() -> String?)? = {
            condition1.fulfill()
            return nil
        }
        
        let refreshWindow: TimeInterval = 0
        let waitTime: TimeInterval = 2
        let expirationTimeSinceEpoch = Date(timeIntervalSinceNow: refreshWindow + waitTime).timeIntervalSince1970
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let localStorage = MockLocalStorage()
        let authManager = AuthManager(onAuthTokenRequestedCallback: authTokenRequestedCallback,
                                      localStorage: localStorage,
                                      dateProvider: MockDateProvider(),
                                      refreshWindow: refreshWindow)
        localStorage.authToken = mockEncodedPayload
        authManager.retrieveAuthToken()
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }

    func testAuthTokenRefreshOnInit() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called when refresh was fired")
        
        let authTokenRequestedCallback: (() -> String?)? = {
            condition1.fulfill()
            return nil
        }
        
        let refreshWindow: TimeInterval = 0
        let waitTime: TimeInterval = 2
        let expirationTimeSinceEpoch = Date(timeIntervalSinceNow: refreshWindow + waitTime).timeIntervalSince1970
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let mockLocalStorage = MockLocalStorage()
        mockLocalStorage.authToken = mockEncodedPayload
        
        _ = AuthManager(onAuthTokenRequestedCallback: authTokenRequestedCallback,
                        localStorage: mockLocalStorage,
                        dateProvider: MockDateProvider(),
                        refreshWindow: refreshWindow)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenCallbackOnSetEmail() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called after setEmail")
        
        let authTokenRequestedCallback: (() -> String?)? = {
            condition1.fulfill()
            return nil
        }
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = authTokenRequestedCallback
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.setEmail(AuthTests.email)
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenCallbackOnSetUserId() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called after setEmail")
        
        let authTokenRequestedCallback: (() -> String?)? = {
            condition1.fulfill()
            return nil
        }
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = authTokenRequestedCallback
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.setUserId(AuthTests.userId)
        
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    private func createMockEncodedPayload(exp: Int) -> String {
        let payload = """
        {
            "email": "\(AuthTests.email)",
            "exp": \(exp)
        }
        """
        
        return "asdf.\(payload.data(using: .utf8)!.base64EncodedString()).asdf"
    }
}
