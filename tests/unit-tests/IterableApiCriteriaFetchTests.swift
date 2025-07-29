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
        
        // Reset the singleton to avoid test interference
        IterableAPI.implementation = nil
        
        super.tearDown()
    }
    
    func testForegroundCriteriaFetchWhenConditionsMet() {
        let expectation1 = expectation(description: "First criteria fetch")
        let expectation2 = expectation(description: "Second criteria fetch")
        
        var fetchCount = 0
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.getCriteria) {
                fetchCount += 1
                if fetchCount == 1 {
                    expectation1.fulfill()
                } else if fetchCount == 2 {
                    expectation2.fulfill()
                }
                return MockNetworkSession.MockResponse(statusCode: 200)
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.enableForegroundCriteriaFetch = true
        
        IterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: localStorage,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        // Get the internal instance from the singleton for direct access
        internalApi = IterableAPI.implementation!
        
        internalApi.setVisitorUsageTracked(isVisitorUsageTracked: true)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        
        // Reset the last criteria fetch time to bypass cooldown
        internalApi.unknownUserManager.updateLastCriteriaFetch(currentTime: 0)
        // Simulate app coming to foreground
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
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
        
        IterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: localStorage,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        internalApi = IterableAPI.implementation!
        internalApi.setVisitorUsageTracked(isVisitorUsageTracked: true)
        
        // Simulate app coming to foreground
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testForegroundCriteriaFetchWithCooldown() {
        let expectation1 = expectation(description: "First criteria fetch on foreground")
        let expectation2 = expectation(description: "Second criteria fetch on foreground")
        let expectation3 = expectation(description: "No third fetch during cooldown")
        expectation3.isInverted = true
        
        var fetchCount = 0
        mockNetworkSession.responseCallback = { url in
            if url.absoluteString.contains(Const.Path.getCriteria) {
                fetchCount += 1
                switch fetchCount {
                case 1: expectation1.fulfill()
                case 2: expectation2.fulfill()
                case 3: expectation3.fulfill()
                default: break
                }
                return MockNetworkSession.MockResponse(statusCode: 200)
            }
            return MockNetworkSession.MockResponse(statusCode: 200)
        }
        
        let config = IterableConfig()
        config.enableUnknownUserActivation = true
        config.enableForegroundCriteriaFetch = true
        
        IterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            networkSession: mockNetworkSession,
            localStorage: localStorage,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        internalApi = IterableAPI.implementation!
        
        // Prevent fetch on setVisitorUsageTracked by setting last fetch time to now
        internalApi.unknownUserManager.updateLastCriteriaFetch(currentTime: mockDateProvider.currentDate.timeIntervalSince1970 * 1000)
        internalApi.setVisitorUsageTracked(isVisitorUsageTracked: true)

        // Reset the last criteria fetch time to bypass cooldown for the first real foreground fetch
        internalApi.unknownUserManager.updateLastCriteriaFetch(currentTime: 0)
        
        // First foreground
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        
        // Second foreground after some time
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(130) // After cooldown
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
        
        // Third foreground during cooldown
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(10) // Within cooldown
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation3], timeout: 2.0)
    }
}
