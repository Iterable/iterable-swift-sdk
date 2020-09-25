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
        let emailToken = "asdf"
        
        let authDelegate = createAuthDelegate { completion in
            completion(emailToken)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.email = "previous.user@example.com"
        
        internalAPI.setEmail(AuthTests.email)
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertEqual(internalAPI.auth.authToken, emailToken)
    }
    
    func testUserIdWithTokenPersistence() {
        let userIdToken = "qwer"
        
        let authDelegate = createAuthDelegate { completion in
            completion(userIdToken)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
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
        
        let authDelegate = createAuthDelegate { completion in
            if internalAPI?.email == originalEmail { completion(originalToken) }
            if internalAPI?.email == newEmail { completion(newToken) }
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
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
        
        let authDelegate = createAuthDelegate { completion in
            if internalAPI?.userId == originalUserId { completion(originalToken) }
            if internalAPI?.userId == newUserId { completion(newToken) }
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
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
        
        let authDelegate = createAuthDelegate { completion in
            if internalAPI?.email == originalEmail { completion(originalToken) }
            if internalAPI?.email == updatedEmail { completion(updatedToken) }
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
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
                        onSuccess: { _ in
                            XCTAssertEqual(API.email, updatedEmail)
                            XCTAssertNil(API.userId)
                            XCTAssertEqual(API.auth.authToken, updatedToken)
                            condition1.fulfill()
                        },
                        onFailure: nil)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testLogoutUser() {
        let authDelegate = createStockAuthDelegate()
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
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
        
        let authDelegate = createAuthDelegate { completion in
            guard internalAPI?.email == AuthTests.email else {
                completion(nil)
                return
            }
            
            completion(authTokenChanged ? newAuthToken : AuthTests.authToken)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setEmail(AuthTests.email)
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: nil)
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testAuthTokenChangeWithSameUserId() {
        var authTokenChanged = false
        
        var internalAPI: IterableAPIInternal?
        
        let newAuthToken = AuthTests.authToken + "3984ru398gj893"
        
        let authDelegate = createAuthDelegate { completion in
            guard internalAPI?.userId == AuthTests.userId else {
                completion(nil)
                return
            }
            
            completion(authTokenChanged ? newAuthToken : AuthTests.authToken)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setUserId(AuthTests.userId)
        
        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: nil)
        
        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testOnNewAuthTokenCallbackCalled() {
        let condition1 = expectation(description: "\(#function) - auth failure callback didn't get called")
        
        var callbackCalled = false
        
        let authDelegate = createAuthDelegate { completion in
            callbackCalled = true
            completion(nil)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let mockNetworkSession = MockNetworkSession(statusCode: 401,
                                                    json: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload])
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   networkSession: mockNetworkSession)
        
        internalAPI.email = AuthTests.email
        
        internalAPI.track("event",
                          dataFields: nil,
                          onSuccess: { _ in
                              XCTFail("track event shouldn't have succeeded")
                          }, onFailure: { _, _ in
                              XCTAssertTrue(callbackCalled)
                              condition1.fulfill()
                          })
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testDecodeExpirationDate() {
        // generated using https://jwt.io
        let encodedExpDate = 1_516_239_122
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
        
        let authDelegate = createAuthDelegate { completion in
            condition1.fulfill()
            completion(nil)
        }
        
        let refreshWindow: TimeInterval = 0
        let waitTime: TimeInterval = 2
        let expirationTimeSinceEpoch = Date(timeIntervalSinceNow: refreshWindow + waitTime).timeIntervalSince1970
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let localStorage = MockLocalStorage()
        
        localStorage.authToken = mockEncodedPayload
        
        let authManager = AuthManager(delegate: authDelegate,
                                      refreshWindow: refreshWindow,
                                      localStorage: localStorage,
                                      dateProvider: MockDateProvider())
        
        _ = authManager
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenRefreshOnInit() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called when refresh was fired")
        
        let authDelegate = createAuthDelegate { completion in
            condition1.fulfill()
            completion(nil)
        }
        
        let refreshWindow: TimeInterval = 0
        let waitTime: TimeInterval = 2
        let expirationTimeSinceEpoch = Date(timeIntervalSinceNow: refreshWindow + waitTime).timeIntervalSince1970
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let mockLocalStorage = MockLocalStorage()
        mockLocalStorage.authToken = mockEncodedPayload
        
        let authManager = AuthManager(delegate: authDelegate,
                                      refreshWindow: refreshWindow,
                                      localStorage: mockLocalStorage,
                                      dateProvider: MockDateProvider())
        
        _ = authManager
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenCallbackOnSetEmail() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called after setEmail")
        
        let authDelegate = createAuthDelegate { completion in
            condition1.fulfill()
            completion(nil)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.setEmail(AuthTests.email)
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenCallbackOnSetUserId() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called after setEmail")
        
        let authDelegate = createAuthDelegate { completion in
            condition1.fulfill()
            completion(nil)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.setUserId(AuthTests.userId)
        
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenDeletedOnLogout() {
        let authDelegate = createAuthDelegate { completion in
            completion(AuthTests.authToken)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.email = AuthTests.email
        
        XCTAssertEqual(internalAPI.auth.authToken, AuthTests.authToken)
        
        internalAPI.logoutUser()
        
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testAuthTokenRefreshRetryOnlyOnce() {
        let condition1 = expectation(description: "\(#function) - callback not called correctly in some form")
        condition1.expectedFulfillmentCount = 2
        
        let authDelegate = createAuthDelegate { completion in
            condition1.fulfill()
            completion(AuthTests.authToken)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let mockNetworkSession = MockNetworkSession(statusCode: 401,
                                                    json: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload])
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   networkSession: mockNetworkSession)
        
        internalAPI.email = AuthTests.email
        
        // two calls here to trigger the retry more than once
        internalAPI.track("event")
        internalAPI.track("event")
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testPriorAuthFailedRetryPrevention() {
        let condition1 = expectation(description: "\(#function) - incorrect number of retry calls")
        condition1.expectedFulfillmentCount = 2
        
        let authDelegate = createAuthDelegate { completion in
            condition1.fulfill()
            completion(nil)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let authManager = AuthManager(delegate: authDelegate,
                                      refreshWindow: config.authTokenRefreshWindow,
                                      localStorage: MockLocalStorage(),
                                      dateProvider: MockDateProvider())
        
        // a normal call to ensure default states
        authManager.requestNewAuthToken()
        
        // 2 failing calls to ensure both the manager and the incoming request test retry prevention
        authManager.requestNewAuthToken(hasFailedPriorAuth: true)
        authManager.requestNewAuthToken(hasFailedPriorAuth: true)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testPriorAuthFailedRetrySuccess() {
        let condition1 = expectation(description: "\(#function) - incorrect number of retry calls")
        condition1.expectedFulfillmentCount = 3
        
        let authDelegate = createAuthDelegate { completion in
            condition1.fulfill()
            completion(nil)
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let authManager = AuthManager(delegate: authDelegate,
                                      refreshWindow: config.authTokenRefreshWindow,
                                      localStorage: MockLocalStorage(),
                                      dateProvider: MockDateProvider())
        
        // a normal call to ensure default states
        authManager.requestNewAuthToken()
        
        // 2 failing calls to ensure both the manager and the incoming request test retry prevention
        authManager.requestNewAuthToken(hasFailedPriorAuth: true)
        authManager.requestNewAuthToken(hasFailedPriorAuth: true)
        
        // and now a normal call
        authManager.requestNewAuthToken()
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testPushRegistrationAfterAuthTokenRetrieval() {
        let condition1 = expectation(description: "\(#function) - notification state provider not fulfilled")
        condition1.expectedFulfillmentCount = 2
        
        let authDelegate = createAuthDelegate { completion in
            completion(nil)
        }
        
        let mockNotificationStateProvider = MockNotificationStateProvider(enabled: true, expectation: condition1)
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   notificationStateProvider: mockNotificationStateProvider)
        
        internalAPI.email = AuthTests.email
        
        internalAPI.email = "different@email.com"
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAsyncAuthTokenRetrieval() {
        let condition1 = expectation(description: "\(#function) - async auth token retrieval failed")
        
        class AsyncAuthDelegate: IterableAuthDelegate {
            func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    completion(AuthTests.authToken)
                }
            }
        }
        
        let authDelegate = AsyncAuthDelegate()
        
        let authManager = AuthManager(delegate: authDelegate,
                                      refreshWindow: 0,
                                      localStorage: MockLocalStorage(),
                                      dateProvider: MockDateProvider())
        
        authManager.requestNewAuthToken(hasFailedPriorAuth: false,
                                        onSuccess: { token in
                                            XCTAssertEqual(token, AuthTests.authToken)
                                            condition1.fulfill()
                                        })
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenRetrievalFailureReset() {
        let condition1 = expectation(description: "\(#function) - retry was not reset")
        let condition2 = expectation(description: "\(#function) - call should not have reached success handler")
        condition2.isInverted = true
        let condition3 = expectation(description: "\(#function) - couldn't get token when requested")
        
        class AuthDelegate: IterableAuthDelegate {
            func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
                completion(AuthTests.authToken)
            }
        }
        
        let authDelegate = AuthDelegate()
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        // setEmail calls gets the new auth token successfully
        internalAPI.email = AuthTests.email
        
        // pass a failed state to the AuthManager
        internalAPI.authManager.requestNewAuthToken(hasFailedPriorAuth: true, onSuccess: nil)
        
        // verify that on retry it's still in a failed state with the inverted condition
        internalAPI.authManager.requestNewAuthToken(hasFailedPriorAuth: true,
                                                    onSuccess: { _ in
                                                        condition2.fulfill()
                                                    })
        
        // now make a successful request to reset the AuthManager
        internalAPI.track("", onSuccess: { _ in
            condition1.fulfill()
        })
        
        // verify that the AuthManager is able to request a new token again
        internalAPI.authManager.requestNewAuthToken(hasFailedPriorAuth: false,
                                                    onSuccess: { _ in
                                                        condition3.fulfill()
                                                    })
        
        wait(for: [condition1, condition2, condition3], timeout: testExpectationTimeoutForInverted)
    }
    
    // MARK: - Private
    
    class DefaultAuthDelegate: IterableAuthDelegate {
        var requestedCallback: ((AuthTokenRetrievalHandler) -> Void)?
        
        init(_ requestedCallback: ((AuthTokenRetrievalHandler) -> Void)?) {
            self.requestedCallback = requestedCallback
        }
        
        func onAuthTokenRequested(completion: AuthTokenRetrievalHandler) {
            requestedCallback?(completion)
        }
    }
    
    private func createAuthDelegate(_ requestedCallback: @escaping (AuthTokenRetrievalHandler) -> Void) -> IterableAuthDelegate {
        DefaultAuthDelegate(requestedCallback)
    }
    
    private func createStockAuthDelegate() -> IterableAuthDelegate {
        DefaultAuthDelegate { completion in
            completion(AuthTests.authToken)
        }
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
