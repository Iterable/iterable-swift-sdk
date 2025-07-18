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
        mockLocalStorage.anonymousUsageTrack = true
        
        let config = IterableConfig()
        config.enableAnonActivation = true
        
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
        mockLocalStorage.userIdAnnon = nil
        
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
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConsentSentOnUserIdSetForReplayScenario() {
        let expectation = XCTestExpectation(description: "Consent tracked on userId set")
        
        // Set up replay scenario (no anonymous user ID)
        mockLocalStorage.userIdAnnon = nil
        
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
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConsentNotSentWhenAnonUserExists() {
        let expectation = XCTestExpectation(description: "No consent when anon user exists")
        expectation.isInverted = true
        
        // Set up scenario with existing anonymous user (no replay needed)
        mockLocalStorage.userIdAnnon = "existing-anon-user-id"
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should not happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        internalAPI.setEmail(ConsentTrackingTests.testEmail)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testConsentNotSentWhenNoTracking() {
        let expectation = XCTestExpectation(description: "No consent when tracking disabled")
        expectation.isInverted = true
        
        // Disable anonymous usage tracking
        mockLocalStorage.anonymousUsageTrack = false
        
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.trackConsent) {
                expectation.fulfill() // This should not happen
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        internalAPI.setEmail(ConsentTrackingTests.testEmail)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testConsentNotSentWhenAnonActivationDisabled() {
        let expectation = XCTestExpectation(description: "No consent when anon activation disabled")
        expectation.isInverted = true
        
        // Create API with anon activation disabled
        let config = IterableConfig()
        config.enableAnonActivation = false
        
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
        
        internalAPI.setEmail(ConsentTrackingTests.testEmail)
        
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
        
        internalAPI.setEmail(ConsentTrackingTests.testEmail)
        
        wait(for: [expectation], timeout: 5.0)
    }
} 
