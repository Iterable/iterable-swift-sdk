//
//  AnonymousUserManagerTests.swift
//  swift-sdk
//
//  Created by HARDIK MASHRU on 26/03/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class AnonymousUserManagerTests: XCTestCase, AuthProvider {
    
    public var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: "asdf")
    }
    
    override class func setUp() {
        super.setUp()
    }
    
    func testCreateKnownUserIfCriteriaMatched() {
        let apiKey = "test-api-key"
        let localStorage = MockLocalStorage()
        let expectation1 = XCTestExpectation(description: "new api endpoint called")
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey)
        let networkSession: NetworkSessionProtocol = MockNetworkSession()
        let mockApiClient = ApiClient(apiKey: apiKey,
                                      authProvider: self,
                                      endpoint: Endpoint.api,
                                      networkSession: networkSession,
                                      deviceMetadata: InternalIterableAPI.initializeForTesting().deviceMetadata,
                                      dateProvider: MockDateProvider())
        
        let mockAnonymousUserManager = MockAnonymousUserManager(localStorage: localStorage, dateProvider: internalAPI.dependencyContainer.dateProvider, notificationStateProvider: internalAPI.dependencyContainer.notificationStateProvider, apiClient: mockApiClient)
        mockAnonymousUserManager.updateAnonSession()
        let items = [CommerceItem(id: "id1", name: "myCommerceItem", price: 5.9, quantity: 2)]
        mockAnonymousUserManager.trackAnonPurchaseEvent(total: 10, items: items, dataFields: nil)
        expectation1.fulfill()
    }
}
