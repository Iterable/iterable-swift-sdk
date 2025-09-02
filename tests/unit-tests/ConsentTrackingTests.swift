//
//  ConsentTrackingTests.swift
//  swift-sdk
//
//  Created by Iterable Team on 23/01/2025.
//  Copyright © 2025 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class ConsentTrackingTests: XCTestCase {
    private var mockNetworkSession: MockNetworkSession!
    private var mockDateProvider: MockDateProvider!
    private var mockLocalStorage: MockLocalStorage!
    private var internalAPI: InternalIterableAPI!
    private static let apiKey = "test-api-key"
    private static let testEmail = "test@example.com"
    private static let testUserId = "test-user-123"
    private static let consentTimestamp: Int64 = 1639490139
    
    override func setUp() {
        super.setUp()
        mockNetworkSession = MockNetworkSession()
        mockDateProvider = MockDateProvider()
        mockLocalStorage = MockLocalStorage()
        
        // Set up consent timestamp
        mockLocalStorage.visitorConsentTimestamp = ConsentTrackingTests.consentTimestamp
        mockLocalStorage.visitorUsageTracked = true
        
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        // Needed so register(token:) can succeed in tests
        config.pushIntegrationName = "test-push-integration"
        
        internalAPI = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
    }
    
    override func tearDown() {
        mockNetworkSession = nil
        mockDateProvider = nil
        mockLocalStorage = nil
        internalAPI = nil
        super.tearDown()
    }
    
    // MARK: - Criteria Match Scenario Tests
    
    func testConsentSentAfterCriteriaMatch() {
        let expectation = XCTestExpectation(description: "Consent tracked after criteria match")
        
        var consentRequestReceived = false
        
        mockNetworkSession.responseCallback = { url in
            let urlString = url.absoluteString
            
            if urlString.contains(Const.Path.trackConsent) {
                consentRequestReceived = true
                expectation.fulfill()
                return MockNetworkSession.MockResponse(statusCode: 200)
            }
            
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        // Verify consent request body using requestCallback
        mockNetworkSession.requestCallback = { urlRequest in
            if urlRequest.url?.absoluteString.contains(Const.Path.trackConsent) == true {
                let body = urlRequest.httpBody?.json() as? [String: Any]
                XCTAssertEqual(body?[JsonKey.consentTimestamp] as? Int, Int(ConsentTrackingTests.consentTimestamp))
                XCTAssertEqual(body?[JsonKey.isUserKnown] as? Bool, false)
                XCTAssertNotNil(body?[JsonKey.userId] as? String)
                XCTAssertNil(body?[JsonKey.email])
            }
        }
        
        // Directly test the consent sending logic by calling the API method
        // This simulates what happens when criteria are met and anonymous user is created
        let testUserId = "test-anon-user-id"
        
        internalAPI.apiClient.trackConsent(
            consentTimestamp: ConsentTrackingTests.consentTimestamp,
            email: nil,
            userId: testUserId,
            isUserKnown: false
        )
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(consentRequestReceived)
    }
    
    func testConsentTimestampSentInMilliseconds() {
        // Use a test date in seconds
        let testDateInSeconds = Date(timeIntervalSince1970: 1639490139) // December 14, 2021
        mockDateProvider.currentDate = testDateInSeconds
        
        // Set consent which should store timestamp in milliseconds
        internalAPI.setVisitorUsageTracked(isVisitorUsageTracked: true)
        
        // Verify the timestamp was stored in milliseconds format
        guard let storedTimestamp = mockLocalStorage.visitorConsentTimestamp else {
            XCTFail("Expected visitorConsentTimestamp to be set after calling setVisitorUsageTracked(true)")
            return
        }
        
        let expectedTimestampInSeconds = Int64(testDateInSeconds.timeIntervalSince1970)
        let expectedTimestampInMilliseconds = expectedTimestampInSeconds * 1000
        
        // Verify the stored timestamp is in milliseconds (much larger than seconds)
        XCTAssertEqual(storedTimestamp, expectedTimestampInMilliseconds, "Stored timestamp should be in milliseconds")
        XCTAssertTrue(storedTimestamp > expectedTimestampInSeconds, "Timestamp should be in milliseconds, not seconds")
        
        // Verify it converts back to the correct date when divided by 1000
        let convertedDate = Date(timeIntervalSince1970: TimeInterval(storedTimestamp) / 1000.0)
        XCTAssertEqual(convertedDate, testDateInSeconds, "Timestamp should convert back to original date when divided by 1000")
        
        // Verify the timestamp format: should be 13 digits (milliseconds since epoch)
        let timestampString = String(storedTimestamp)
        XCTAssertEqual(timestampString.count, 13, "Millisecond timestamp should have 13 digits")
        
        // Test that API call can be made with the millisecond timestamp (this verifies integration)
        let expectation = XCTestExpectation(description: "API call completed")
        _ = internalAPI.apiClient.trackConsent(
            consentTimestamp: storedTimestamp,
            email: nil,
            userId: "test-user",
            isUserKnown: false
        ).onSuccess { _ in
            expectation.fulfill()
        }.onError { _ in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConsentNotSentWhenNoConsentTimestamp() {
        let expectation = XCTestExpectation(description: "No consent request when no timestamp")
        expectation.isInverted = true
        
        // Clear consent timestamp
        mockLocalStorage.visitorConsentTimestamp = nil
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should not happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        // Simulate criteria being met
        mockLocalStorage.criteriaData = "mock-criteria".data(using: .utf8)
        internalAPI.track("test-event")
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Replay Scenario Tests
    
    func testConsentSentOnEmailSetForReplayScenario() {
        let expectation = XCTestExpectation(description: "Consent tracked on email set")
        
        // Set up replay scenario (no anonymous user ID)
        mockLocalStorage.userIdUnknownUser = nil
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill()
                return MockNetworkSession.MockResponse(statusCode: 200)
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        mockNetworkSession.requestCallback = { urlRequest in
            if urlRequest.url?.absoluteString.contains(Const.Path.trackConsent) == true {
                let body = urlRequest.httpBody?.json() as? [String: Any]
                XCTAssertEqual(body?[JsonKey.consentTimestamp] as? Int, Int(ConsentTrackingTests.consentTimestamp))
                XCTAssertEqual(body?[JsonKey.isUserKnown] as? Bool, true)
                XCTAssertEqual(body?[JsonKey.email] as? String, ConsentTrackingTests.testEmail)
                XCTAssertNil(body?[JsonKey.userId])
            }
        }
        
        internalAPI.setEmail(ConsentTrackingTests.testEmail)
        // Consent is sent after successful device registration
        internalAPI.register(token: "test-token")
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConsentSentOnUserIdSetForReplayScenario() {
        let expectation = XCTestExpectation(description: "Consent tracked on userId set")
        
        // Set up replay scenario (no anonymous user ID)
        mockLocalStorage.userIdUnknownUser = nil
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill()
                return MockNetworkSession.MockResponse(statusCode: 200)
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        mockNetworkSession.requestCallback = { urlRequest in
            if urlRequest.url?.absoluteString.contains(Const.Path.trackConsent) == true {
                let body = urlRequest.httpBody?.json() as? [String: Any]
                XCTAssertEqual(body?[JsonKey.consentTimestamp] as? Int, Int(ConsentTrackingTests.consentTimestamp))
                XCTAssertEqual(body?[JsonKey.isUserKnown] as? Bool, true)
                XCTAssertEqual(body?[JsonKey.userId] as? String, ConsentTrackingTests.testUserId)
                XCTAssertNil(body?[JsonKey.email])
            }
        }
        
        internalAPI.setUserId(ConsentTrackingTests.testUserId)
        // Consent is sent after successful device registration
        internalAPI.register(token: "test-token")
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConsentNotSentWhenAnonUserExists() {
        let expectation = XCTestExpectation(description: "No consent when anon user exists")
        expectation.isInverted = true
        
        // Set up scenario with existing anonymous user (no replay needed)
        mockLocalStorage.userIdUnknownUser = "existing-anon-user-id"
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should not happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        internalAPI.setEmail(ConsentTrackingTests.testEmail)
        // Consent is sent after successful device registration
        internalAPI.register(token: "test-token")
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testConsentNotSentWhenNoTracking() {
        let expectation = XCTestExpectation(description: "No consent when tracking disabled")
        expectation.isInverted = true
        
        // Disable anonymous usage tracking
        mockLocalStorage.visitorUsageTracked = false
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should not happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        internalAPI.setEmail(ConsentTrackingTests.testEmail)
        // Consent is sent after successful device registration
        internalAPI.register(token: "test-token")
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Event Replay Configuration Tests
    
    func testSendPendingConsentWhenReplayEnabled() {
        let expectation = XCTestExpectation(description: "Consent sent when replay enabled")
        
        // Set up scenario where replay is explicitly enabled
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.pushIntegrationName = "test-push-integration"
        config.identityResolution.replayOnVisitorToKnown = true
        
        let testAPI = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
        
        // Set up pending consent scenario
        mockLocalStorage.visitorUsageTracked = true
        mockLocalStorage.visitorConsentTimestamp = ConsentTrackingTests.consentTimestamp
        mockLocalStorage.userIdUnknownUser = nil // No existing anonymous user
        
        var consentRequestReceived = false
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                consentRequestReceived = true
                expectation.fulfill()
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        testAPI.setEmail(ConsentTrackingTests.testEmail)
        // This should trigger sendPendingConsent in the registration success callback
        testAPI.register(token: "test-token")
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(consentRequestReceived, "Expected consent request when replay is enabled")
    }
    
    func testSendPendingConsentSkippedWhenReplayDisabled() {
        let expectation = XCTestExpectation(description: "Consent not sent when replay disabled")
        expectation.isInverted = true
        
        // Set up scenario where replay is explicitly disabled
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.pushIntegrationName = "test-push-integration"
        config.identityResolution.replayOnVisitorToKnown = false
        
        let testAPI = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
        
        // Set up pending consent scenario
        mockLocalStorage.visitorUsageTracked = true
        mockLocalStorage.visitorConsentTimestamp = ConsentTrackingTests.consentTimestamp
        mockLocalStorage.userIdUnknownUser = nil // No existing anonymous user
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should NOT happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        testAPI.setEmail(ConsentTrackingTests.testEmail)
        // This should NOT trigger sendPendingConsent due to replay being disabled
        testAPI.register(token: "test-token")
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSendPendingConsentSkippedInLoginFlowWhenReplayDisabled() {
        let expectation = XCTestExpectation(description: "Consent not sent in login flow when replay disabled")
        expectation.isInverted = true
        
        // Set up scenario with auto push registration disabled and replay disabled
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.pushIntegrationName = "test-push-integration"
        config.autoPushRegistration = false // This triggers the alternative code path
        config.identityResolution.replayOnVisitorToKnown = false
        
        let testAPI = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
        
        // Set up pending consent scenario
        mockLocalStorage.visitorUsageTracked = true
        mockLocalStorage.visitorConsentTimestamp = ConsentTrackingTests.consentTimestamp
        mockLocalStorage.userIdUnknownUser = nil // No existing anonymous user
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should NOT happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        // This should NOT trigger sendPendingConsent due to replay being disabled
        testAPI.setEmail(ConsentTrackingTests.testEmail)
        
        wait(for: [expectation], timeout: 2.0)
    }

    func testConsentNotSentWhenAnonActivationDisabled() {
        let expectation = XCTestExpectation(description: "No consent when anon activation disabled")
        expectation.isInverted = true
        
        // Create API with anon activation disabled
        let config = IterableConfig()
        config.enableUnknownUserActivation = false
        
        let apiWithoutAnonActivation = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should not happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        apiWithoutAnonActivation.setEmail(ConsentTrackingTests.testEmail)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testConsentTrackingErrorHandling() {
        let expectation = XCTestExpectation(description: "Error handling for consent tracking")
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill()
                // Simulate network error
                return MockNetworkSession.MockResponse(statusCode: 500, error: NSError(domain: "TestError", code: 500, userInfo: nil))
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        // Directly invoke consent tracking to verify error handling
        internalAPI.apiClient.trackConsent(
            consentTimestamp: ConsentTrackingTests.consentTimestamp,
            email: ConsentTrackingTests.testEmail,
            userId: nil,
            isUserKnown: true
        )
        
        wait(for: [expectation], timeout: 5.0)
        // Test should not crash on error - error is logged internally
    }
    
    // MARK: - Device Info Tests
    
    func testConsentRequestIncludesDeviceInfo() {
        let expectation = XCTestExpectation(description: "Device info included in consent request")
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill()
                return MockNetworkSession.MockResponse(statusCode: 200)
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        mockNetworkSession.requestCallback = { urlRequest in
            if urlRequest.url?.absoluteString.contains(Const.Path.trackConsent) == true {
                let body = urlRequest.httpBody?.json() as? [String: Any]
                let deviceInfo = body?[JsonKey.deviceInfo] as? [String: Any]
                
                XCTAssertNotNil(deviceInfo)
                XCTAssertNotNil(deviceInfo?[JsonKey.deviceId])
                XCTAssertEqual(deviceInfo?[JsonKey.platform] as? String, JsonValue.iOS)
                XCTAssertNotNil(deviceInfo?[JsonKey.appPackageName])
            }
        }
        
        // Invoke via API client to validate device info payload
        internalAPI.apiClient.trackConsent(
            consentTimestamp: ConsentTrackingTests.consentTimestamp,
            email: ConsentTrackingTests.testEmail,
            userId: nil,
            isUserKnown: true
        )
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Retry Mechanism Tests
    
    func testConsentRetryOnFailure() {
        let retryExpectation = XCTestExpectation(description: "Consent retry after initial failure")
        var requestCount = 0
        var firstCallFailed = false
        var secondCallSucceeded = false
        
        // Set up retry scenario (no anonymous user ID for replay)
        mockLocalStorage.userIdUnknownUser = nil
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                requestCount += 1
                if requestCount == 1 {
                    firstCallFailed = true
                    // First attempt fails with 500 error
                    return MockNetworkSession.MockResponse(statusCode: 500, error: NSError(domain: "TestError", code: 500, userInfo: nil))
                } else if requestCount == 2 {
                    secondCallSucceeded = true
                    retryExpectation.fulfill()
                    // Second attempt succeeds
                    return MockNetworkSession.MockResponse(statusCode: 200)
                }
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        // Set up config for test
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.pushIntegrationName = "test-push-integration"
        
        let testAPI = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
        
        testAPI.setEmail(ConsentTrackingTests.testEmail)
        // Consent is sent after successful device registration
        testAPI.register(token: "test-token")
        
        wait(for: [retryExpectation], timeout: 10.0)
        
        XCTAssertTrue(firstCallFailed, "First consent call should have failed")
        XCTAssertTrue(secondCallSucceeded, "Second consent call should have succeeded")
        XCTAssertEqual(requestCount, 2, "Should have made exactly 2 requests")
    }
    
    func testConsentNoRetryOnSuccess() {
        let successExpectation = XCTestExpectation(description: "Success on first attempt")
        var requestCount = 0
        
        // Set up replay scenario (no anonymous user ID for replay)
        mockLocalStorage.userIdUnknownUser = nil
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                requestCount += 1
                successExpectation.fulfill()
                // First attempt succeeds
                return MockNetworkSession.MockResponse(statusCode: 200)
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        // Set up config for test
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.pushIntegrationName = "test-push-integration"
        
        let testAPI = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
        
        testAPI.setEmail(ConsentTrackingTests.testEmail)
        // Consent is sent after successful device registration
        testAPI.register(token: "test-token")
        
        wait(for: [successExpectation], timeout: 5.0)
        
        XCTAssertEqual(requestCount, 1, "Should have made exactly 1 request when first attempt succeeds")
    }
    
    func testConsentRetryFailsAfterTwoAttempts() {
        let finalFailureExpectation = XCTestExpectation(description: "Both attempts fail")
        var requestCount = 0
        
        // Set up retry scenario (no anonymous user ID for replay)
        mockLocalStorage.userIdUnknownUser = nil
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                requestCount += 1
                if requestCount == 2 {
                    // Complete expectation after second failure
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        finalFailureExpectation.fulfill()
                    }
                }
                // Both attempts fail with 500 error
                return MockNetworkSession.MockResponse(statusCode: 500, error: NSError(domain: "TestError", code: 500, userInfo: nil))
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        // Set up config for test
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.pushIntegrationName = "test-push-integration"
        
        let testAPI = InternalIterableAPI.initializeForTesting(
            apiKey: ConsentTrackingTests.apiKey,
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: mockLocalStorage
        )
        
        testAPI.setEmail(ConsentTrackingTests.testEmail)
        // Consent is sent after successful device registration
        testAPI.register(token: "test-token")
        
        wait(for: [finalFailureExpectation], timeout: 10.0)
        
        XCTAssertEqual(requestCount, 2, "Should have made exactly 2 requests before giving up")
    }
} 
