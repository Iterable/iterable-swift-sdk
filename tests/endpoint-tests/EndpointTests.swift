//
//  Created by Tapash Majumder on 6/29/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class EndpointTests: XCTestCase {
    func test1UpdateUser() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.updateUser(["field1": "value1"],
                       mergeNestedObjects: true,
                       onSuccess: { _ in
                           expectation1.fulfill()
        }) { _, _ in
            XCTFail()
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test2UpdateEmail() throws {
        let expectation1 = expectation(description: #function)
        let expectation2 = expectation(description: "New email is deleted")
        
        let email = "user@example.com"
        let newEmail = IterableUtil.generateUUID() + "@example.com"
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = email
        
        api.updateEmail(newEmail, onSuccess: { _ in
            expectation1.fulfill()
            IterableAPISupport.sendDeleteUserRequest(email: newEmail).onSuccess { _ in
                expectation2.fulfill()
            }
        }) { _, _ in
            XCTFail()
        }
        wait(for: [expectation1, expectation2], timeout: 15)
    }
    
    private static var apiKey: String {
        Environment.get(key: .apiKey)!
    }
}
