//
//  Copyright © 2024 Iterable. All rights reserved.
//

import XCTest
import Foundation

@testable import IterableSDK

class RedirectNetworkSessionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Redirect Completion Handler Tests
    
    func testRedirectCompletionHandlerAllowsRedirect() {
        let expectation = expectation(description: "Redirect delegate called")
        let mockDelegate = MockRedirectNetworkSessionDelegate()
        
        let redirectSession = RedirectNetworkSession(delegate: mockDelegate)
        
        let originalUrl = URL(string: "https://links.greenfi.com/a/JsvVI")!
        let redirectUrl = URL(string: "https://example.com/destination")!
        
        // Mock the redirect response
        let response = HTTPURLResponse(
            url: originalUrl,
            statusCode: 303,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Location": redirectUrl.absoluteString,
                "Set-Cookie": createCookieValue(nameValuePairs: "iterableEmailCampaignId", 12345, "iterableTemplateId", 67890, "iterableMessageId", "test-message")
            ]
        )!
        
        let newRequest = URLRequest(url: redirectUrl)
        
        mockDelegate.onRedirectCallback = { deepLinkLocation, campaignId, templateId, messageId in
            XCTAssertEqual(deepLinkLocation, redirectUrl)
            XCTAssertEqual(campaignId, NSNumber(value: 12345))
            XCTAssertEqual(templateId, NSNumber(value: 67890))
            XCTAssertEqual(messageId, "test-message")
            expectation.fulfill()
        }
        
        var capturedRequest: URLRequest?
        
        // Call the redirect method directly
        redirectSession.urlSession(
            URLSession.shared,
            task: URLSessionDataTask(),
            willPerformHTTPRedirection: response,
            newRequest: newRequest
        ) { request in
            capturedRequest = request
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that the completion handler was called with the request (allowing redirect)
        XCTAssertNotNil(capturedRequest, "Completion handler should receive the request to allow redirect")
        XCTAssertEqual(capturedRequest?.url, redirectUrl, "Should pass the redirect request to allow following the redirect")
    }
    
    func testRedirectWithoutCookiesStillAllowsRedirect() {
        let expectation = expectation(description: "Redirect delegate called")
        let mockDelegate = MockRedirectNetworkSessionDelegate()
        
        let redirectSession = RedirectNetworkSession(delegate: mockDelegate)
        
        let originalUrl = URL(string: "https://links.greenfi.com/a/JsvVI")!
        let redirectUrl = URL(string: "https://example.com/destination")!
        
        // Mock the redirect response without cookies
        let response = HTTPURLResponse(
            url: originalUrl,
            statusCode: 303,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Location": redirectUrl.absoluteString
            ]
        )!
        
        let newRequest = URLRequest(url: redirectUrl)
        
        mockDelegate.onRedirectCallback = { deepLinkLocation, campaignId, templateId, messageId in
            XCTAssertEqual(deepLinkLocation, redirectUrl)
            XCTAssertNil(campaignId)
            XCTAssertNil(templateId)
            XCTAssertNil(messageId)
            expectation.fulfill()
        }
        
        var capturedRequest: URLRequest?
        
        // Call the redirect method directly
        redirectSession.urlSession(
            URLSession.shared,
            task: URLSessionDataTask(),
            willPerformHTTPRedirection: response,
            newRequest: newRequest
        ) { request in
            capturedRequest = request
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that the completion handler was called with the request (allowing redirect)
        XCTAssertNotNil(capturedRequest, "Completion handler should receive the request to allow redirect")
        XCTAssertEqual(capturedRequest?.url, redirectUrl, "Should pass the redirect request to allow following the redirect")
    }
    
    func testRedirectWithMalformedCookiesStillAllowsRedirect() {
        let expectation = expectation(description: "Redirect delegate called")
        let mockDelegate = MockRedirectNetworkSessionDelegate()
        
        let redirectSession = RedirectNetworkSession(delegate: mockDelegate)
        
        let originalUrl = URL(string: "https://links.greenfi.com/a/JsvVI")!
        let redirectUrl = URL(string: "https://example.com/destination")!
        
        // Mock the redirect response with malformed cookies
        let response = HTTPURLResponse(
            url: originalUrl,
            statusCode: 303,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Location": redirectUrl.absoluteString,
                "Set-Cookie": createCookieValue(nameValuePairs: "iterableEmailCampaignId", "invalid", "iterableTemplateId", "also-invalid", "iterableMessageId", "valid-message")
            ]
        )!
        
        let newRequest = URLRequest(url: redirectUrl)
        
        mockDelegate.onRedirectCallback = { deepLinkLocation, campaignId, templateId, messageId in
            XCTAssertEqual(deepLinkLocation, redirectUrl)
            XCTAssertEqual(campaignId, NSNumber(value: 0)) // Should default to 0 for invalid values
            XCTAssertEqual(templateId, NSNumber(value: 0)) // Should default to 0 for invalid values
            XCTAssertEqual(messageId, "valid-message")
            expectation.fulfill()
        }
        
        var capturedRequest: URLRequest?
        
        // Call the redirect method directly
        redirectSession.urlSession(
            URLSession.shared,
            task: URLSessionDataTask(),
            willPerformHTTPRedirection: response,
            newRequest: newRequest
        ) { request in
            capturedRequest = request
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that the completion handler was called with the request (allowing redirect)
        XCTAssertNotNil(capturedRequest, "Completion handler should receive the request to allow redirect")
        XCTAssertEqual(capturedRequest?.url, redirectUrl, "Should pass the redirect request to allow following the redirect")
    }
    
    func testRedirectWithNoHeaderFields() {
        let expectation = expectation(description: "Redirect delegate called")
        let mockDelegate = MockRedirectNetworkSessionDelegate()
        
        let redirectSession = RedirectNetworkSession(delegate: mockDelegate)
        
        let originalUrl = URL(string: "https://links.greenfi.com/a/JsvVI")!
        let redirectUrl = URL(string: "https://example.com/destination")!
        
        // Mock the redirect response with no header fields
        let response = HTTPURLResponse(
            url: originalUrl,
            statusCode: 303,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        let newRequest = URLRequest(url: redirectUrl)
        
        mockDelegate.onRedirectCallback = { deepLinkLocation, campaignId, templateId, messageId in
            XCTAssertEqual(deepLinkLocation, redirectUrl)
            XCTAssertNil(campaignId)
            XCTAssertNil(templateId)
            XCTAssertNil(messageId)
            expectation.fulfill()
        }
        
        var capturedRequest: URLRequest?
        
        // Call the redirect method directly
        redirectSession.urlSession(
            URLSession.shared,
            task: URLSessionDataTask(),
            willPerformHTTPRedirection: response,
            newRequest: newRequest
        ) { request in
            capturedRequest = request
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that the completion handler was called with the request (allowing redirect)
        XCTAssertNotNil(capturedRequest, "Completion handler should receive the request to allow redirect")
        XCTAssertEqual(capturedRequest?.url, redirectUrl, "Should pass the redirect request to allow following the redirect")
    }
    
    // MARK: - Integration Tests
    
    func testDeepLinkManagerUsesRedirectNetworkSession() {
        let expectation = expectation(description: "Deep link resolves with redirect")
        
        let greenfiUrl = "https://links.greenfi.com/a/JsvVI"
        let destinationUrl = "https://example.com/destination"
        let campaignId = 12345
        let templateId = 67890
        let messageId = "test-message-id"
        
        // Create a mock network session that simulates a successful redirect
        let mockNetworkSession = MockNetworkSession()
        mockNetworkSession.responseCallback = { _ in
            MockNetworkSession.MockResponse(
                statusCode: 200,
                data: "{}".data(using: .utf8)!,
                delay: 0.0,
                error: nil,
                headerFields: [:]
            )
        }
        
        // Create a provider that uses our test redirect session
        let provider = TestRedirectNetworkSessionProvider(
            destinationUrl: destinationUrl,
            campaignId: campaignId,
            templateId: templateId,
            messageId: messageId
        )
        
        let deepLinkManager = DeepLinkManager(redirectNetworkSessionProvider: provider)
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = { url, context in
            XCTAssertEqual(url.absoluteString, destinationUrl)
            XCTAssertEqual(context.action.type, IterableAction.actionTypeOpenUrl)
            expectation.fulfill()
        }
        
        let (isIterableLink, attributionInfoFuture) = deepLinkManager.handleUniversalLink(
            URL(string: greenfiUrl)!,
            urlDelegate: mockUrlDelegate,
            urlOpener: MockUrlOpener()
        )
        
        XCTAssertTrue(isIterableLink)
        
        // Also verify attribution info is extracted
        attributionInfoFuture.onSuccess { attributionInfo in
            XCTAssertEqual(attributionInfo?.campaignId, NSNumber(value: campaignId))
            XCTAssertEqual(attributionInfo?.templateId, NSNumber(value: templateId))
            XCTAssertEqual(attributionInfo?.messageId, messageId)
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Test Helpers

private func createCookieValue(nameValuePairs values: Any...) -> String {
    values.take(2).map { "\($0[0])=\($0[1])" }.joined(separator: ";,")
}

class MockRedirectNetworkSessionDelegate: RedirectNetworkSessionDelegate {
    var onRedirectCallback: ((URL?, NSNumber?, NSNumber?, String?) -> Void)?
    
    func onRedirect(deepLinkLocation: URL?, campaignId: NSNumber?, templateId: NSNumber?, messageId: String?) {
        onRedirectCallback?(deepLinkLocation, campaignId, templateId, messageId)
    }
}

struct TestRedirectNetworkSessionProvider: RedirectNetworkSessionProvider {
    let destinationUrl: String
    let campaignId: Int
    let templateId: Int
    let messageId: String
    
    func createRedirectNetworkSession(delegate: RedirectNetworkSessionDelegate) -> NetworkSessionProtocol {
        TestRedirectNetworkSession(
            destinationUrl: destinationUrl,
            campaignId: campaignId,
            templateId: templateId,
            messageId: messageId,
            delegate: delegate
        )
    }
}

class TestRedirectNetworkSession: NetworkSessionProtocol {
    var timeout: TimeInterval = 60.0
    
    private let destinationUrl: String
    private let campaignId: Int
    private let templateId: Int
    private let messageId: String
    private weak var delegate: RedirectNetworkSessionDelegate?
    
    init(destinationUrl: String, campaignId: Int, templateId: Int, messageId: String, delegate: RedirectNetworkSessionDelegate?) {
        self.destinationUrl = destinationUrl
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
        self.delegate = delegate
    }
    
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler) {
        // Simulate the redirect behavior by calling the delegate
        DispatchQueue.main.async {
            self.delegate?.onRedirect(
                deepLinkLocation: URL(string: self.destinationUrl),
                campaignId: NSNumber(value: self.campaignId),
                templateId: NSNumber(value: self.templateId),
                messageId: self.messageId
            )
            
            // Simulate successful completion of the redirected request
            let response = HTTPURLResponse(
                url: URL(string: self.destinationUrl)!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [:]
            )
            completionHandler("{}".data(using: .utf8), response, nil)
        }
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping CompletionHandler) {
        // Simulate the redirect behavior by calling the delegate
        DispatchQueue.main.async {
            self.delegate?.onRedirect(
                deepLinkLocation: URL(string: self.destinationUrl),
                campaignId: NSNumber(value: self.campaignId),
                templateId: NSNumber(value: self.templateId),
                messageId: self.messageId
            )
            
            // Simulate successful completion of the redirected request
            let response = HTTPURLResponse(
                url: URL(string: self.destinationUrl)!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [:]
            )
            completionHandler("{}".data(using: .utf8), response, nil)
        }
    }
    
    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol {
        // Return a mock data task for this test
        MockDataTask { [weak self] in
            self?.makeDataRequest(with: url, completionHandler: completionHandler)
        }
    }
}

class MockDataTask: DataTaskProtocol {
    var state: URLSessionDataTask.State = .suspended
    private let executeBlock: () -> Void
    
    init(executeBlock: @escaping () -> Void) {
        self.executeBlock = executeBlock
    }
    
    func resume() {
        state = .running
        executeBlock()
        state = .completed
    }
    
    func cancel() {
        state = .completed
    }
} 