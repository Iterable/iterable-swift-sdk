//
//
//  Created by Tapash Majumder on 6/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

import OHHTTPStubs

@testable import IterableSDK

class IterableActionInterpreterTests: XCTestCase {
    
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
        
        let result = IterableActionInterpreter.execute(action: action, from: .push, urlHandler: {url in return false})
        if case let IterableActionInterpreter.Result.openUrl(url) = result {
            XCTAssertEqual(url.absoluteString, urlString)
        } else {
            XCTFail()
        }
    }
    
    func testUrlHandlingOverride() {
        let urlString = "https://example.com"
        let action = IterableAction.action(fromDictionary: ["type" : "openUrl", "data" : urlString])!
        
        let result = IterableActionInterpreter.execute(action: action, from: .push, urlHandler: {url in return true})
        if case let IterableActionInterpreter.Result.openedUrl(url) = result {
            XCTAssertEqual(url.absoluteString, urlString)
        } else {
            XCTFail()
        }
    }
    
    func testCustomAction() {
        let action = IterableAction.action(fromDictionary: ["type" : "customActionName"])!
        
        let result = IterableActionInterpreter.execute(action: action, from: .push, customActionHandler: {actionType in return true})
        if case let IterableActionInterpreter.Result.performedCustomAction(actionName) = result {
            XCTAssertEqual(actionName, "customActionName")
        } else {
            XCTFail()
        }
    }
    
}
