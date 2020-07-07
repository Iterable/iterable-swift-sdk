//
//  Created by Tapash Majumder on 9/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class DeferredDeepLinkTests: XCTestCase {
    private static let apiKey = "zeeApiKey"
    
    override func setUp() {
        super.setUp()
        
        TestUtils.clearTestUserDefaults()
    }
    
    func testCallCheckForDDL() {
        let expectation = XCTestExpectation(description: "callCheckForDDL")
        
        let json: [AnyHashable: Any] = [
            "isMatch": true,
            "destinationUrl": "zeeDestinationUrl",
            "campaignId": "1",
            "templateId": "1",
            "messageId": "1",
        ]
        
        let networkSession = MockNetworkSession(statusCode: 200, json: json)
        
        let config = IterableConfig()
        config.checkForDeferredDeeplink = true
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = { url, _ in
            TestUtils.validate(request: networkSession.request!, apiEndPoint: Endpoint.links, path: Const.Path.ddlMatch)
            expectation.fulfill()
            XCTAssertEqual(url.absoluteString, "zeeDestinationUrl")
        }
        
        config.urlDelegate = urlDelegate
        IterableAPIInternal.initializeForTesting(apiKey: DeferredDeepLinkTests.apiKey, config: config, networkSession: networkSession)
        
        wait(for: [expectation], timeout: testExpectationTimeout)
        
        // Test that calling second time does not trigger
        let expectation2 = XCTestExpectation(description: "should not callCheckForDDL")
        expectation2.isInverted = true
        let config2 = IterableConfig()
        config2.checkForDeferredDeeplink = true
        let urlDelegate2 = MockUrlDelegate(returnValue: true)
        urlDelegate2.callback = { _, _ in
            expectation2.fulfill()
        }
        config.urlDelegate = urlDelegate2
        IterableAPIInternal.initializeForTesting(apiKey: DeferredDeepLinkTests.apiKey, config: config, networkSession: networkSession)
        
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func testDDLNoMatch() {
        let expectation = XCTestExpectation(description: "testDDL No Match")
        expectation.isInverted = true
        
        let json: [AnyHashable: Any] = [
            "isMatch": false,
        ]
        let networkSession = MockNetworkSession(statusCode: 200, json: json)
        
        let config = IterableConfig()
        config.checkForDeferredDeeplink = true
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = { _, _ in
            expectation.fulfill()
        }
        config.urlDelegate = urlDelegate
        IterableAPIInternal.initializeForTesting(apiKey: DeferredDeepLinkTests.apiKey, config: config, networkSession: networkSession)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCheckForDeferredDDLIsSetToFalse() {
        let expectation = XCTestExpectation(description: "testDDL No Match")
        expectation.isInverted = true
        
        let json: [AnyHashable: Any] = [
            "isMatch": true,
            "destinationUrl": "zeeDestinationUrl",
            "campaignId": "1",
            "templateId": "1",
            "messageId": "1",
        ]
        let networkSession = MockNetworkSession(statusCode: 200, json: json)
        
        let config = IterableConfig()
        config.checkForDeferredDeeplink = false
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = { _, _ in
            expectation.fulfill()
        }
        config.urlDelegate = urlDelegate
        IterableAPIInternal.initializeForTesting(apiKey: DeferredDeepLinkTests.apiKey, config: config, networkSession: networkSession)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
