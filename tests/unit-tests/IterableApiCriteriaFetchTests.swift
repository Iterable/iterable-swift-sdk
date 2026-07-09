//
//  IterableApiCriteriaFetchTests.swift
//  swift-sdk
//
//  Created by Joao Dordio on 30/01/2025.
//  Copyright © 2025 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableApiCriteriaFetchTests: XCTestCase {
    private var mockNetworkSession: MockNetworkSession!
    private var mockDateProvider: MockDateProvider!
    private var mockNotificationCenter: MockNotificationCenter!
    private var internalApi: InternalIterableAPI!
    private var mockApplicationStateProvider: MockApplicationStateProvider!
    private static let apiKey = "zeeApiKey"
    let localStorage = MockLocalStorage()
    
    override func setUp() {
        super.setUp()
        mockNetworkSession = MockNetworkSession()
        mockDateProvider = MockDateProvider()
        mockNotificationCenter = MockNotificationCenter()
        mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .active)
    }
    
    override func tearDown() {
        mockNetworkSession = nil
        mockDateProvider = nil
        mockNotificationCenter = nil
        internalApi = nil
        mockApplicationStateProvider = nil
        super.tearDown()
    }
    
    func testForegroundCriteriaFetchWhenConditionsMet() {
        let expectation1 = expectation(description: "First criteria fetch")
        expectation1.expectedFulfillmentCount = 2
        
        mockNetworkSession.responseCallback = { urlRequest in
            if urlRequest.absoluteString.contains(Const.Path.getCriteria) == true {
                expectation1.fulfill()
            }
            return nil
        }
        
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.enableForegroundCriteriaFetch = true
        
        // Set up localStorage to have visitor usage tracking enabled for the first criteria fetch during initialization
        localStorage.visitorUsageTracked = true
        
        IterableAPI.initializeForTesting(apiKey: IterableApiCriteriaFetchTests.apiKey,
                                         config: config,
                                         networkSession: mockNetworkSession,
                                         localStorage: localStorage)
        
        // Manually trigger the criteria fetch logic that happens in initialize2() but not in initializeForTesting()
        if let implementation = IterableAPI.implementation, config.enableUnknownUserActivation, !implementation.isSDKInitialized(), implementation.getVisitorUsageTracked() {
            implementation.unknownUserManager.getUnknownCriteria()
            implementation.unknownUserManager.updateUnknownSession()
        }
        
        internalApi = InternalIterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: localStorage,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        internalApi.setVisitorUsageTracked(isVisitorUsageTracked: true)
        sleep(5)
        // Simulate app coming to foreground
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testCriteriaFetchNotCalledWhenDisabled() {
        let expectation1 = expectation(description: "No criteria fetch")
        expectation1.isInverted = true
        
        mockNetworkSession.responseCallback = { urlRequest in
            if urlRequest.absoluteString.contains(Const.Path.getCriteria) == true {
                expectation1.fulfill()
            }
            return nil
        }
        
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.enableForegroundCriteriaFetch = false
        
        internalApi = InternalIterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: localStorage,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        internalApi.setVisitorUsageTracked(isVisitorUsageTracked: true)
        
        // Simulate app coming to foreground
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testCriteriaFetchSuccessInvokesUnknownUserHandlerAfterPersistingCriteria() {
        let expectation1 = expectation(description: "Criteria received")
        let localStorage = MockLocalStorage()
        let criteriaPayload: [AnyHashable: Any] = [
            JsonKey.criteriaSets: [
                [JsonKey.CriteriaItem.criteriaId: "123"]
            ]
        ]
        let handler = MockUnknownUserHandler()
        handler.onCriteriaReceivedCallback = { criteria in
            let storedCriteria = localStorage.criteriaData?.json()
            let storedCriteriaSets = storedCriteria?[JsonKey.criteriaSets] as? [[String: Any]]
            let receivedCriteriaSets = criteria[JsonKey.criteriaSets] as? [[String: Any]]

            XCTAssertEqual(storedCriteriaSets?.first?[JsonKey.CriteriaItem.criteriaId] as? String, "123")
            XCTAssertEqual(receivedCriteriaSets?.first?[JsonKey.CriteriaItem.criteriaId] as? String, "123")
            expectation1.fulfill()
        }
        handler.onCriteriaFetchFailedCallback = { reason in
            XCTFail("Unexpected criteria fetch failure: \(reason)")
        }

        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.getCriteria) == true {
                return MockNetworkSession.MockResponse(statusCode: 200, data: criteriaPayload.toJsonData())
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }

        let config = IterableConfig()
        config.unknownUserHandler = handler

        IterableAPI.initializeForTesting(apiKey: IterableApiCriteriaFetchTests.apiKey,
                                         config: config,
                                         networkSession: mockNetworkSession,
                                         localStorage: localStorage)
        defer { IterableAPI.implementation = nil }

        IterableAPI.implementation?.unknownUserManager.getUnknownCriteria()

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testCriteriaFetchFailureInvokesUnknownUserHandler() {
        let expectation1 = expectation(description: "Criteria fetch failed")
        let localStorage = MockLocalStorage()
        let failureReason = "criteria fetch failed"
        let handler = MockUnknownUserHandler()
        handler.onCriteriaReceivedCallback = { _ in
            XCTFail("Unexpected criteria received callback")
        }
        handler.onCriteriaFetchFailedCallback = { reason in
            XCTAssertEqual(reason, failureReason)
            XCTAssertNil(localStorage.criteriaData)
            expectation1.fulfill()
        }

        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.getCriteria) == true {
                return MockNetworkSession.MockResponse(statusCode: 500,
                                                       data: ["msg": failureReason].toJsonData())
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }

        let config = IterableConfig()
        config.unknownUserHandler = handler

        IterableAPI.initializeForTesting(apiKey: IterableApiCriteriaFetchTests.apiKey,
                                         config: config,
                                         networkSession: mockNetworkSession,
                                         localStorage: localStorage)
        defer { IterableAPI.implementation = nil }

        IterableAPI.implementation?.unknownUserManager.getUnknownCriteria()

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testCriteriaFetchSuccessInvokesUnknownUserHandlerOnEveryFetch() {
        let expectation1 = expectation(description: "Criteria received twice")
        expectation1.expectedFulfillmentCount = 2
        let localStorage = MockLocalStorage()
        let criteriaPayload: [AnyHashable: Any] = [
            JsonKey.criteriaSets: [
                [JsonKey.CriteriaItem.criteriaId: "123"]
            ]
        ]
        let handler = MockUnknownUserHandler()
        var receivedCount = 0
        handler.onCriteriaReceivedCallback = { _ in
            receivedCount += 1
            XCTAssertTrue(Thread.isMainThread)
            expectation1.fulfill()
        }

        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.getCriteria) == true {
                return MockNetworkSession.MockResponse(statusCode: 200, data: criteriaPayload.toJsonData())
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }

        let config = IterableConfig()
        config.unknownUserHandler = handler

        IterableAPI.initializeForTesting(apiKey: IterableApiCriteriaFetchTests.apiKey,
                                         config: config,
                                         networkSession: mockNetworkSession,
                                         localStorage: localStorage)
        defer { IterableAPI.implementation = nil }

        IterableAPI.implementation?.unknownUserManager.getUnknownCriteria()
        IterableAPI.implementation?.unknownUserManager.getUnknownCriteria()

        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(receivedCount, 2)
    }
    
    func testForegroundCriteriaFetchWithCooldown() {
        let expectation1 = expectation(description: "First criteria fetch")
        let expectation2 = expectation(description: "Second criteria fetch")
        let expectation3 = expectation(description: "No third fetch during cooldown")
        expectation3.isInverted = true
        
        var fetchCount = 0
        mockNetworkSession.responseCallback = { urlRequest in
            if urlRequest.absoluteString.contains(Const.Path.getCriteria) == true {
                fetchCount += 1
                switch fetchCount {
                case 1: expectation1.fulfill()
                case 2: expectation2.fulfill()
                case 3: expectation3.fulfill()
                default: break
                }
            }
            return nil
        }
        
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.enableForegroundCriteriaFetch = true
        
        // Set up localStorage to have visitor usage tracking enabled for the first criteria fetch during initialization
        localStorage.visitorUsageTracked = true
        
        IterableAPI.initializeForTesting(apiKey: IterableApiCriteriaFetchTests.apiKey,
                                         config: config,
                                         networkSession: mockNetworkSession,
                                         localStorage: localStorage)

        // Manually trigger the criteria fetch logic that happens in initialize2() but not in initializeForTesting()
        if let implementation = IterableAPI.implementation, config.enableUnknownUserActivation, !implementation
            .isSDKInitialized(), implementation
            .getVisitorUsageTracked() {
            implementation.unknownUserManager.getUnknownCriteria()
            implementation.unknownUserManager.updateUnknownSession()
        }

        internalApi = InternalIterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: localStorage,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        internalApi.setVisitorUsageTracked(isVisitorUsageTracked: true)
        
        sleep(5)
        
        // First foreground
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        // Second foreground after some time
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(130) // After cooldown
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        // Third foreground during cooldown
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(10) // Within cooldown
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
}

private final class MockUnknownUserHandler: NSObject, IterableUnknownUserHandler {
    var onCriteriaReceivedCallback: (([AnyHashable: Any]) -> Void)?
    var onCriteriaFetchFailedCallback: ((String) -> Void)?

    func onUnknownUserCreated(userId: String) {}

    func onCriteriaReceived(criteria: [AnyHashable: Any]) {
        onCriteriaReceivedCallback?(criteria)
    }

    func onCriteriaFetchFailed(reason: String) {
        onCriteriaFetchFailedCallback?(reason)
    }
}
