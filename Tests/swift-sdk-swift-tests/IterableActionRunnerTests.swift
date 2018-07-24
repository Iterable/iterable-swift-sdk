//
//  IterableActionRunnerTests.swift
//  swift-sdk-swift-tests
//
//  Created by Tapash Majumder on 6/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

import OHHTTPStubs

@testable import IterableSDK

class IterableActionRunnerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        IterableAPIImplementation.initialize(apiKey:"", config: IterableConfig())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUrlOpenAction() {
        let urlString = "https://example.com"
        let action = IterableAction.action(fromDictionary: ["type" : "openUrl", "data" : urlString])!
        
        let result = IterableActionRunner.execute(action: action, from: .push, urlDelegateHandler: {url in return false})
        if case let IterableActionRunner.Result.openUrl(url) = result {
            XCTAssertEqual(url.absoluteString, urlString)
        } else {
            XCTFail()
        }
    }
    
    func testUrlHandlingOverride() {
        let urlString = "https://example.com"
        let action = IterableAction.action(fromDictionary: ["type" : "openUrl", "data" : urlString])!
        
        let result = IterableActionRunner.execute(action: action, from: .push, urlDelegateHandler: {url in return true})
        if case let IterableActionRunner.Result.openedUrl(url) = result {
            XCTAssertEqual(url.absoluteString, urlString)
        } else {
            XCTFail()
        }
    }
    
    func testCustomAction() {
        let action = IterableAction.action(fromDictionary: ["type" : "customActionName"])!
        
        let result = IterableActionRunner.execute(action: action, from: .push, customActionDelegateHandler: {actionType in return true})
        if case let IterableActionRunner.Result.performedCustomAction(actionName) = result {
            XCTAssertEqual(actionName, "customActionName")
        } else {
            XCTFail()
        }
    }
    
}
