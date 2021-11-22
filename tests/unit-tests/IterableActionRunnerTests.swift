//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

let testExpectationTimeout = 15.0 // How long to wait when we expect to succeed
let testExpectationTimeoutForInverted = 1.0 // How long to wait when we expect to fail

class IterableActionRunnerTests: XCTestCase {
    func testUrlOpenAction() {
        let urlString = "https://example.com"
        let action = IterableAction.action(fromDictionary: ["type": "openUrl", "data": urlString])!
        let context = IterableActionContext(action: action, source: .push)
        let urlOpener = MockUrlOpener()
        let expectation = XCTestExpectation(description: "call UrlHandler")
        let urlHandler: UrlHandler = { url in
            XCTAssertEqual(url.absoluteString, urlString)
            expectation.fulfill()
            return false
        }
        
        let handled = IterableActionRunner.execute(action: action,
                                                   context: context,
                                                   urlHandler: urlHandler,
                                                   urlOpener: urlOpener)
        
        wait(for: [expectation], timeout: testExpectationTimeout)
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
        let action = IterableAction.action(fromDictionary: ["type": "openUrl", "data": urlString])!
        let context = IterableActionContext(action: action, source: .push)
        let urlOpener = MockUrlOpener()
        let expectation = XCTestExpectation(description: "call UrlHandler")
        let urlHandler: UrlHandler = { url in
            XCTAssertEqual(url.absoluteString, urlString)
            expectation.fulfill()
            return true
        }
        
        let handled = IterableActionRunner.execute(action: action,
                                                   context: context,
                                                   urlHandler: urlHandler,
                                                   urlOpener: urlOpener)
        
        wait(for: [expectation], timeout: testExpectationTimeout)
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
        let action = IterableAction.action(fromDictionary: ["type": customActionName])!
        let context = IterableActionContext(action: action, source: .push)
        let expection = XCTestExpectation(description: "callActionHandler")
        let customActionHandler: CustomActionHandler = { name in
            XCTAssertEqual(name, customActionName)
            expection.fulfill()
            return true
        }
        
        let handled = IterableActionRunner.execute(action: action,
                                                   context: context,
                                                   customActionHandler: customActionHandler)
        
        wait(for: [expection], timeout: testExpectationTimeout)
        XCTAssertTrue(handled)
    }
    
    func testCustomActionOverride() {
        let customActionName = "myCustomActionName"
        let action = IterableAction.action(fromDictionary: ["type": customActionName])!
        let context = IterableActionContext(action: action, source: .push)
        let expection = XCTestExpectation(description: "callActionHandler")
        let customActionHandler: CustomActionHandler = { name in
            XCTAssertEqual(name, customActionName)
            expection.fulfill()
            return false
        }
        
        let handled = IterableActionRunner.execute(action: action,
                                                   context: context,
                                                   customActionHandler: customActionHandler)
        
        wait(for: [expection], timeout: testExpectationTimeout)
        XCTAssertFalse(handled)
    }
    
    func testBadDataInIterableAction() {
        let action = IterableAction.action(fromDictionary: ["type": 1])
        
        XCTAssertNil(action)
    }
    
    func testOpenHttpsByDefault() {
        let urlString = "https://example.com"
        let action = IterableAction.action(fromDictionary: ["type": "openUrl", "data": urlString])!
        let context = IterableActionContext(action: action, source: .push)
        let expectation1 = XCTestExpectation(description: #function)
        
        let urlOpener = MockUrlOpener() { url in
            XCTAssertEqual(url.absoluteString, urlString)
            expectation1.fulfill()
        }

        let handled = IterableActionRunner.execute(action: action,
                                                   context: context,
                                                   urlHandler: nil,
                                                   urlOpener: urlOpener)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertTrue(handled)
    }

    func testDoNotOpenHttpByDefault() {
        let urlString = "http://example.com"
        let action = IterableAction.action(fromDictionary: ["type": "openUrl", "data": urlString])!
        let context = IterableActionContext(action: action, source: .push)
        let expectation1 = XCTestExpectation(description: #function)
        expectation1.isInverted = true
        
        let urlOpener = MockUrlOpener() { url in
            XCTAssertEqual(url.absoluteString, urlString)
            expectation1.fulfill()
        }

        IterableActionRunner.execute(action: action,
                                     context: context,
                                     urlHandler: nil,
                                     urlOpener: urlOpener)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }

    func testAllowHttpWhenAllowedProtocolsIsSet() {
        let urlString = "http://example.com"
        let action = IterableAction.action(fromDictionary: ["type": "openUrl", "data": urlString])!
        let context = IterableActionContext(action: action, source: .push)
        let expectation1 = XCTestExpectation(description: #function)
        
        let urlOpener = MockUrlOpener() { url in
            XCTAssertEqual(url.absoluteString, urlString)
            expectation1.fulfill()
        }

        IterableActionRunner.execute(action: action,
                                     context: context,
                                     urlHandler: nil,
                                     urlOpener: urlOpener,
                                     allowedProtocols: ["http"])
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}
