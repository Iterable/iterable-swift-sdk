//
//  AnonymousUserMergeTests.swift
//
//
//  Created by Hani Vora on 29/12/23.
//


import XCTest
import Foundation

@testable import IterableSDK

class AnonymousUserMergeTests: XCTestCase, AuthProvider {
    public var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: "asdf", userIdAnon: nil)
    }
    
    private static let apiKey = "zeeApiKey"
    
    override func setUp() {
        super.setUp()
    }
    
    func testMergeUserUsingUserId() {
        let networkSession: NetworkSessionProtocol = MockNetworkSession()
        let mockApiClient = ApiClient(apiKey: AnonymousUserMergeTests.apiKey,
                                      authProvider: self,
                                      endpoint: Endpoint.api,
                                      networkSession: networkSession,
                                      deviceMetadata: InternalIterableAPI.initializeForTesting().deviceMetadata,
                                      dateProvider: MockDateProvider())
        
        
        self.callMergeApi(sourceEmail: "", sourceUserId: "123", destinationEmail: "destination@example.com", destinationUserId: "456", apiClient: mockApiClient)
        
    }
    
    func testMergeUserUsingEmail() {
        let networkSession: NetworkSessionProtocol = MockNetworkSession()
        let mockApiClient = ApiClient(apiKey: AnonymousUserMergeTests.apiKey,
                                      authProvider: self,
                                      endpoint: Endpoint.api,
                                      networkSession: networkSession,
                                      deviceMetadata: InternalIterableAPI.initializeForTesting().deviceMetadata,
                                      dateProvider: MockDateProvider())
        
        
        self.callMergeApi(sourceEmail: "source@example.com", sourceUserId: "", destinationEmail: "destination@example.com", destinationUserId: "456", apiClient: mockApiClient)
        
    }
    
    private func callMergeApi(sourceEmail: String, sourceUserId: String, destinationEmail: String, destinationUserId: String, apiClient: ApiClient) {
        
        let expectation1 = expectation(description: #function)
        
        apiClient.mergeUser(sourceEmail: sourceEmail, sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationUserId: destinationUserId).onSuccess { _ in
            expectation1.fulfill()
        }
    }
    
}
