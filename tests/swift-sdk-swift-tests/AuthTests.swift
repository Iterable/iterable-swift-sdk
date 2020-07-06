//
//  AuthTests.swift
//  swift-sdk-swift-tests
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
    
    override func setUp() {
        super.setUp()
        
        TestUtils.clearTestUserDefaults()
    }
    
    func testEmailPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        internalAPI.email = IterableAPITests.email
        XCTAssertEqual(internalAPI.email, IterableAPITests.email)
        XCTAssertNil(internalAPI.userId)
    }
    
    func testUserIdPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        internalAPI.userId = IterableAPITests.userId
        XCTAssertEqual(internalAPI.userId, IterableAPITests.userId)
        XCTAssertNil(internalAPI.email)
    }
    
    func testEmailWithTokenPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        let emailToken = "asdf"
        
        internalAPI.setEmail(IterableAPITests.email, withToken: emailToken)
        XCTAssertEqual(internalAPI.email, IterableAPITests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertEqual(internalAPI.auth.authToken, emailToken)
    }
    
    func testUserIdWithTokenPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        let userIdToken = "qwer"
        
        internalAPI.setUserId(IterableAPITests.userId, withToken: userIdToken)
        XCTAssertEqual(internalAPI.userId, IterableAPITests.userId)
        XCTAssertNil(internalAPI.email)
        XCTAssertEqual(internalAPI.auth.authToken, userIdToken)
    }
    
    func testUserLoginAndLogout() {
        
    }
    
    func testEmailWithTokenChange() {
        
    }
}
