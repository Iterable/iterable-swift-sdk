//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAutoShowInAppSingle() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            // 1 message is present when showing
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            expectation1.fulfill()
        }
        
        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        // Zero messages should be left after showing
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testAutoShowInAppSingleOverride() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
        XCTAssertEqual(IterableAPI.inAppManager.getMessages()[0].skipped, true)

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }

    func testAutoShowInAppMultiple() {
        let expectation1 = expectation(description: "testShowInAppMultiple")

        let payload = createPayload(numMessages: 3)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 3)
            expectation1.fulfill()
        }
        
        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].skipped, true)
        XCTAssertEqual(messages[1].skipped, true)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testAutoShowInAppMultipleOverride() {
        let expectation1 = expectation(description: "testShowInAppMultipleOverride")
        expectation1.isInverted = true
        
        let payload = createPayload(numMessages: 3)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )

        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].skipped, true)
        XCTAssertEqual(messages[1].skipped, true)
        XCTAssertEqual(messages[2].skipped, true)

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }

    
    func testAutoShowInAppOpenUrlByDefault() {
        let expectation1 = expectation(description: "testShowInAppOpenUrlByDefault")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, self.getClickUrl(index: 1))
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
            expectation1.fulfill()
        }
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            mockInAppDisplayer.click(url: self.getClickUrl(index: 1))
        }
        
        IterableAPI.initializeForTesting(
                                 inAppSynchronizer: mockInAppSynchronizer,
                                 inAppDisplayer: mockInAppDisplayer,
                                 urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 0)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testAutoShowInAppUrlDelegateOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppUrlDelegateOverride")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, self.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            mockInAppDisplayer.click(url: self.getClickUrl(index: 1))
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        let messages = IterableAPI.inAppManager.getMessages()
        // Message count is 0 because inApp is still being shown. It is just not opening external url on click.
        XCTAssertEqual(messages.count, 0)

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testShowInAppWithConsume() {
        let expectation1 = expectation(description: "testShowInAppWithConsume")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            mockInAppDisplayer.click(url: self.getClickUrl(index: 1))
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )

        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 1)
        
        IterableAPI.inAppManager.show(message: messages[0], consume: true) { (clickedUrl) in
            XCTAssertEqual(clickedUrl, self.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testShowInAppWithNoConsume() {
        let expectation1 = expectation(description: "testShowInAppWithNoConsume")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            mockInAppDisplayer.click(url: self.getClickUrl(index: 1))
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        
        var messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].skipped, true)

        // Now show the first message, but don't consume
        IterableAPI.inAppManager.show(message: messages[0], consume: false) { (clickedUrl) in
            XCTAssertEqual(clickedUrl, self.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].skipped, true)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    // Check that onNew is called just once if the messageId is same.
    func testOnNewNotCalledMultipleTimes() {
        let expectation1 = expectation(description: "testOnNewNotCalledMultipleTimes")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        mockInAppDelegate.onNewMessageCallback = {_ in
            // should only be called once
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        
        // Send second message with same id.
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    private func createPayload(numMessages: Int) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : (1...numMessages).reduce(into: [[AnyHashable : Any]]()) { (result, index) in
                result.append(createOneInAppDict(index: index))
            }
        ]
    }

    private func createOneInAppDict(index: Int) -> [AnyHashable : Any] {
        return [
            "content" : [
                "html" : "<a href='\(getClickUrl(index: index))'>Click Here</a>",
                "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]],
                "payload" : ["channelName" : "inBox", "title" : "Product 1 Available", "date" : "2018-11-14T14:00:00:00.32Z"]
            ],
            "messageId" : getMessageId(index: index),
            "campaignId" : getCampaignId(index: index),
        ]
    }
    
    private func getMessageId(index: Int) -> String {
        return "message\(index)"
    }

    private func getCampaignId(index: Int) -> String {
        return "campaign\(index)"
    }

    private func getClickUrl(index: Int) -> String {
        return "https://www.site\(index).com"
    }
}
