//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest
import CryptoKit

@testable import IterableSDK

@available(iOS 13, *)
class AuthTests: XCTestCase {
    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"
    private static let userId = "testUserId"
    private static let authToken = "testAuthToken"
    
    override func setUp() {
        super.setUp()
    }
    
    func testEmailPersistence() {
        let internalAPI = InternalIterableAPI.initializeForTesting()
        
        internalAPI.email = AuthTests.email
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testUserIdPersistence() {
        let internalAPI = InternalIterableAPI.initializeForTesting()
        
        internalAPI.userId = AuthTests.userId
        
        XCTAssertNil(internalAPI.email)
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testEmailWithTokenPersistence() {
        let authToken = AuthTests.generateJwt()
        
        let authDelegate = createAuthDelegate({ authToken })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        internalAPI.email = "previous.user@example.com"
        
        internalAPI.email = AuthTests.email
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertEqual(internalAPI.authToken, authToken)
    }
    
    func testUserIdWithTokenPersistence() {
        let userIdToken = "qwer"
        
        let authDelegate = createAuthDelegate { userIdToken }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        internalAPI.userId = "previousUserId"
        
        internalAPI.setUserId(AuthTests.userId)
        
        XCTAssertNil(internalAPI.email)
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        XCTAssertEqual(internalAPI.auth.authToken, userIdToken)
    }
    
    func testUserLoginAndLogout() {
        let internalAPI = InternalIterableAPI.initializeForTesting()
        
        internalAPI.setEmail(AuthTests.email)
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)
        
        internalAPI.email = nil
        
        XCTAssertNil(internalAPI.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testNewEmailAndThenChangeToken() {
        var internalAPI: InternalIterableAPI?
        
        let originalEmail = "first@example.com"
        let originalToken = "fdsa"
        
        let newEmail = "second@example.com"
        let newToken = "jay"
        
        let authDelegate = createAuthDelegate({
            if internalAPI?.email == originalEmail { return originalToken }
            else if internalAPI?.email == newEmail { return newToken }
            else { return nil }
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
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
    
    func testNewUserIdAndThenChangeToken() {
        var internalAPI: InternalIterableAPI?
        
        let originalUserId = "firstUserId"
        let originalToken = "nen"
        
        let newUserId = "secondUserId"
        let newToken = "greedIsland"
        
        let authDelegate = createAuthDelegate({
            if internalAPI?.userId == originalUserId { return originalToken }
            else if internalAPI?.userId == newUserId { return newToken }
            else { return nil }
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
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
    
    func testUpdateEmailAndThenChangeToken() {
        let condition1 = expectation(description: "update email and then change auth token")
        
        var internalAPI: InternalIterableAPI?
        
        let originalEmail = "first@example.com"
        let originalToken = "fdsa"
        
        let updatedEmail = "second@example.com"
        let updatedToken = "jay"
        
        let authDelegate = DefaultAuthDelegate {
            if internalAPI?.email == originalEmail { return originalToken }
            else if internalAPI?.email == updatedEmail { return updatedToken }
            else { return nil }
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
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
    
    func testUpdateEmailWithTokenParam() {
        let condition1 = expectation(description: #function)
        
        var internalAPI: InternalIterableAPI?
        
        let originalEmail = "rtbo"
        let originalToken = "hngk"
        
        let updatedEmail = "2"
        let updatedToken = "564g"
        
        let authDelegate = DefaultAuthDelegate {
            return originalToken
        }
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setEmail(originalEmail)
        
        XCTAssertEqual(API.email, originalEmail)
        XCTAssertNil(API.userId)
        XCTAssertEqual(API.auth.authToken, originalToken)
        
        API.updateEmail(updatedEmail, withToken: updatedToken) { data in
            XCTAssertEqual(API.email, updatedEmail)
            XCTAssertNil(API.userId)
            XCTAssertEqual(API.auth.authToken, updatedToken)
            
            condition1.fulfill()
        } onFailure: { reason, data in
            XCTFail()
        }
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testLogoutUser() {
        let authDelegate = createStockAuthDelegate()
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let localStorage = MockLocalStorage()
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config,
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
        
        var internalAPI: InternalIterableAPI?
        
        let newAuthToken = AuthTests.authToken + "3984ru398gj893"
        
        let authDelegate = createAuthDelegate({
            guard internalAPI?.email == AuthTests.email else {
                return nil
            }
            
            return authTokenChanged ? newAuthToken : AuthTests.authToken
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setEmail(AuthTests.email)
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: nil, shouldIgnoreRetryPolicy: true)
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testAuthTokenChangeWithSameUserId() {
        var authTokenChanged = false
        
        var internalAPI: InternalIterableAPI?
        
        let newAuthToken = AuthTests.authToken + "3984ru398gj893"
        
        let authDelegate = createAuthDelegate({
            guard internalAPI?.userId == AuthTests.userId else {
                return nil
            }
            
            return (authTokenChanged ? newAuthToken : AuthTests.authToken)
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setUserId(AuthTests.userId)
        
        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: nil, shouldIgnoreRetryPolicy: true)
        
        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testOnNewAuthTokenCallbackCalled() {
        let condition1 = expectation(description: "\(#function) - auth failure callback didn't get called")
        
        var callbackCalled = false
        
        let authDelegate = createAuthDelegate({
            callbackCalled = true
            return nil
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let mockNetworkSession = MockNetworkSession(statusCode: 401,
                                                    json: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload])
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config,
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
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let expirationRefreshPeriod: TimeInterval = 0
        let waitTime: TimeInterval = 1.0
        let mockDateProvider = MockDateProvider()
        mockDateProvider.currentDate = Date(timeIntervalSince1970: 1_000_000_000)
        let expirationTimeSinceEpoch = mockDateProvider.currentDate.timeIntervalSince1970 + expirationRefreshPeriod + waitTime
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let localStorage = MockLocalStorage()
        
        localStorage.authToken = mockEncodedPayload
        localStorage.userId = AuthTests.userId
        
        let authManager = AuthManager(delegate: authDelegate, 
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: expirationRefreshPeriod,
                                      localStorage: localStorage,
                                      dateProvider: mockDateProvider)
        
        let _ = authManager
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }

    func testPauseAuthRetriesBlocksScheduledRefresh() {
        let callbackNotCalledExpectation = expectation(description: "\(#function) - callback got called when it shouldn't while paused")
        callbackNotCalledExpectation.isInverted = true
        
        let authDelegate = createAuthDelegate({
            callbackNotCalledExpectation.fulfill()
            return nil
        })
        
        let expirationRefreshPeriod: TimeInterval = 0
        let waitTime: TimeInterval = 1.0
        
        let mockDateProvider = MockDateProvider()
        mockDateProvider.currentDate = Date(timeIntervalSince1970: 1_000_000_000)
        let expirationTimeSinceEpoch = mockDateProvider.currentDate.timeIntervalSince1970 + expirationRefreshPeriod + waitTime
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let localStorage = MockLocalStorage()
        localStorage.authToken = mockEncodedPayload
        localStorage.userId = AuthTests.userId
        
        let authManager = AuthManager(delegate: authDelegate,
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: expirationRefreshPeriod,
                                      localStorage: localStorage,
                                      dateProvider: mockDateProvider)
        
        authManager.pauseAuthRetries(true)
        
        wait(for: [callbackNotCalledExpectation], timeout: waitTime + 1.0)
    }

    func testMaxRetryLimitRespectedForScheduledRefresh() {
        let secondCallbackNotCalledExpectation = expectation(description: "\(#function) - scheduled refresh requested auth token beyond maxRetry")
        secondCallbackNotCalledExpectation.isInverted = true
        
        let expirationRefreshPeriod: TimeInterval = 0
        let mockDateProvider = MockDateProvider()
        mockDateProvider.currentDate = Date(timeIntervalSince1970: 1_000_000_000)
        
        let expiredExp = Int(mockDateProvider.currentDate.timeIntervalSince1970 - 10)
        let expiredToken = createMockEncodedPayload(exp: expiredExp)
        
        var callbackCount = 0
        let authDelegate = createAuthDelegate({
            callbackCount += 1
            if callbackCount > 1 {
                secondCallbackNotCalledExpectation.fulfill()
            }
            return expiredToken
        })
        
        let localStorage = MockLocalStorage()
        localStorage.userId = AuthTests.userId
        
        let authManager = AuthManager(delegate: authDelegate,
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: expirationRefreshPeriod,
                                      localStorage: localStorage,
                                      dateProvider: mockDateProvider)
        
        // 1st attempt increments retryCount to maxRetry
        authManager.requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: nil, shouldIgnoreRetryPolicy: true)
        
        // Scheduled refresh attempt must respect maxRetry even when shouldIgnoreRetryPolicy is true.
        authManager.scheduleAuthTokenRefreshTimer(interval: 0.01, isScheduledRefresh: true, successCallback: nil)
        
        wait(for: [secondCallbackNotCalledExpectation], timeout: 1.0)
        XCTAssertEqual(callbackCount, 1)
    }
    
    func testAuthTokenRefreshOnInit() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called when refresh was fired")
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let expirationRefreshPeriod: TimeInterval = 0
        let waitTime: TimeInterval = 1.0
        let expirationTimeSinceEpoch = Date(timeIntervalSinceNow: expirationRefreshPeriod + waitTime).timeIntervalSince1970
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let mockLocalStorage = MockLocalStorage()
        mockLocalStorage.authToken = mockEncodedPayload
        mockLocalStorage.email = AuthTests.email
        
        let authManager = AuthManager(delegate: authDelegate, 
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: expirationRefreshPeriod,
                                      localStorage: mockLocalStorage,
                                      dateProvider: MockDateProvider())
        
        let _ = authManager
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenRefreshSkippedIfUserLoggedOutAfterReschedule() {
        let callbackNotCalledExpectation = expectation(description: "\(#function) - Callback got called. Which it shouldn't when there is no userId or emailId in memory")
        callbackNotCalledExpectation.isInverted = true
        
        let authDelegate = createAuthDelegate({
            callbackNotCalledExpectation.fulfill()
            return nil
        })
        
        let expirationRefreshPeriod: TimeInterval = 0
        let waitTime: TimeInterval = 1.0
        let expirationTimeSinceEpoch = Date(timeIntervalSinceNow: expirationRefreshPeriod + waitTime).timeIntervalSince1970
        let mockEncodedPayload = createMockEncodedPayload(exp: Int(expirationTimeSinceEpoch))
        
        let mockLocalStorage = MockLocalStorage()
        mockLocalStorage.authToken = mockEncodedPayload
        mockLocalStorage.email = nil
        mockLocalStorage.userId = nil
        
        let authManager = AuthManager(delegate: authDelegate, 
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: expirationRefreshPeriod,
                                      localStorage: mockLocalStorage,
                                      dateProvider: MockDateProvider())
        
        let _ = authManager
        
        wait(for: [callbackNotCalledExpectation], timeout: 2.0)
    }
    
    func testAuthTokenCallbackOnSetEmail() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called after setEmail")
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        internalAPI.setEmail(AuthTests.email)
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenCallbackOnSetUserId() {
        let condition1 = expectation(description: "\(#function) - callback didn't get called after setEmail")
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        internalAPI.setUserId(AuthTests.userId)
        
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testAuthTokenDeletedOnLogout() {
        let authDelegate = createAuthDelegate({ AuthTests.authToken })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        internalAPI.email = AuthTests.email
        
        XCTAssertEqual(internalAPI.auth.authToken, AuthTests.authToken)
        
        internalAPI.logoutUser()
        
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testAuthTokenRefreshRetryOnlyOnce() throws {        
        let condition1 = expectation(description: "\(#function) - callback not called correctly in some form")
        condition1.expectedFulfillmentCount = 2
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return AuthTests.authToken
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let mockNetworkSession = MockNetworkSession(statusCode: 401,
                                                    json: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload])
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config,
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
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let authManager = AuthManager(delegate: authDelegate, 
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: config.expiringAuthTokenRefreshPeriod,
                                      localStorage: MockLocalStorage(),
                                      dateProvider: MockDateProvider())
        
        // a normal call to ensure default states
        authManager.requestNewAuthToken(shouldIgnoreRetryPolicy: true)
        
        // 2 failing calls to ensure both the manager and the incoming request test retry prevention
        authManager.requestNewAuthToken(hasFailedPriorAuth: true, shouldIgnoreRetryPolicy: true)
        authManager.requestNewAuthToken(hasFailedPriorAuth: true, shouldIgnoreRetryPolicy: true)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testPriorAuthFailedRetrySuccess() {
        let condition1 = expectation(description: "\(#function) - incorrect number of retry calls")
        condition1.expectedFulfillmentCount = 3
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let authManager = AuthManager(delegate: authDelegate, 
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: config.expiringAuthTokenRefreshPeriod,
                                      localStorage: MockLocalStorage(),
                                      dateProvider: MockDateProvider())
        
        // a normal call to ensure default states
        authManager.requestNewAuthToken(shouldIgnoreRetryPolicy: true)
        
        // 2 failing calls to ensure both the manager and the incoming request test retry prevention
        authManager.requestNewAuthToken(hasFailedPriorAuth: true, shouldIgnoreRetryPolicy: true)
        authManager.requestNewAuthToken(hasFailedPriorAuth: true, shouldIgnoreRetryPolicy: true)
        
        // and now a normal call
        authManager.requestNewAuthToken(shouldIgnoreRetryPolicy: true)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testPushRegistrationAfterAuthTokenRetrieval() {
        let condition1 = expectation(description: "\(#function) - push registration not fulfilled")
        condition1.expectedFulfillmentCount = 2
        
        let condition2 = expectation(description: "\(#function) - auth handler not fulfilled")
        condition2.expectedFulfillmentCount = 2
        
        let authDelegate = createAuthDelegate({
            condition2.fulfill()
            return AuthTests.authToken
        })
        
        let mockNotificationStateProvider = MockNotificationStateProvider(enabled: true, expectation: condition1)
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config,
                                                                   notificationStateProvider: mockNotificationStateProvider)
        
        internalAPI.email = AuthTests.email
        
        internalAPI.email = "different@email.com"
        
        wait(for: [condition1, condition2], timeout: testExpectationTimeout)
    }
    
    func testAsyncAuthTokenRetrieval() {
        let condition1 = expectation(description: "\(#function) - async auth token retrieval failed")
        
        class AsyncAuthDelegate: IterableAuthDelegate {
            func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion(AuthTests.authToken)
                }
            }
            
            func onAuthFailure(_ authFailure: AuthFailure) {
                
            }
        }
        
        let authDelegate = AsyncAuthDelegate()
        
        let authManager = AuthManager(delegate: authDelegate, 
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: 0,
                                      localStorage: MockLocalStorage(),
                                      dateProvider: MockDateProvider())
        
        authManager.requestNewAuthToken(hasFailedPriorAuth: false,
                                        onSuccess: { token in
                                            XCTAssertEqual(token, AuthTests.authToken)
                                            condition1.fulfill()
        }, shouldIgnoreRetryPolicy: true)
        
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
            
            func onAuthFailure(_ authFailure: AuthFailure) {
                
            }
        }
        
        let authDelegate = AuthDelegate()
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config)
        
        // setEmail calls gets the new auth token successfully
        internalAPI.email = AuthTests.email
        
        // pass a failed state to the AuthManager
        internalAPI.authManager.requestNewAuthToken(hasFailedPriorAuth: true, onSuccess: nil, shouldIgnoreRetryPolicy: true)
        
        // verify that on retry it's still in a failed state with the inverted condition
        internalAPI.authManager.requestNewAuthToken(hasFailedPriorAuth: true,
                                                    onSuccess: { token in
                                                        condition2.fulfill()
        }, shouldIgnoreRetryPolicy: true)
        
        // now make a successful request to reset the AuthManager
        internalAPI.track("", onSuccess: { data in
            condition1.fulfill()
        })
        
        // verify that the AuthManager is able to request a new token again
        internalAPI.authManager.requestNewAuthToken(hasFailedPriorAuth: false,
                                                    onSuccess: { token in
                                                        condition3.fulfill()
        }, shouldIgnoreRetryPolicy: true)
        
        wait(for: [condition1, condition3], timeout: testExpectationTimeout)
        wait(for: [condition2], timeout: testExpectationTimeoutForInverted)
    }
    
    func testRefreshTimerQueueRejection() {
        let condition1 = expectation(description: "\(#function) - first refresh timer never happened called")
        let condition2 = expectation(description: "\(#function) - second refresh timer should not have been called")
        condition2.isInverted = true
        
        class AsyncAuthDelegate: IterableAuthDelegate {
            func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion(AuthTests.authToken)
                }
            }
            
            func onAuthFailure(_ authFailure: AuthFailure) {
                
            }
        }
        
        let authDelegate = AsyncAuthDelegate()
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let authManager = AuthManager(delegate: config.authDelegate, 
                                      authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0, retryBackoff: .linear),
                                      expirationRefreshPeriod: config.expiringAuthTokenRefreshPeriod,
                                      localStorage: MockLocalStorage(),
                                      dateProvider: MockDateProvider())
        
        authManager.requestNewAuthToken(hasFailedPriorAuth: false,
                                        onSuccess: { token in
                                            XCTAssertEqual(token, AuthTests.authToken)
                                            condition1.fulfill()
        }, shouldIgnoreRetryPolicy: true)
        
        authManager.requestNewAuthToken(hasFailedPriorAuth: false,
                                        onSuccess: { token in
                                            condition2.fulfill()
        }, shouldIgnoreRetryPolicy: true)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
        wait(for: [condition2], timeout: 1.0)
    }
    
    func testAuthTokenNotRequestingForAlreadyExistingEmail() {
        let condition1 = expectation(description: "auth handler got called when it should not")
        condition1.isInverted = true
        
        let localStorage = MockLocalStorage()
        localStorage.email = AuthTests.email
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config,
                                                                   localStorage: localStorage)
        
        XCTAssertNotNil(internalAPI.email)
        XCTAssertNil(internalAPI.authManager.getAuthToken())
        
        internalAPI.email = AuthTests.email
        
        wait(for: [condition1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testLoggedOutAuthTokenRequest() {
        let condition1 = expectation(description: "auth handler was called")
        condition1.isInverted = true
        
        let localStorage = MockLocalStorage()
        localStorage.email = AuthTests.email
        
        let authDelegate = createAuthDelegate({
            condition1.fulfill()
            return nil
        })
        
        let config = IterableConfig()
        config.authDelegate = authDelegate
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config,
                                                                   localStorage: localStorage)
        
        XCTAssertNotNil(internalAPI.email)
        XCTAssertNil(internalAPI.authManager.getAuthToken())
        
        internalAPI.logoutUser()
        
        wait(for: [condition1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testRetryJwtFailure() throws {
        let expectation1 = expectation(description: "called track request")
        expectation1.expectedFulfillmentCount = 2
        let expectation2 = expectation(description: "pass in second attempt")
        
        let config = IterableConfig()
        let authDelegate = createStockAuthDelegate()
        config.authDelegate = authDelegate
        
        var callNumber = 0
        let networkSession = MockNetworkSession()
        networkSession.responseCallback = { url in
            if url.absoluteString.contains("track") {
                callNumber += 1
                if callNumber == 1 {
                    return MockNetworkSession.MockResponse(statusCode: 401,
                                                           data: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload].toJsonData())
                } else {
                    return MockNetworkSession.MockResponse()
                }
            } else {
                return MockNetworkSession.MockResponse()
            }
        }
        networkSession.requestCallback = { request in
            if request.url?.absoluteString.contains("track") == true {
                expectation1.fulfill()
            }
        }
        
        let api = InternalIterableAPI.initializeForTesting(
            config: config,
            networkSession: networkSession
        )
        api.userId = "some-user-id"
        api.track("some-event").onSuccess { _ in
            expectation2.fulfill()
        }.onError { error in
            XCTFail()
        }
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testRetryJwtFailureQueuesRequestsUntilNewJwtTokenIsReceived() throws {
        let t0 = Date()
        func log(_ message: String) {
            let dt = String(format: "%.3f", Date().timeIntervalSince(t0))
            print("[AuthTests][\(dt)s] \(message)")
        }
        
        // This test intentionally avoids InternalIterableAPI login, because that can initiate a token request
        // and mask the JWT-retry queueing behavior we want to validate.
        let tokenRequestStarted = expectation(description: "auth token request started")
        
        let allSucceeded = expectation(description: "all requests succeeded after retry")
        allSucceeded.expectedFulfillmentCount = 4
        
        let invalidJwtError = SendRequestError(
            reason: "Invalid Request",
            data: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload].toJsonData(),
            httpStatusCode: 401,
            iterableCode: JsonValue.Code.invalidJwtPayload
        )
        
        let localStorage = MockLocalStorage()
        localStorage.email = AuthTests.email
        
        var tokenRequestedCount = 0
        var tokenDelivered = false
        
        final class DelayedAuthDelegate: IterableAuthDelegate {
            let delay: TimeInterval
            let token: String
            let log: (String) -> Void
            let onRequested: () -> Void
            let onDelivered: () -> Void
            
            init(delay: TimeInterval,
                 token: String,
                 log: @escaping (String) -> Void,
                 onRequested: @escaping () -> Void,
                 onDelivered: @escaping () -> Void) {
                self.delay = delay
                self.token = token
                self.log = log
                self.onRequested = onRequested
                self.onDelivered = onDelivered
            }
            
            func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
                log("authDelegate.onAuthTokenRequested()")
                onRequested()
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [token, onDelivered] in
                    self.log("authDelegate delivering token")
                    onDelivered()
                    completion(token)
                }
            }
            
            func onAuthFailure(_ authFailure: AuthFailure) {}
        }
        
        let authDelegate = DelayedAuthDelegate(
            delay: 0.3,
            token: AuthTests.authToken,
            log: log,
            onRequested: {
                tokenRequestedCount += 1
                log("tokenRequestedCount=\(tokenRequestedCount)")
                tokenRequestStarted.fulfill()
            },
            onDelivered: {
                tokenDelivered = true
                log("tokenDelivered=true")
            }
        )
        
        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 1, retryInterval: 0.01, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: localStorage,
            dateProvider: MockDateProvider()
        )
        
        var totalAttempts = 0
        var attemptsByRequest: [Int: Int] = [:]
        
        func makeRequestProvider(requestId: Int) -> () -> Pending<SendRequestValue, SendRequestError> {
            return {
                totalAttempts += 1
                attemptsByRequest[requestId, default: 0] += 1
                
                let attempt = attemptsByRequest[requestId] ?? 0
                log("requestProvider id=\(requestId) attempt=\(attempt) tokenDelivered=\(tokenDelivered)")
                
                // On retry, ensure we only retry after token is delivered.
                if attempt >= 2 {
                    XCTAssertTrue(tokenDelivered, "request \(requestId) retried before JWT token delivered")
                }
                
                if attempt == 1 {
                    return Fulfill(error: invalidJwtError)
                } else {
                    return Fulfill(value: [:])
                }
            }
        }
        
        // 1) Fire the first request and wait until token request has started
        _ = RequestProcessorUtil.sendRequest(
            requestProvider: makeRequestProvider(requestId: 0),
            authManager: authManager,
            requestIdentifier: "test-request-0"
        ).onSuccess { _ in
            log("request 0 succeeded")
            allSucceeded.fulfill()
        }.onError { _ in
            XCTFail()
        }
        
        wait(for: [tokenRequestStarted], timeout: testExpectationTimeout)
        log("token request started; firing remaining requests while token is pending")
        
        // 2) While token is still pending, fire 3 more requests that should be queued behind the same token refresh.
        (1..<4).forEach { requestId in
            _ = RequestProcessorUtil.sendRequest(
                requestProvider: makeRequestProvider(requestId: requestId),
                authManager: authManager,
                requestIdentifier: "test-request-\(requestId)"
            ).onSuccess { _ in
                log("request \(requestId) succeeded")
                allSucceeded.fulfill()
            }.onError { _ in
                XCTFail()
            }
        }
        
        wait(for: [allSucceeded], timeout: testExpectationTimeout)
        
        log("final: totalAttempts=\(totalAttempts) tokenRequestedCount=\(tokenRequestedCount) tokenDelivered=\(tokenDelivered) attemptsByRequest=\(attemptsByRequest)")
        XCTAssertEqual(tokenRequestedCount, 1)
        XCTAssertEqual(totalAttempts, 8)
    }

    // MARK: - Private
    
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

    private func createStockAuthDelegate() -> IterableAuthDelegate {
        return DefaultAuthDelegate({ AuthTests.authToken })
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
    
    /// adapated from https://stackoverflow.com/questions/60290703/how-do-i-generate-a-jwt-to-use-in-api-authentication-for-swift-app
    private static func generateJwt() -> String {
        let secret = "secret"
        let privateKey = SymmetricKey(data: Data(secret.utf8))
        
        struct Header: Encodable {
            let alg = "HS256"
            let typ = "JWT"
        }
        
        struct Payload: Encodable {
            let email = AuthTests.email
            let iat = Date()
            let exp = Date(timeIntervalSinceNow: 24 * 60 * 1)
        }
        
        let headerJsonData = try! JSONEncoder().encode(Header())
        let headerBase64 = headerJsonData.urlEncodedBase64()
        
        let payloadJsonData = try! JSONEncoder().encode(Payload())
        let payloadBase64 = payloadJsonData.urlEncodedBase64()
        
        let toSign = Data((headerBase64 + "." + payloadBase64).utf8)
        
        let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
        let signatureBase64 = Data(signature).urlEncodedBase64()
        
        let token = [headerBase64, payloadBase64, signatureBase64].joined(separator: ".")
        
        return token
    }
}

extension Data {
    func urlEncodedBase64() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
