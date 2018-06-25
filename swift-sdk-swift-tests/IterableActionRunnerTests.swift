//
//  IterableActionRunnerTests.swift
//  swift-sdk-swift-tests
//
//  Created by Tapash Majumder on 6/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableActionRunnerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        IterableAPI.initializeAPI(apiKey:"", config: IterableAPIConfig())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUrlOpenAction() {
        let urlString = "https://example.com"
        let urlDelegate = MockUrlDelegate(returnValue: false)
        let urlOpener = MockUrlOpener()
        let actionRunner = IterableActionRunner(urlDelegate: urlDelegate, customActionDelegate: nil, urlOpener: urlOpener)
        
        let action = IterableAction.action(fromDictionary: ["type" : "openUrl", "data" : urlString])!
        actionRunner.execute(action: action)
        
        if #available(iOS 10.0, *) {
            XCTAssertEqual(urlOpener.ios10OpenedUrl?.absoluteString, urlString)
            XCTAssertNil(urlOpener.preIos10openedUrl)
        } else {
            XCTAssertEqual(urlOpener.preIos10openedUrl?.absoluteString, urlString)
            XCTAssertNil(urlOpener.ios10OpenedUrl)
        }
    }
    
    func testUrlHandlingOverride() {
        let urlString = "https://example.com"
        let urlDelegate = MockUrlDelegate(returnValue: true)
        let urlOpener = MockUrlOpener()
        let actionRunner = IterableActionRunner(urlDelegate: urlDelegate, customActionDelegate: nil, urlOpener: urlOpener)
        
        let action = IterableAction.action(fromDictionary: ["type" : "openUrl", "data" : urlString])!
        actionRunner.execute(action: action)
        
        if #available(iOS 10.0, *) {
            XCTAssertNil(urlOpener.preIos10openedUrl)
            XCTAssertNil(urlOpener.ios10OpenedUrl)
        } else {
            XCTAssertNil(urlOpener.preIos10openedUrl)
            XCTAssertNil(urlOpener.ios10OpenedUrl)
        }
    }
    
    func testCustomAction() {
        let customActionDelegate = MockCustomActionDelegate(returnValue: false)
        let action = IterableAction.action(fromDictionary: ["type" : "customActionName"])!
        let actionRunner = IterableActionRunner(urlDelegate: nil, customActionDelegate: customActionDelegate, urlOpener: MockUrlOpener())
        actionRunner.execute(action: action)
        
        XCTAssertEqual(customActionDelegate.action, action)
    }
    
}
