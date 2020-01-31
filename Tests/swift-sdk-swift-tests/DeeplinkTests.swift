//
//  Created by Tapash Majumder on 12/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

import OHHTTPStubs

@testable import IterableSDK

class DeeplinkTests: XCTestCase {

    override func setUp() {
        super.setUp()

        IterableAPI.initializeForTesting()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    private let iterableRewriteURL = "http://links.iterable.com/a/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0"
    private let iterableNoRewriteURL = "http://links.iterable.com/u/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0"
    
    private let redirectRequest = "https://httpbin.org/redirect-to?url=http://example.com"
    private let exampleUrl = "http://example.com"

    func testUniversalDeeplinkRewrite() {
        let expectation1 = expectation(description: "testUniversalDeeplinkRewrite")
        
        let redirectLocation = "https://links.iterable.com/api/docs#!/email"
        let campaignId = 83306
        let templateId = 124348
        let messageId = "93125f33ba814b13a882358f8e0852e0"
        
        setupRedirectStubResponse(location: redirectLocation, campaignId: campaignId, templateId: templateId, messageId: messageId)
        
        IterableAPI.getAndTrack(deeplink: URL(string: iterableRewriteURL)!) { (redirectUrl) in
            XCTAssertEqual(redirectUrl, redirectLocation)
            XCTAssertTrue(Thread.isMainThread)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testUniversalDeeplinkNoRewrite() {
        let expectation1 = expectation(description: "testUniversalDeeplinkNoRewrite")
        
        setupStubResponse()
        
        IterableAPI.getAndTrack(deeplink: URL(string: iterableNoRewriteURL)!) { (redirectUrl) in
            XCTAssertEqual(redirectUrl, self.iterableNoRewriteURL)
            XCTAssertTrue(Thread.isMainThread)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testHandleUniversalLinkRewrite() {
        let expectation1 = expectation(description: "urlDelegate is called")
        
        let redirectLocation = "https://links.iterable.com/api/docs#!/email"
        let campaignId = 83306
        let templateId = 124348
        let messageId = "93125f33ba814b13a882358f8e0852e0"
        
        setupRedirectStubResponse(location: redirectLocation, campaignId: campaignId, templateId: templateId, messageId: messageId)
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: false)
        mockUrlDelegate.callback = {(url, context) in
            XCTAssertEqual(url.absoluteString, redirectLocation)
            XCTAssertEqual(context.action.type, IterableAction.actionTypeOpenUrl)
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        IterableAPI.initializeForObjcTesting(config: config)
        
        IterableAPI.handle(universalLink: URL(string: iterableRewriteURL)!)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDeeplinkAttributionInfo() {
        let expectation1 = expectation(description: "testDeeplinkAttributionInfo")
        
        let redirectLocation = "https://links.iterable.com/api/docs#!/email"
        let campaignId = 83306
        let templateId = 124348
        let messageId = "93125f33ba814b13a882358f8e0852e0"
        
        setupRedirectStubResponse(location: redirectLocation, campaignId: campaignId, templateId: templateId, messageId: messageId)
        
        IterableAPI.getAndTrack(deeplink: URL(string: iterableRewriteURL)!) { (redirectUrl) in
            XCTAssertEqual(IterableAPI.attributionInfo?.campaignId, NSNumber(value: campaignId))
            XCTAssertEqual(IterableAPI.attributionInfo?.templateId, NSNumber(value: templateId))
            XCTAssertEqual(IterableAPI.attributionInfo?.messageId, messageId)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    // this is a service that automatically redirects if that url is hit, make sure we are not actually hitting the url
    // but our servers
    func testNoURLRedirect() {
        let expectation1 = expectation(description: "testNoURLRedirect")
        
        setupStubResponse()
        
        IterableAPI.getAndTrack(deeplink: URL(string: redirectRequest)!) { (redirectUrl) in
            XCTAssertNotEqual(redirectUrl, self.exampleUrl)
            XCTAssertEqual(redirectUrl, self.redirectRequest)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func setupRedirectStubResponse(location: String, campaignId: Int, templateId: Int, messageId: String) {
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return true
        }) { (request) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: try! JSONSerialization.data(withJSONObject: [:], options: []), statusCode: 301, headers: [
                "Location" : location,
                "Set-Cookie" : self.createCookieValue(nameValuePairs: "iterableEmailCampaignId", campaignId, "iterableTemplateId", templateId, "iterableMessageId", messageId)
                ])
        }
    }

    private func setupStubResponse() {
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return true
        }) { (request) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: try! JSONSerialization.data(withJSONObject: [:], options: []), statusCode: 200, headers: nil)
        }
    }

    private func createCookieValue(nameValuePairs values: Any...) -> String {
        return values.take(2).map { "\($0[0])=\($0[1])" }.joined(separator: ";,")
    }
}

