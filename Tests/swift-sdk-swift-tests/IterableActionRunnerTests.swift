//
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
        let context = IterableActionContext(action: action, source: .push)
        let urlOpener = MockUrlOpener()

        let handled = IterableActionRunner.execute(action: action,
                                     context: context,
                                     urlHandler: { url in return false},
                                     urlOpener: urlOpener)
        
        XCTAssertTrue(handled)
        
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
        let action = IterableAction.action(fromDictionary: ["type" : "openUrl", "data" : urlString])!
        let context = IterableActionContext(action: action, source: .push)
        let urlOpener = MockUrlOpener()

        let handled = IterableActionRunner.execute(action: action,
                                     context: context,
                                     urlHandler: { url in return true},
                                     urlOpener: urlOpener)
        
        XCTAssertTrue(handled)
        
        if #available(iOS 10.0, *) {
            XCTAssertNil(urlOpener.ios10OpenedUrl)
            XCTAssertNil(urlOpener.preIos10openedUrl)
        } else {
            XCTAssertNil(urlOpener.ios10OpenedUrl)
            XCTAssertNil(urlOpener.preIos10openedUrl)
        }
    }
    
    func testCustomAction() {
        let customActionName = "myCustomActionName"
        let action = IterableAction.action(fromDictionary: ["type" : customActionName])!
        let context = IterableActionContext(action: action, source: .push)
        let customActionHandler: CustomActionHandler = {name in
            XCTAssertEqual(name, customActionName)
            return true
        }

        let handled = IterableActionRunner.execute(action: action,
                                     context: context,
                                     customActionHandler: customActionHandler)
        
        XCTAssertTrue(handled)
    }

    func testCustomActionOverride() {
        let customActionName = "myCustomActionName"
        let action = IterableAction.action(fromDictionary: ["type" : customActionName])!
        let context = IterableActionContext(action: action, source: .push)
        let customActionHandler: CustomActionHandler = {name in
            XCTAssertEqual(name, customActionName)
            return false
        }
        
        let handled = IterableActionRunner.execute(action: action,
                                                   context: context,
                                                   customActionHandler: customActionHandler)
        
        XCTAssertFalse(handled)
    }

}
