//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppNavigationTests: XCTestCase {
    func testOpenHttpsByDefault() {
        let expectation1 = expectation(description: #function)
        let expectation2 = expectation(description: "url opened")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(protocol: "https", index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { url in
            XCTAssertEqual(url, TestInAppPayloadGenerator.getClickedUrl(protocol: "https", index: 1))
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let internalApi = InternalIterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { [weak internalApi] _ in
            guard let internalApi = internalApi else {
                XCTFail("Expected internalApi to be not nil")
                return
            }
            let messages = internalApi.inAppManager.getMessages()
            
            internalApi.inAppManager.show(message: messages[0], consume: true) { clickedUrl in
                XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickedUrl(protocol: "https", index: 1))
                expectation1.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }

    func testDoNotOpenHttpByDefault() {
        let expectation1 = expectation(description: #function)
        let expectation2 = expectation(description: "url opened")
        expectation2.isInverted = true
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(protocol: "http", index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { url in
            XCTAssertEqual(url, TestInAppPayloadGenerator.getClickedUrl(protocol: "http", index: 1))
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let internalApi = InternalIterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { [weak internalApi] _ in
            guard let internalApi = internalApi else {
                XCTFail("Expected internalApi to be not nil")
                return
            }
            let messages = internalApi.inAppManager.getMessages()
            
            internalApi.inAppManager.show(message: messages[0], consume: true) { clickedUrl in
                XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickedUrl(protocol: "http", index: 1))
                expectation1.fulfill()
            }
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }

    func testAllowHttpWhenAllowedProtocolsIsSet() {
        let expectation1 = expectation(description: #function)
        let expectation2 = expectation(description: "url opened")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(protocol: "http", index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { url in
            XCTAssertEqual(url, TestInAppPayloadGenerator.getClickedUrl(protocol: "http", index: 1))
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        config.allowedProtocols = ["http"]

        let internalApi = InternalIterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { [weak internalApi] _ in
            guard let internalApi = internalApi else {
                XCTFail("Expected internalApi to be not nil")
                return
            }
            let messages = internalApi.inAppManager.getMessages()
            
            internalApi.inAppManager.show(message: messages[0], consume: true) { clickedUrl in
                XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickedUrl(protocol: "http", index: 1))
                expectation1.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
}
