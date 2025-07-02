//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class DeepLinkTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private let iterableRewriteURL = "https://links.iterable.com/a/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0"
    private let iterableNoRewriteURL = "https://links.iterable.com/u/60402396fbd5433eb35397b47ab2fb83?_e=joneng%40iterable.com&_m=93125f33ba814b13a882358f8e0852e0"
    
    private let redirectRequest = "https://httpbin.org/redirect-to?url=https://example.com"
    private let exampleUrl = "https://example.com"
    
    func testTrackUniversalDeepLinkRewrite() {
        let expectation1 = expectation(description: #function)
        let expectation2 = expectation(description: "\(#function)-attributionInfo")
        
        let redirectLocation = "https://links.iterable.com/api/docs#!/email"
        let campaignId = 83306
        let templateId = 124_348
        let messageId = "93125f33ba814b13a882358f8e0852e0"

        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = { url, context in
            XCTAssertEqual(url.absoluteString, redirectLocation)
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(context.action.type, IterableAction.actionTypeOpenUrl)
            expectation1.fulfill()
        }
        
        let networkSessionProvider = createRedirectNetworkSessionProvider(location: redirectLocation,
                                                                          campaignId: campaignId,
                                                                          templateId: templateId,
                                                                          messageId: messageId)
        let deepLinkManager = DeepLinkManager(redirectNetworkSessionProvider: networkSessionProvider)
        
        let (isIterableLink, attributionInfoFuture) = deepLinkManager.handleUniversalLink(URL(string: iterableRewriteURL)!,
                                                                      urlDelegate: mockUrlDelegate,
                                                                      urlOpener: MockUrlOpener())
        XCTAssertTrue(isIterableLink)
        attributionInfoFuture.onSuccess { attributionInfo in
            XCTAssertEqual(attributionInfo?.campaignId, NSNumber(value: campaignId))
            XCTAssertEqual(attributionInfo?.templateId, NSNumber(value: templateId))
            XCTAssertEqual(attributionInfo?.messageId, messageId)
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }

    func testTrackUniversalDeepLinkNoRewrite() {
        let expectation1 = expectation(description: "testUniversalDeepLinkNoRewrite")
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = { url, context in
            XCTAssertEqual(url.absoluteString, self.iterableNoRewriteURL)
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(context.action.type, IterableAction.actionTypeOpenUrl)
            expectation1.fulfill()
        }
        
        let deepLinkManager = DeepLinkManager(redirectNetworkSessionProvider: createNoRedirectNetworkSessionProvider())
        
        let (_, _) = deepLinkManager.handleUniversalLink(URL(string: iterableNoRewriteURL)!,
                                                                      urlDelegate: mockUrlDelegate,
                                                                      urlOpener: MockUrlOpener())

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testHandleUniversalLinkRewrite() {
        let expectation1 = expectation(description: "urlDelegate is called")
        
        let redirectLocation = "https://links.iterable.com/api/docs#!/email"
        let campaignId = 83306
        let templateId = 124_348
        let messageId = "93125f33ba814b13a882358f8e0852e0"
        
        let networkSession = createRedirectNetworkSession(location: redirectLocation,
                                                          campaignId: campaignId,
                                                          templateId: templateId,
                                                          messageId: messageId)
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: false)
        mockUrlDelegate.callback = { url, context in
            XCTAssertEqual(url.absoluteString, redirectLocation)
            XCTAssertEqual(context.action.type, IterableAction.actionTypeOpenUrl)
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config, networkSession: networkSession)
        
        internalAPI.handleUniversalLink(URL(string: iterableRewriteURL)!)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testHandleUniversalLinkAttributionInfo() {
        let expectation1 = expectation(description: "testHandleUniversalLinkAttributionInfo")
        
        let redirectLocation = "https://links.iterable.com/api/docs#!/email"
        let campaignId = 83306
        let templateId = 124_348
        let messageId = "93125f33ba814b13a882358f8e0852e0"
        
        let networkSession = createRedirectNetworkSession(location: redirectLocation,
                                                          campaignId: campaignId,
                                                          templateId: templateId,
                                                          messageId: messageId)

        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession)
        internalAPI.handleUniversalLink(URL(string: iterableRewriteURL)!)
        internalAPI.attributionInfo = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(internalAPI.attributionInfo?.campaignId, NSNumber(value: campaignId))
            XCTAssertEqual(internalAPI.attributionInfo?.templateId, NSNumber(value: templateId))
            XCTAssertEqual(internalAPI.attributionInfo?.messageId, messageId)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    /// this is a service that automatically redirects if that url is hit, make sure we are not actually hitting the url but our servers
    func testNoURLRedirect() {
        let expectation1 = expectation(description: "testNoURLRedirect")
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: false)
        mockUrlDelegate.callback = { redirectUrl, context in
            XCTAssertNotEqual(redirectUrl.absoluteString, self.exampleUrl)
            XCTAssertEqual(redirectUrl.absoluteString, self.redirectRequest)
            
            expectation1.fulfill()
        }
        
        let deepLinkManager = DeepLinkManager(redirectNetworkSessionProvider: createNoRedirectNetworkSessionProvider())
        
        _ = deepLinkManager.handleUniversalLink(URL(string: redirectRequest)!,
                                                urlDelegate: mockUrlDelegate,
                                                urlOpener: MockUrlOpener())
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func createRedirectNetworkSessionProvider(location: String, campaignId: Int, templateId: Int, messageId: String) -> RedirectNetworkSessionProvider {
        MockRedirectNetworkSessionProvider(networkSession: createRedirectNetworkSession(location: location,
                                                                                        campaignId: campaignId,
                                                                                        templateId: templateId,
                                                                                        messageId: messageId))
    }

    private func createRedirectNetworkSession(location: String, campaignId: Int, templateId: Int, messageId: String) -> MockNetworkSession {
        let networkSession = MockNetworkSession()
        networkSession.responseCallback = { _ in
            MockNetworkSession.MockResponse(statusCode: 301,
                                            data: Dictionary<AnyHashable, Any>().toJsonData(),
                                            delay: 0.0,
                                            error: nil,
                                            headerFields: [
                                                "Location": location,
                                                "Set-Cookie": self.createCookieValue(nameValuePairs: "iterableEmailCampaignId", campaignId, "iterableTemplateId", templateId, "iterableMessageId", messageId),
                                            ])
        }
        return networkSession
    }

    private func createNoRedirectNetworkSessionProvider() -> RedirectNetworkSessionProvider {
        MockNoRedirectNetworkSessionProvider(networkSession: MockNetworkSession())
    }

    private func createCookieValue(nameValuePairs values: Any...) -> String {
        values.take(2).map { "\($0[0])=\($0[1])" }.joined(separator: ";,")
    }
    
    // MARK: - GreenFi SMS Deep Link Tests
    
    func testGreenFiSMSDeepLinkRedirect() {
        let expectation1 = expectation(description: "Deep link resolves successfully")
        let expectation2 = expectation(description: "Attribution info extracted")
        
        let greenfiSmsUrl = "https://links.greenfi.com/a/JsvVI"
        let destinationUrl = "https://app.greenfi.com/dashboard"
        let campaignId = 123456
        let templateId = 789012
        let messageId = "sms-campaign-123"
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = { url, context in
            XCTAssertEqual(url.absoluteString, destinationUrl)
            XCTAssertEqual(context.action.type, IterableAction.actionTypeOpenUrl)
            XCTAssertTrue(Thread.isMainThread)
            expectation1.fulfill()
        }
        
        // Create network session that simulates GreenFi's 303 redirect response
        let networkSession = MockNetworkSession()
        networkSession.responseCallback = { _ in
            MockNetworkSession.MockResponse(
                statusCode: 303, // GreenFi returns 303 redirect
                data: Dictionary<AnyHashable, Any>().toJsonData(),
                delay: 0.0,
                error: nil,
                headerFields: [
                    "Location": destinationUrl,
                    "Set-Cookie": self.createCookieValue(nameValuePairs: "iterableEmailCampaignId", campaignId, "iterableTemplateId", templateId, "iterableMessageId", messageId),
                ]
            )
        }
        
        let networkSessionProvider = MockRedirectNetworkSessionProvider(networkSession: networkSession)
        let deepLinkManager = DeepLinkManager(redirectNetworkSessionProvider: networkSessionProvider)
        
        let (isIterableLink, attributionInfoFuture) = deepLinkManager.handleUniversalLink(
            URL(string: greenfiSmsUrl)!,
            urlDelegate: mockUrlDelegate,
            urlOpener: MockUrlOpener()
        )
        
        XCTAssertTrue(isIterableLink, "GreenFi URL should be recognized as Iterable deep link")
        
        attributionInfoFuture.onSuccess { attributionInfo in
            XCTAssertNotNil(attributionInfo, "Should extract attribution info from 303 response")
            XCTAssertEqual(attributionInfo?.campaignId, NSNumber(value: campaignId))
            XCTAssertEqual(attributionInfo?.templateId, NSNumber(value: templateId))
            XCTAssertEqual(attributionInfo?.messageId, messageId)
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testGreenFiDeepLinkWithoutRedirect() {
        let expectation1 = expectation(description: "Deep link handled without redirect")
        
        let greenfiSmsUrl = "https://links.greenfi.com/a/JsvVI"
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = { url, context in
            // When no redirect occurs, should get original URL
            XCTAssertEqual(url.absoluteString, greenfiSmsUrl)
            XCTAssertEqual(context.action.type, IterableAction.actionTypeOpenUrl)
            expectation1.fulfill()
        }
        
        // Use no-redirect provider to simulate timeout/failure scenario
        let deepLinkManager = DeepLinkManager(redirectNetworkSessionProvider: createNoRedirectNetworkSessionProvider())
        
        let (isIterableLink, attributionInfoFuture) = deepLinkManager.handleUniversalLink(
            URL(string: greenfiSmsUrl)!,
            urlDelegate: mockUrlDelegate,
            urlOpener: MockUrlOpener()
        )
        
        XCTAssertTrue(isIterableLink, "GreenFi URL should be recognized as Iterable deep link")
        
        attributionInfoFuture.onSuccess { attributionInfo in
            XCTAssertNil(attributionInfo, "Should not have attribution info when redirect fails")
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}

private struct MockNoRedirectNetworkSessionProvider: RedirectNetworkSessionProvider {
    init(networkSession: NetworkSessionProtocol) {
        self.networkSession = networkSession
    }
    
    func createRedirectNetworkSession(delegate: RedirectNetworkSessionDelegate) -> NetworkSessionProtocol {
        networkSession
    }
    
    private let networkSession: NetworkSessionProtocol
}

private struct MockRedirectNetworkSessionProvider: RedirectNetworkSessionProvider {
    init(networkSession: NetworkSessionProtocol) {
        self.networkSession = networkSession
    }
    
    func createRedirectNetworkSession(delegate: RedirectNetworkSessionDelegate) -> NetworkSessionProtocol {
        MockRedirectNetworkSession(networkSession: networkSession, redirectDelegate: delegate)
    }
    
    private let networkSession: NetworkSessionProtocol
}
