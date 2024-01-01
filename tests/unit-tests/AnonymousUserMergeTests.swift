//
//  File.swift
//  
//
//  Created by Hani Vora on 29/12/23.
//


import XCTest
import Foundation

@testable import IterableSDK

class AnonymousUserMergeTests: XCTestCase {
    
    private static let apiKey = "zeeApiKey"
    
    override func setUp() {
        super.setUp()
    }
    
    func testUserMergeByUserId() {
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey:AnonymousUserMergeTests.apiKey)
        let items = [CommerceItem(id: "id1", name: "Mocha", price: 4.67, quantity: 2)]
        internalAPI.trackPurchase(10.0, items: items)
        internalAPI.setUserId("testUserId")
    }
    
    func testUserMergeByEmail() {
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey:AnonymousUserMergeTests.apiKey)
        let items = [CommerceItem(id: "id1", name: "Mocha", price: 4.67, quantity: 2)]
        internalAPI.trackPurchase(10.0, items: items)
        IterableAPI.setEmail("user@example.com")
    }
    
    
    // Mock Dependency Container
//    class MockDependencyContainer: DependencyContainerProtocol {
//        func createAnonymousUserManager() -> AnonymousUserManagerProtocol {
//            // Implement your mock or use a testing library for mocking
//            return MockAnonymousUserManager()
//        }
//    }
//    
//    // Mock ApiClient
//    class MockApiClient: ApiClient {
//        // Implement mock methods as needed for testing
//        override func getUserByUserID(userId: String) -> Result<YourResponseType, Error> {
//            // Return mock data or handle as needed
//            return .success(MockData.userResponse)
//        }
//        
//        // Implement other mock methods
//    }
//    
//    // Mock Data
//    struct MockData {
//        static let userResponse: [String: Any] = ["user": ["userId": "123", "email": "test@example.com"]]
//    }
//    
//    // Mock AnonymousUserManager
//    class MockAnonymousUserManager: AnonymousUserManagerProtocol {
//        // Implement mock methods as needed for testing
//    }
//    
//    // Test Cases
//    func testMergeUserUsingUserId() {
//        // Arrange
//        let mockDependencyContainer = MockDependencyContainer()
//        let mockApiClient = MockApiClient()
//        let anonymousUserMerge = AnonymousUserMerge(dependencyContainer: mockDependencyContainer, apiClient: mockApiClient)
//        
//        // Act
//        anonymousUserMerge.mergeUserUsingUserId(destinationUserId: "456", sourceUserId: "123", destinationEmail: "destination@example.com")
//        
//        // Assert or add additional validation as needed
//        // For example, you can assert that certain methods on the mock objects were called.
//    }
//    
//    func testMergeUserUsingEmail() {
//        // Arrange
//        let mockDependencyContainer = MockDependencyContainer()
//        let mockApiClient = MockApiClient()
//        let anonymousUserMerge = AnonymousUserMerge(dependencyContainer: mockDependencyContainer, apiClient: mockApiClient)
//        
//        // Act
//        anonymousUserMerge.mergeUserUsingEmail(destinationUserId: "456", destinationEmail: "destination@example.com", sourceEmail: "source@example.com")
//        
//        // Assert or add additional validation as needed
//    }
    
}
